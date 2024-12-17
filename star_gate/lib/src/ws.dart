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
import 'dart:typed_data';

import 'package:startrek/nio.dart';
import 'package:startrek/startrek.dart';

import 'gate.dart';
import 'plain.dart';
import 'stream.dart';
import 'ws_html.dart' if (dart.library.io) 'ws_io.dart';


class ClientGate extends CommonGate<ClientHub> {
  ClientGate(super.keeper);

  @override
  Porter createPorter({required SocketAddress remote, SocketAddress? local}) {
    var docker = PlainPorter(remote: remote, local: local);
    docker.delegate = delegate;
    return docker;
  }

}


class ClientHub extends StreamHub {
  ClientHub(super.delegate);

  @override
  Connection createConnection({required SocketAddress remote, SocketAddress? local}) {
    ActiveConnection conn = ActiveConnection(remote: remote, local: local);
    conn.delegate = delegate;  // gate
    return conn;
  }

  //
  //  Open Socket Channel
  //

  @override
  Future<Channel?> open({SocketAddress? remote, SocketAddress? local}) async {
    if (remote == null) {
      assert(false, 'remote address empty');
      return null;
    }
    //
    //  0. pre-checking
    //
    Channel? channel = getChannel(remote: remote, local: local);
    if (channel != null) {
      // check local address
      if (local == null) {
        return channel;
      }
      SocketAddress? address = channel.localAddress;
      if (address == null || address == local) {
        return channel;
      }
    }
    //
    //  1. create new channel & cache it
    //
    channel = createChannel(remote: remote, local: local);
    local ??= channel.localAddress;
    // cache the channel
    var cached = setChannel(channel, remote: remote, local: local);
    if (cached == null || identical(cached, channel)) {} else {
      await cached.close();
    }
    //
    //  2. create socket for this channel
    //
    if (channel is BaseChannel) {
      SocketChannel? socket = await _createSocket(remote: remote, local: local);
      if (socket == null) {
        assert(false, 'failed to prepare socket: $local -> $remote');
        removeChannel(channel, remote: remote, local: local);
        channel = null;
      } else {
        // set socket for this channel
        await StreamHub.setSocket(socket, channel);
      }
    }
    return channel;
  }

}

Future<SocketChannel?> _createSocket({required SocketAddress remote, SocketAddress? local}) async {
  try {
    SocketChannel? sock = _WebSocketChannel();
    sock.configureBlocking(true);
    if (local != null) {
      await sock.bind(local);
    }
    bool ok = await sock.connect(remote);
    if (!ok) {
      // throw SocketException('failed to connect remote address: $remote');
      print('[WS] failed to connect remote address: $remote');
      return null;
    }
    sock.configureBlocking(false);
    return sock;
  } on Exception catch (e) {
    print('[WS] cannot create socket: $remote, $local, $e');
    return null;
  }
}


class _WebSocketChannel extends SocketChannel {

  final List<Uint8List> _caches = [];

  SocketAddress? _remoteAddress;
  SocketAddress? _localAddress;

  WebSocketConnector? _socket;

  @override
  bool get isClosed => super.isClosed || _socket?.isClosed == true;

  @override
  // bool get isBound => _localAddress != null;
  bool get isBound => false;

  @override
  // bool get isConnected => _remoteAddress != null;
  bool get isConnected => _socket?.isConnected == true;

  @override
  SocketAddress? get remoteAddress => _remoteAddress;

  @override
  SocketAddress? get localAddress => _localAddress;

  @override
  String toString() {
    Type clazz = runtimeType;
    return '<$clazz remote="$remoteAddress" local="$localAddress">\n\t'
        '$_socket\n</$clazz>';
  }

  @override
  Future<void> implCloseChannel() async {
    var sock = _socket;
    _socket = null;
    await sock?.close();
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
    if (remote is! InetSocketAddress) {
      assert(false, 'remote address error: $remote');
      return false;
    } else if (_socket != null) {
      assert(false, 'socket already connected: $_socket');
      return false;
    }
    Uri url = Uri.parse('ws://${remote.host}:${remote.port}/');
    WebSocketConnector connector = WebSocketConnector(url);
    _socket = connector;
    bool ok = await connector.connect();
    if (ok) {
      _remoteAddress = remote;
      _caches.clear();
      // add an empty package to update "connection.lastReceivedTime"
      _caches.add(PlainPorter.NOOP);
      // read buffer
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
    } else if (src.isEmpty) {
      return 0;
    }
    return await connector.write(src);
  }

}
