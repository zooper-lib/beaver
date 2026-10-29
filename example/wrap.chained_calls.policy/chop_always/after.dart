void example() {
  var name = person
      .trim()
      .toLowerCase();
  final names = people
      .where((person) => person.isActive)
      .map((person) => person.name)
      .toList();
}
