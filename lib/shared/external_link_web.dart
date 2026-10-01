import 'package:web/web.dart' as web;

void openExternal(String url) => web.window.open(url, '_blank', 'noopener');
