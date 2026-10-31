void example() {
  try {
    load();
  }
  on FormatException catch (e) {
    report(e);
  } finally {
    close();
  }
}
