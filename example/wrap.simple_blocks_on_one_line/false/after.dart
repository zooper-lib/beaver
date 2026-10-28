void example() {
  if (items.isEmpty) {
    return;
  }
  while (queue.isNotEmpty) {
    process(queue.removeFirst());
  }
}
