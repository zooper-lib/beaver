String status(int code) {
  switch (code) {
    case 200: return 'ok';
    case 404: return 'missing';
    default: return 'error';
  }
}
