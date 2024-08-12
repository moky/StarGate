import 'dart:convert';
import 'dart:typed_data';

import 'package:startrek/skywalker.dart';
import 'package:startrek/nio.dart';
import 'package:startrek/startrek.dart';
import 'package:stargate/websocket.dart';

class Client extends Runner implements PorterDelegate {
  Client(this.remoteAddress, super.millis) {
    gate = ClientGate(this);
    gate.hub = ClientHub(gate);
  }

  final SocketAddress remoteAddress;

  late final ClientGate gate;

  ClientHub get hub => gate.hub as ClientHub;

  Future<void> start() async {
    // await hub.bind(localAddress);
    await hub.connect(remote: remoteAddress);
    // start a background thread
    /*await */run();
  }

  @override
  Future<bool> process() async {
    bool incoming = await hub.process();
    bool outgoing = await gate.process();
    return incoming || outgoing;
  }

  Future<bool> sendData(Uint8List data) async {
    Porter? docker = await gate.fetchPorter(remote: remoteAddress);
    if (docker == null) {
      return false;
    }
    return await docker.sendData(data);
  }

  Future<bool> sendText(String text) async =>
      await sendData(Uint8List.fromList(utf8.encode(text)));

  //
  //  Gate Delegate
  //

  @override
  Future<void> onPorterStatusChanged(PorterStatus previous, PorterStatus current, Porter porter) async {
    SocketAddress? remote = porter.remoteAddress;
    SocketAddress? local = porter.localAddress;
    print('!!! connection ($remote, $local) state changed: ${previous.name} -> ${current.name}');
  }

  @override
  Future<void> onPorterReceived(Arrival arrival, Porter porter) async {
    Uint8List pack = (arrival as PlainArrival).payload;
    int size = pack.length;
    String text = utf8.decode(pack);
    SocketAddress? source = porter.remoteAddress;
    print('<<< received $size byte(s) from $source: $text');
  }

  @override
  Future<void> onPorterSent(Departure departure, Porter porter) async {
    // ignore event for sending success
    // check it in the gate::onConnectionSent()
    SocketAddress? remote = porter.remoteAddress;
    print('::: departure ship sent: $remote');
  }

  @override
  Future<void> onPorterFailed(IOError error, Departure departure, Porter porter) async {
    // ignore event for sending failed
    // check it in the gate::onConnectionFailed()
    SocketAddress? remote = porter.remoteAddress;
    print('::: departure failed: $remote');
  }

  @override
  Future<void> onPorterError(IOError error, Departure departure, Porter porter) async {
    // ignore event for receiving error
    // check it in the gate::onConnectionError()
    SocketAddress? remote = porter.remoteAddress;
    print('::: docker error: $remote');
  }

}
