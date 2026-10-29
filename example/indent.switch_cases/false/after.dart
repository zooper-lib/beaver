void example() {
  switch (command) {
  case 'start':
    start();
  case 'stop':
    stop();
  default:
    help();
  }
}
