class Point {
  int x = 0;
  int y = 0;
  int get sum => x + y;

  void moveRight() {
    x++;
  }

  void moveDown() {
    y++;
  }
}
