void example() {
  test('adds', () {
    expect(add(1, 2), 3);
  });
  setState(() {
    _count++;
  });
}
