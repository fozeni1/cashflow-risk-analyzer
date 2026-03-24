import 'simple_http_client_base.dart';
import 'simple_http_client_stub.dart'
    if (dart.library.io) 'simple_http_client_io.dart'
    if (dart.library.html) 'simple_http_client_web.dart';

export 'simple_http_client_base.dart';

SimpleHttpClient createSimpleHttpClient() => createClient();
