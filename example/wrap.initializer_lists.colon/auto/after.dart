class Point {
  Point(this.x, this.y)
    : _len = sqrt(x * x + y * y),
      _label = 'a point at $x and $y',
      _z = 0;
  Point.long(this.someVeryLongParameterName, this.anotherVeryLongParameterName)
    : first = 1,
      second = 2;
}
