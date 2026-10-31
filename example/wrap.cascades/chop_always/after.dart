void example() {
  final paint = Paint()
    ..color = Colors.red;
  final p = Paint()
    ..color = Colors.red
    ..strokeWidth = 2;
  final path = Path()
    ..moveTo(startX, startY)
    ..lineTo(middleX, middleY)
    ..lineTo(endX, endY)
    ..close();
}
