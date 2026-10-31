String status(int code) {
  switch (code) {
    case 200 :
      return 'ok';
    default :
      return 'error';
  }
}
