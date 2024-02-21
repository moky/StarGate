import 'dart:convert';
import 'dart:typed_data';

import 'package:startrek/fsm.dart';
import 'package:startrek/nio.dart';
import 'package:startrek/startrek.dart';
import 'package:stargate/websocket.dart';

class Client extends Runner implements DockerDelegate {
  Client(this.remoteAddress) {
    gate = ClientGate(this);
    gate.hub = ClientHub(gate);
  }

  final SocketAddress remoteAddress;

  late final ClientGate gate;

  ClientHub get hub => gate.hub as ClientHub;

  @override
  bool get isRunning => super.isRunning && gate.isRunning;

  Future<void> start() async {
    // await hub.bind(localAddress);
    await hub.connect(remote: remoteAddress);
    // start a background thread
    /*await */run();
  }

  @override
  Future<void> stop() async {
    await super.stop();
    await gate.stop();
  }

  @override
  Future<void> setup() async {
    await super.setup();
    await gate.start();
  }

  @override
  Future<void> finish() async {
    await gate.stop();
    await super.finish();
  }

  @override
  Future<bool> process() async {
    bool incoming = await hub.process();
    bool outgoing = await gate.process();
    return incoming || outgoing;
  }

  Future<bool> sendData(Uint8List data) async {
    Docker? docker = await gate.fetchDocker([], remote: remoteAddress);
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
  Future<void> onDockerStatusChanged(DockerStatus previous, DockerStatus current, Docker docker) async {
    SocketAddress? remote = docker.remoteAddress;
    SocketAddress? local = docker.localAddress;
    print('!!! connection ($remote, $local) state changed: ${previous.name} -> ${current.name}');
  }

  @override
  Future<void> onDockerReceived(Arrival arrival, Docker docker) async {
    Uint8List pack = (arrival as PlainArrival).payload;
    int size = pack.length;
    String text = utf8.decode(pack);
    SocketAddress? source = docker.remoteAddress;
    print('<<< received $size byte(s) from $source: $text');
  }

  @override
  Future<void> onDockerSent(Departure departure, Docker docker) async {
    // ignore event for sending success
    // check it in the gate::onConnectionSent()
    SocketAddress? remote = docker.remoteAddress;
    print('::: departure ship sent: $remote');
  }

  @override
  Future<void> onDockerFailed(IOError error, Departure departure, Docker docker) async {
    // ignore event for sending failed
    // check it in the gate::onConnectionFailed()
    SocketAddress? remote = docker.remoteAddress;
    print('::: departure failed: $remote');
  }

  @override
  Future<void> onDockerError(IOError error, Departure departure, Docker docker) async {
    // ignore event for receiving error
    // check it in the gate::onConnectionError()
    SocketAddress? remote = docker.remoteAddress;
    print('::: docker error: $remote');
  }

}
