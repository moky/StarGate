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


class StreamChannelReader extends ChannelReader<SocketChannel> {
  StreamChannelReader(super.channel);

  @override
  Future<Pair<Uint8List?, SocketAddress?>> receive(int maxLen) async {
    SocketAddress? remote = remoteAddress;
    Uint8List? data = await read(maxLen);
    if (data == null/* || data.isEmpty*/) {
      remote = null;
    } else {
      assert(remote != null, 'should not happen: ${data.length}');
    }
    return Pair(data, remote);
  }

}

class StreamChannelWriter extends ChannelWriter<SocketChannel> {
  StreamChannelWriter(super.channel);

  @override
  Future<int> send(Uint8List src, SocketAddress target) async {
    // TCP channel will be always connected
    // so the target address must be the remote address
    assert(target == remoteAddress, 'target error: $target, remote=$remoteAddress');
    return await write(src);
  }

}


class StreamChannel extends BaseChannel<SocketChannel> {
  StreamChannel(super.sock, {super.remote, super.local});

  @override
  SocketReader createReader() => StreamChannelReader(this);

  @override
  SocketWriter createWriter() => StreamChannelWriter(this);

}


class ChannelPool extends AddressPairMap<Channel> {

  @override
  void setItem(Channel? value, {SocketAddress? remote, SocketAddress? local}) {
    Channel? old = getItem(remote: remote, local: local);
    if (old == null || identical(old, value)) {} else {
      removeItem(old, remote: remote, local: local);
    }
    super.setItem(value, remote: remote, local: local);
  }

  @override
  Channel? removeItem(Channel? value, {SocketAddress? remote, SocketAddress? local}) {
    Channel? cached = super.removeItem(value, remote: remote, local: local);
    if (value == null) {} else {
      /*await */value.close();
    }
    if (cached == null || identical(cached, value)) {} else {
      /*await */cached.close();
    }
    return cached;
  }

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
  Channel createChannel(SocketChannel sock, {required SocketAddress remote, SocketAddress? local}) =>
      StreamChannel(sock, remote: remote, local: local);

  @override
  Iterable<Channel> get allChannels => _channelPool.items;

  @override
  // protected
  Channel? removeChannel(Channel? channel, {SocketAddress? remote, SocketAddress? local}) =>
      _channelPool.removeItem(channel, remote: remote, local: local);

  // protected
  Channel? getChannel({required SocketAddress remote, SocketAddress? local}) =>
      _channelPool.getItem(remote: remote, local: local);

  // protected
  void setChannel(Channel channel, {required SocketAddress remote, SocketAddress? local}) =>
      _channelPool.setItem(channel, remote: remote, local: local);

  @override
  Future<Channel?> open({SocketAddress? remote, SocketAddress? local}) async {
    if (remote == null) {
      assert(false, 'remote address empty');
      return null;
    }
    // get channel connected to remote address
    return getChannel(remote: remote, local: local);
  }

}
