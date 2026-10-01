// Phone share sheet on the web; nothing elsewhere (tests run on the VM).
export 'native_share_stub.dart'
    if (dart.library.js_interop) 'native_share_web.dart';
