library stargate;

// export 'package:startrek/fsm.dart';
// export 'package:startrek/startrek.dart';

export 'src/plain.dart';
export 'src/stream.dart';
export 'src/gate.dart';

export 'src/ws.dart';
export 'src/ws_html.dart' if (dart.library.io) 'src/ws_io.dart';
