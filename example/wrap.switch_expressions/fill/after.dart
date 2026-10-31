String label(Side side) => switch (side) {
  Side.left => 'L', Side.right => 'R'
};

String describe(Shape shape) => switch (shape) {
  Circle() => 'a circle', Square() => 'a square', Triangle() => 'a triangle',
  _ => 'unknown'
};
