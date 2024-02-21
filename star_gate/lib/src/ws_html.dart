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
import 'dart:html';
import 'dart:io' show SocketException;
import 'dart:typed_data';

import 'package:startrek/nio.dart';

class WebSocketChannel extends SocketChannel {

  String? _url;
  WebSocket? _ws;

  final List<Uint8List> _caches = [];

  SocketAddress? _remoteAddress;
  SocketAddress? _localAddress;

  @override
  bool get isClosed => super.isClosed || _ws?.readyState == WebSocket.CLOSED;

  @override
  bool get isBound => _localAddress != null;

  @override
  bool get isConnected => _ws?.readyState == WebSocket.OPEN;

  @override
  SocketAddress? get remoteAddress => _remoteAddress;

  @override
  SocketAddress? get localAddress => _localAddress;

  @override
  String toString() {
    Type clazz = runtimeType;
    return '<$clazz url="$_url" />';
  }

  @override
  Future<void> implCloseChannel() async {
    _ws?.close();
    _ws = null;
  }

  @override
  void implConfigureBlocking(bool block) {
    // TODO: implement implConfigureBlocking
  }

  @override
  Future<SocketChannel?> bind(SocketAddress local) async {
    // TODO: implement bind
    assert(false, 'cannot bind address: $local');
    _localAddress = local;
    return null;
  }

  @override
  Future<bool> connect(SocketAddress remote) async {
    if (remote is InetSocketAddress) {} else {
      return false;
    }
    try {
      _ws = WebSocket(_url = 'ws://${remote.host}:${remote.port}/');
    } catch (e) {
      throw SocketException('failed to connect web socket: $remote, $e');
    }
    _remoteAddress = remote;
    _caches.clear();
    _ws?.onMessage.listen((ev) {
      var msg = ev.data;
      if (msg is String) {
        msg = Uint8List.fromList(utf8.encode(msg));
      }
      assert(msg is Uint8List, 'msg error');
      _caches.add(msg);
    });
    return _ws != null;
  }

  @override
  Future<Uint8List?> read(int maxLen) async {
    if (_caches.isEmpty) {
      return null;
    }
    // TODO: max length
    return _caches.removeAt(0);
  }

  @override
  Future<int> write(Uint8List src) async {
    if (_ws?.readyState != WebSocket.OPEN) {
      throw SocketException('WebSocket closed: $_url');
    }
    _ws?.send(src);
    return src.length;
  }

}
