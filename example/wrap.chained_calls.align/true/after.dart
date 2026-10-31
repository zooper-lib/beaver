void example() {
  final names = people.where((person) => person.isActive)
                      .map((person) => person.name)
                      .toList();
}
