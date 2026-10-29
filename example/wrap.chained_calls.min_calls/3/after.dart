void example() {
  final names = people
      .where(isActive)
      .map(toName)
      .toList();
  final name = person.trim().toLowerCase();
}
