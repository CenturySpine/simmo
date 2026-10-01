/// No share sheet outside the browser: the caller copies the link instead.
Future<bool> shareNatively({
  required String title,
  required String url,
}) async => false;
