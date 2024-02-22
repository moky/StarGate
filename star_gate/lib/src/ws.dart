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
import 'dart:io';
import 'dart:typed_data';

import 'package:startrek/nio.dart';
import 'package:startrek/startrek.dart';

import 'gate.dart';
import 'plain.dart';
import 'stream.dart';
import 'ws_html.dart' if (dart.library.io) 'ws_io.dart';


class ClientGate extends CommonGate {
  ClientGate(super.keeper);

  @override
  Docker? createDocker(Connection conn, List<Uint8List> data) {
    PlainDocker docker = PlainDocker(conn);
    docker.delegate = delegate;
    return docker;
  }

  @override
  Future<void> heartbeat(Connection connection) async {
    // let the client to do the job
    if (connection is ActiveConnection) {
      super.heartbeat(connection);
    }
  }

}


class ClientHub extends StreamHub {
  ClientHub(super.delegate);

  void putChannel(Channel channel) =>
      setChannel(channel, remote: channel.remoteAddress!, local: channel.localAddress);

  @override
  Connection? getConnection({required SocketAddress remote, SocketAddress? local}) =>
      super.getConnection(remote: remote);

  @override
  void setConnection(Connection conn, {required SocketAddress remote, SocketAddress? local}) =>
      super.setConnection(conn, remote: remote);

  @override
  void removeConnection(Connection? conn, {required SocketAddress remote, SocketAddress? local}) =>
      super.removeConnection(conn, remote: remote);

  @override
  Connection? createConnection(Channel channel, {required SocketAddress remote, SocketAddress? local}) {
    ActiveConnection conn = ActiveConnection(this, channel, remote: remote, local: local);
    conn.delegate = delegate;  // gate
    /*await */conn.start();    // start FSM
    return conn;
  }

  @override
  Future<Channel?> open({SocketAddress? remote, SocketAddress? local}) async {
    Channel? channel = await super.open(remote: remote, local: local);
    if (channel == null && remote != null) {
      channel = await _create(remote: remote, local: local);
      if (channel != null) {
        setChannel(channel, remote: channel.remoteAddress!, local: channel.localAddress);
      }
    }
    return channel;
  }

  Future<Channel?> _create({required SocketAddress remote, SocketAddress? local}) async {
    try {
      SocketChannel sock = await _createSocket(remote: remote, local: local);
      local ??= sock.localAddress;
      return createChannel(sock, remote: remote, local: local);
    } on IOException catch (e) {
      print('[WS] cannot create socket: $remote, $local, $e');
      return null;
    }
  }

}


Future<SocketChannel> _createSocket({required SocketAddress remote, SocketAddress? local}) async {
  SocketChannel sock = _WebSocketChannel();
  sock.configureBlocking(true);
  if (local != null) {
    await sock.bind(local);
  }
  await sock.connect(remote);
  sock.configureBlocking(false);
  return sock;
}


class _WebSocketChannel extends SocketChannel {

  final List<Uint8List> _caches = [];

  SocketAddress? _remoteAddress;
  SocketAddress? _localAddress;

  WebSocketConnector? _socket;

  @override
  bool get isClosed => super.isClosed || _socket?.readyState == WebSocketConnector.closed;

  @override
  bool get isBound => _localAddress != null;

  @override
  bool get isConnected => _socket?.readyState == WebSocketConnector.open;

  @override
  SocketAddress? get remoteAddress => _remoteAddress;

  @override
  SocketAddress? get localAddress => _localAddress;

  @override
  String toString() {
    Type clazz = runtimeType;
    return '<$clazz url="${_socket?.url}" state=${_socket?.readyState} />';
  }

  @override
  Future<void> implCloseChannel() async {
    await _socket?.close();
    _socket = null;
  }

  @override
  void implConfigureBlocking(bool block) {
    // TODO: implement implConfigureBlocking
  }

  @override
  Future<SocketChannel?> bind(SocketAddress local) async {
    // TODO: implement bind
    _localAddress = local;
    return null;
  }

  @override
  Future<bool> connect(SocketAddress remote) async {
    if (remote is InetSocketAddress) {} else {
      assert(false, 'remote address error: $remote');
      return false;
    }
    Uri url = Uri.parse('ws://${remote.host}:${remote.port}/');
    WebSocketConnector connector = WebSocketConnector(url);
    bool ok = await connector.connect();
    if (ok) {
      _remoteAddress = remote;
      _caches.clear();
      _socket = connector;
      connector.listen((msg) => _caches.add(msg));
    }
    return ok;
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
    WebSocketConnector? connector = _socket;
    if (connector == null) {
      assert(false, 'socket not connect');
      return -1;
    }
    return await connector.write(src);
  }

}
