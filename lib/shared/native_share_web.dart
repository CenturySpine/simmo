import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

/// Opens the phone's share sheet (WhatsApp, SMS...). Returns false on
/// computers (mouse pointer) or without the Web Share API, so the caller
/// copies the link instead; true once shared or cancelled by the user.
Future<bool> shareNatively({required String title, required String url}) async {
  final navigator = web.window.navigator;
  if (!web.window.matchMedia('(pointer: coarse)').matches ||
      !(navigator as JSObject).has('share')) {
    return false;
  }
  try {
    await navigator.share(web.ShareData(title: title, url: url)).toDart;
    return true;
  } catch (error) {
    // Closing the sheet rejects with an AbortError: nothing else to do.
    return error.toString().contains('AbortError');
  }
}
