class Point {
  Point(this.x, this.y) : _len = sqrt(x * x + y * y), _label = '$x,$y';
  Point.origin() : x = 0, y = 0;
  Point.named(this.x, this.y) : _len = sqrt(x * x + y * y), _label = 'a point at $x and $y', _z = 0;
}
