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

import 'package:object_key/object_key.dart';
import 'package:startrek/nio.dart';
import 'package:startrek/pair.dart';
import 'package:startrek/startrek.dart';


class StreamChannelReader extends ChannelController<SocketChannel> implements SocketReader {
  StreamChannelReader(super.channel);

  @override
  Future<Uint8List?> read(int maxLen) async {
    SocketChannel? sock = socket;
    if (sock == null || sock.isClosed) {
      throw ClosedChannelException();
    }
    return await sock.read(maxLen);
  }

  @override
  Future<Pair<Uint8List?, SocketAddress?>> receive(int maxLen) async {
    Uint8List? data = await read(maxLen);
    if (data == null || data.isEmpty) {
      return Pair(data, null);
    }
    SocketAddress? remote = remoteAddress;
    assert(remote != null, 'should not happen: ${data.length}');
    return Pair(data, remote);
  }

}

class StreamChannelWriter extends ChannelController<SocketChannel> implements SocketWriter {
  StreamChannelWriter(super.channel);

  // protected
  Future<int> sendAll(WritableByteChannel sock, Uint8List src) async {
    /// TODO: override for sending
    return await sock.write(src);
  }

  @override
  Future<int> write(Uint8List src) async {
    SocketChannel? sock = socket;
    if (sock == null || sock.isClosed) {
      throw ClosedChannelException();
    }
    return await sendAll(sock, src);
  }

  @override
  Future<int> send(Uint8List src, SocketAddress target) async {
    // TCP channel will be always connected
    // so the target address must be the remote address
    assert(target == remoteAddress, 'target error: $target, remote=$remoteAddress');
    return await write(src);
  }

}


class StreamChannel extends BaseChannel<SocketChannel> {
  StreamChannel({super.remote, super.local});

  @override
  SocketReader createReader() => StreamChannelReader(this);

  @override
  SocketWriter createWriter() => StreamChannelWriter(this);

}


class ChannelPool extends AddressPairMap<Channel> {

  @override
  Channel? setItem(Channel? value, {SocketAddress? remote, SocketAddress? local}) {
    // remove cached item
    Channel? cached = super.removeItem(value, remote: remote, local: local);
    // if (cached == null || identical(cached, value)) {} else {
    //   /*await */cached.close();
    // }
    Channel? old = super.setItem(value, remote: remote, local: local);
    assert(old == null, 'should not happen');
    return cached;
  }

  // @override
  // Channel? removeItem(Channel? value, {SocketAddress? remote, SocketAddress? local}) {
  //   Channel? cached = super.removeItem(value, remote: remote, local: local);
  //   if (cached == null || identical(cached, value)) {} else {
  //     /*await */cached.close();
  //   }
  //   if (value == null) {} else {
  //     /*await */value.close();
  //   }
  //   return cached;
  // }

}


abstract class StreamHub extends BaseHub {
  StreamHub(super.delegate) {
    _channelPool = createChannelPool();
  }

  late final AddressPairMap<Channel> _channelPool;

  // protected
  AddressPairMap<Channel> createChannelPool() => ChannelPool();

  //
  //  Channel
  //

  ///  Create channel with socket & addresses
  ///
  /// @param sock   - socket
  /// @param remote - remote address
  /// @param local  - local address
  /// @return null on socket error
  // protected
  Channel createChannel({required SocketAddress remote, SocketAddress? local}) =>
      StreamChannel(remote: remote, local: local);

  @override // protected
  Iterable<Channel> get allChannels => _channelPool.items;

  // protected
  Channel? getChannel({required SocketAddress remote, SocketAddress? local}) =>
      _channelPool.getItem(remote: remote, local: local);

  // protected
  Channel? setChannel(Channel channel, {required SocketAddress remote, SocketAddress? local}) =>
      _channelPool.setItem(channel, remote: remote, local: local);

  @override // protected
  Channel? removeChannel(Channel? channel, {SocketAddress? remote, SocketAddress? local}) =>
      _channelPool.removeItem(channel, remote: remote, local: local);

  // protected
  static Future<bool> setSocket(SocketChannel socket, BaseChannel channel) async {
    try {
      await channel.setSocket(socket);
      return true;
    } catch (e) {
      return false;
    }
  }

}
