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

import 'plain.dart';
import 'stream.dart';


abstract class BaseGate<H extends Hub>
    extends StarGate {
  BaseGate(super.keeper);

  H? hub;

  //
  //  Docker
  //

  @override
  Docker? getDocker({required SocketAddress remote, SocketAddress? local}) =>
      super.getDocker(remote: remote);

  @override
  void setDocker(Docker docker, {required SocketAddress remote, SocketAddress? local}) =>
      super.setDocker(docker, remote: remote);

  @override
  void removeDocker(Docker? docker, {required SocketAddress remote, SocketAddress? local}) =>
      super.removeDocker(docker, remote: remote);

  // @override
  // Future<void> heartbeat(Connection connection) async {
  //   // let the client to do the job
  //   if (connection is ActiveConnection) {
  //     super.heartbeat(connection);
  //   }
  // }

  @override
  List<Uint8List> cacheAdvanceParty(Uint8List data, Connection connection) {
    // TODO: cache the advance party before decide which docker to use
    List<Uint8List> array = [];
    if (data.isNotEmpty) {
      array.add(data);
    }
    return array;
  }

  @override
  void clearAdvanceParty(Connection connection) {
    // TODO: remove advance party for this connection
  }

}


///  Gate with hub for connection
abstract class CommonGate extends BaseGate<StreamHub> /*implements Runnable */{
  CommonGate(super.keeper);

  bool _running = false;

  bool get isRunning => _running;

  Future<void> start() async => _running = true;

  Future<void> stop() async => _running = false;

  // @override
  // Future<void> run() async {
  //   _running = true;
  //   while (isRunning) {
  //     if (await process()) {
  //       // process() return true,
  //       // means this thread is busy,
  //       // so process next task immediately
  //     } else {
  //       // nothing to do now,
  //       // have a rest ^_^
  //       await idle();
  //     }
  //   }
  // }
  //
  // // protected
  // Future<void> idle() async => await Runner.sleep(128);

  Future<Channel?> getChannel({SocketAddress? remote, SocketAddress? local}) async =>
      await hub?.open(remote: remote, local: local);

  Future<bool> sendResponse(Uint8List payload, Arrival ship,
      {required SocketAddress remote, SocketAddress? local}) async {
    assert(ship is PlainArrival, 'arrival ship error: $ship');
    Docker? docker = getDocker(remote: remote, local: local);
    if (docker == null) {
      return false;
    }
    return await docker.sendData(payload);
  }

  Future<Docker?> fetchDocker(List<Uint8List> data, {required SocketAddress remote, SocketAddress? local}) async {
    Docker? docker = getDocker(remote: remote, local: local);
    if (docker == null/* && data.isNotEmpty*/) {
      Connection? conn = await hub?.connect(remote: remote, local: local);
      if (conn != null) {
        docker = createDocker(conn, data);
        if (docker == null) {
          assert(false, 'failed to create docker: $remote, $local');
        } else {
          setDocker(docker, remote: remote, local: local);
        }
      }
    }
    return docker;
  }

}
