Object? first(List<Object> items) {
  if (items.isEmpty) return null;
  if (items.length > 100) return items.last;
  return items.first;
}
