void example() {
  final names = users.where((user) => user.active)
      .map((user) => user.name)
      .toList();
}
