// Conditional import: picks the desktop (dart:io) implementation on native
// platforms, and the no-op web stub in the browser.
export 'process_service_desktop.dart'
    if (dart.library.html) 'process_service_web.dart';
