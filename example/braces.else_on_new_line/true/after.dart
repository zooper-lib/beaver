void example() {
  if (ready) {
    start();
  }
  else {
    wait();
  }
  try {
    run();
  }
  catch (e) {
    report(e);
  }
  finally {
    cleanUp();
  }
}
