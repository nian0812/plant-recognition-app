import 'dart:math' as math;
import 'package:flutter/material.dart';

class PvZSunflowerWidget extends StatefulWidget {
  final double size;
  const PvZSunflowerWidget({Key? key, this.size = 140.0}) : super(key: key);

  @override
  State<PvZSunflowerWidget> createState() => _PvZSunflowerWidgetState();
}

class _PvZSunflowerWidgetState extends State<PvZSunflowerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Chu kỳ 1400ms tương đương nhịp điệu ~85-90 BPM của PvZ
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double t = _controller.value; // Chạy từ 0.0 -> 1.0

        // 1. Góc nghiêng lắc: Sang trái ở t=0.25, sang phải ở t=0.75
        // Tương đương hàm sin kép:
        final double angle = math.sin(t * 2 * math.pi) * 0.18; // ~10.3 độ

        // 2. Nhún lên xuống (Translation Y): 2 lần nhún trong 1 chu kỳ lắc
        final double translateY = -math.sin(t * 4 * math.pi).abs() * 8.0;

        // 3. Hiệu ứng Squash & Stretch theo nhịp nảy:
        // Khi vươn lên đỉnh (translateY âm nhiều): kéo giãn chiều dọc (stretch)
        // Khi đáp xuống (translateY gần 0): nén dẹt chiều dọc (squash)
        final double bouncePhase = math.sin(t * 4 * math.pi);
        final double scaleY = 1.0 + (bouncePhase * 0.08);
        final double scaleX = 1.0 - (bouncePhase * 0.06);

        return Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Đổ bóng đáy nở ra thu vào
            Transform.scale(
              scaleX: 1.0 + (bouncePhase * 0.15),
              scaleY: 1.0 - (bouncePhase * 0.1),
              child: Container(
                width: widget.size * 0.55,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Nhân vật Hoa Hướng Dương PvZ
            Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.identity()
                ..translate(0.0, translateY)
                ..rotateZ(angle)
                ..scale(scaleX, scaleY),
              child: child,
            ),
          ],
        );
      },
      child: Image.asset(
        'assets/images/pvz_sunflower.png',
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
      ),
    );
  }
}