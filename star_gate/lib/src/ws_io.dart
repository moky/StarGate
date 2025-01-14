/* license: https://mit-license.org
 *
 *  Star Gate: Network Connection Module
 *
 *                               Written in 2024 by Moky <albert.moky@gmail.com>
 *
 * =============================================================================
 * The MIT License (MIT)
 *
 * Copyright (c) 2024 Albert Moky
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 * =============================================================================
 */
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';


class WebSocketConnector {
  WebSocketConnector(this.url);

  /// Possible states of the connection.
  static const int connecting = WebSocket.connecting;
  static const int open       = WebSocket.open;
  static const int closing    = WebSocket.closing;
  static const int closed     = WebSocket.closed;

  final Uri url;
  WebSocket? _ws;

  WebSocket? get socket => _ws;
  // protected
  Future<void> setSocket(WebSocket? ws) async {
    // 1. replace with new socket
    WebSocket? old = _ws;
    if (ws != null) {
      _ws = ws;
    // } else {
    //   _ws = null;
    }
    // 2. close old socket
    if (old == null || identical(old, ws)) {} else {
      await old.close();
    }
  }

  bool get isClosed {
    WebSocket? ws = _ws;
    if (ws == null) {
      // initializing
      return false;
    }
    return ws.readyState == closed || ws.closeCode != null;
  }

  bool get isConnected {
    WebSocket? ws = _ws;
    if (ws == null) {
      // initializing
      return false;
    }
    return ws.readyState == open && ws.closeCode == null;
  }

  @override
  String toString() {
    Type clazz = runtimeType;
    return '<$clazz url="$url" state=${_ws?.readyState} />';
  }

  Future<bool> connect([int timeout = 8000]) async {
    var ws = await WebSocket.connect(url.toString());
    if (await _checkState(timeout, () => ws.readyState == open)) {
      await setSocket(ws);
      return true;
    } else {
      assert(false, 'failed to connect: $url');
      return false;
    }
  }

  void listen(void Function(Uint8List data) onData) => socket?.listen((msg) {
    if (msg is String) {
      msg = Uint8List.fromList(utf8.encode(msg));
    } else {
      assert(msg is Uint8List, 'msg error');
    }
    onData(msg);
  }, onDone: () {
    print('[WS] socket closed: $url');
    close();
  });

  Future<int> write(Uint8List src) async {
    WebSocket? ws = socket;
    if (ws == null || !isConnected) {
      // throw SocketException('WebSocket closed: $url');
      assert(false, 'WebSocket closed: $url');
      return -1;
    }
    ws.add(src);
    return src.length;
  }

  Future<bool> close([int timeout = 8000]) async {
    var ws = _ws;
    if (ws == null) {
      assert(false, 'WebSocket not exists: $url');
      return false;
    } else {
      await setSocket(null);
    }
    return await _checkState(timeout, () => ws.readyState == closed);
  }

}

Future<bool> _checkState(int timeout, bool Function() condition) async {
  if (timeout <= 0) {
    // non-blocking
    return true;
  }
  DateTime expired = DateTime.now().add(Duration(milliseconds: timeout));
  while (!condition()) {
    // condition not true, wait a while to check again
    await Future.delayed(Duration(milliseconds: 128));
    if (DateTime.now().isAfter(expired)) {
      // throw SocketException('WebSocket timeout: $url');
      return false;
    }
  }
  // condition true now
  return true;
}
