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


///  Gate with hub for connection
abstract class CommonGate<H extends Hub>
    extends StarGate {
  CommonGate(super.keeper);

  H? hub;

  Future<Docker?> fetchDocker(List<Uint8List> data, {required SocketAddress remote, SocketAddress? local}) async {
    Docker? worker = getDocker(remote: remote, local: local);
    if (worker == null/* && data.isNotEmpty*/) {
      // create & cache docker
      worker = createDocker(data, remote: remote, local: local);
      setDocker(worker, remote: remote, local: local);
      // get connection from hub
      Connection? conn = await hub?.connect(remote: remote, local: local);
      if (conn == null) {
        assert(false, 'failed to get connection: $local -> $remote');
        removeDocker(worker, remote: remote, local: local);
        worker = null;
      } else if (worker is StarDocker) {
        // set connection for this docker
        await worker.setConnection(conn);
      } else {
        assert(false, 'docker error: $remote, $worker');
      }
    }
    return worker;
  }

  Future<bool> sendResponse(Uint8List payload, Arrival ship,
      {required SocketAddress remote, SocketAddress? local}) async {
    assert(ship is PlainArrival, 'arrival ship error: $ship');
    Docker? worker = getDocker(remote: remote, local: local);
    if (worker == null) {
      assert(false, 'docker not found: $local -> $remote');
      return false;
    } else if (!worker.isAlive) {
      assert(false, 'docker not alive: $local -> $remote');
      return false;
    }
    return await worker.sendData(payload);
  }

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
