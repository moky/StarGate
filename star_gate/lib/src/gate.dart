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

  //
  //  Docker
  //

  @override
  Porter? getPorter({required SocketAddress remote, SocketAddress? local}) =>
      super.getPorter(remote: remote);

  @override
  Porter? setPorter(Porter porter, {required SocketAddress remote, SocketAddress? local}) =>
      super.setPorter(porter, remote: remote);

  @override
  Porter? removePorter(Porter? porter, {required SocketAddress remote, SocketAddress? local}) =>
      super.removePorter(porter, remote: remote);

  Future<Porter?> fetchPorter({required SocketAddress remote, SocketAddress? local}) async {
    // get connection from hub
    Connection? conn = await hub?.connect(remote: remote, local: local);
    if (conn == null) {
      assert(false, 'failed to get connection: $local -> $remote');
      return null;
    }
    // connected, get docker with this connection
    return await dock(conn, true);
  }

  Future<bool> sendResponse(Uint8List payload, Arrival ship,
      {required SocketAddress remote, SocketAddress? local}) async {
    assert(ship is PlainArrival, 'arrival ship error: $ship');
    Porter? docker = getPorter(remote: remote, local: local);
    if (docker == null) {
      assert(false, 'docker not found: $local -> $remote');
      return false;
    } else if (!docker.isAlive) {
      assert(false, 'docker not alive: $local -> $remote');
      return false;
    }
    return await docker.sendData(payload);
  }

  //
  //  Keep Active
  //

  @override
  Future<void> heartbeat(Connection connection) async {
    // let the client to do the job
    if (connection is ActiveConnection) {
      await super.heartbeat(connection);
    }
  }

}
