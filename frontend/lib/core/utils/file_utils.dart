export 'file_utils_stub.dart'
    if (dart.library.html) 'file_utils_web.dart'
    if (dart.library.io) 'file_utils_native.dart';
