import Foundation
import CoreML
import Vision
import Flutter

/// Core ML On-Device Plant Recognition Plugin for iOS
/// Executes EfficientNetV2-S V4 on Apple Neural Engine / GPU / CPU fallback
public class CoreMLPlugin: NSObject, FlutterPlugin {
    private static let channelName = "com.plantrecognition.app/coreml"
    
    private var mlModel: MLModel?
    private var visionModel: VNCoreMLModel?
    private var isModelLoading = false
    private var classMapping: [String: String] = [:] // index string -> classId
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
        let instance = CoreMLPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "isCoreMLAvailable":
            result(true)
            
        case "getHardwareEngine":
            result("Core ML — Automatic")
            
        case "getThermalState":
            result(getThermalStateString())
            
        case "loadModel":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGS", message: "Arguments must be a dictionary", details: nil))
                return
            }
            let modelName = args["modelName"] as? String ?? "FlowerRecognitionV4"
            loadCoreMLModel(named: modelName, result: result)
            
        case "predictFrame":
            guard let args = call.arguments as? [String: Any],
                  let imageData = (args["imageBytes"] as? FlutterStandardTypedData)?.data else {
                result(FlutterError(code: "INVALID_IMAGE", message: "Missing imageBytes", details: nil))
                return
            }
            let width = args["width"] as? Int ?? 384
            let height = args["height"] as? Int ?? 384
            predictOnFrame(imageData: imageData, width: width, height: height, result: result)
            
        case "disposeModel":
            self.visionModel = nil
            self.mlModel = nil
            result(true)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - Model Loading
    private func loadCoreMLModel(named modelName: String, result: @escaping FlutterResult) {
        guard !isModelLoading else {
            result(FlutterError(code: "BUSY", message: "Model is currently loading", details: nil))
            return
        }
        
        isModelLoading = true
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // 1. Locate compiled or raw mlmodel in bundle assets
            let mainBundle = Bundle.main
            var modelURL = mainBundle.url(forResource: modelName, withExtension: "mlmodelc")
            
            if modelURL == nil {
                if let rawURL = mainBundle.url(forResource: modelName, withExtension: "mlmodel") {
                    do {
                        modelURL = try MLModel.compileModel(at: rawURL)
                    } catch {
                        DispatchQueue.main.async {
                            self.isModelLoading = false
                            result(FlutterError(code: "COMPILE_ERROR", message: "Failed to compile Core ML model: \(error.localizedDescription)", details: nil))
                        }
                        return
                    }
                }
            }
            
            // Also check flutter asset path
            if modelURL == nil {
                let assetKey = "assets/models/\(modelName).mlmodel"
                if let path = mainBundle.path(forResource: assetKey, ofType: nil) {
                    do {
                        modelURL = try MLModel.compileModel(at: URL(fileURLWithPath: path))
                    } catch {
                        print("[CoreMLPlugin] Failed to compile asset model: \(error)")
                    }
                }
            }
            
            // 2. Configure compute units: Apple Neural Engine -> GPU -> CPU fallback
            let config = MLModelConfiguration()
            config.computeUnits = .all
            
            do {
                if let validURL = modelURL {
                    let loadedModel = try MLModel(contentsOf: validURL, configuration: config)
                    let vModel = try VNCoreMLModel(for: loadedModel)
                    
                    self.mlModel = loadedModel
                    self.visionModel = vModel
                    self.isModelLoading = false
                    
                    DispatchQueue.main.async {
                        result([
                            "success": true,
                            "modelName": modelName,
                            "computeUnits": "all",
                            "engine": "Core ML — Automatic"
                        ])
                    }
                } else {
                    self.isModelLoading = false
                    DispatchQueue.main.async {
                        result(FlutterError(code: "MODEL_NOT_FOUND", message: "Could not find \(modelName).mlmodel in bundle", details: nil))
                    }
                }
            } catch {
                self.isModelLoading = false
                DispatchQueue.main.async {
                    result(FlutterError(code: "LOAD_ERROR", message: "Core ML load failed: \(error.localizedDescription)", details: nil))
                }
            }
        }
    }
    
    // MARK: - Prediction
    private func predictOnFrame(imageData: Data, width: Int, height: Int, result: @escaping FlutterResult) {
        guard let visionModel = self.visionModel else {
            result(FlutterError(code: "NO_MODEL", message: "Core ML model is not loaded", details: nil))
            return
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let request = VNCoreMLRequest(model: visionModel) { (req, error) in
            let elapsedMs = (CFAbsoluteTimeGetCurrent() - startTime) * 1000.0
            
            if let error = error {
                result(FlutterError(code: "INFERENCE_ERROR", message: error.localizedDescription, details: nil))
                return
            }
            
            guard let observations = req.results as? [VNClassificationObservation],
                  let top = observations.first else {
                result([
                    "success": false,
                    "message": "No classifications found"
                ])
                return
            }
            
            let topConfidence = Double(top.confidence)
            let classId = top.identifier
            
            result([
                "success": true,
                "classId": classId,
                "confidence": topConfidence,
                "inferenceTimeMs": elapsedMs,
                "engine": "Core ML — Automatic",
                "thermalState": self.getThermalStateString()
            ])
        }
        
        // 384x384 Center Crop matching V4
        request.imageCropAndScaleOption = .centerCrop
        
        DispatchQueue.global(qos: .userInteractive).async {
            let handler = VNImageRequestHandler(data: imageData, options: [:])
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "HANDLER_ERROR", message: error.localizedDescription, details: nil))
                }
            }
        }
    }
    
    // MARK: - Thermal State Monitoring
    private func getThermalStateString() -> String {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal:
            return "nominal"
        case .fair:
            return "fair"
        case .serious:
            return "serious"
        case .critical:
            return "critical"
        @unknown default:
            return "nominal"
        }
    }
}
