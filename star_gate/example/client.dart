import 'dart:convert';
import 'dart:typed_data';

import 'package:startrek/startrek.dart';
import 'package:stargate/websocket.dart';

class Client implements DockerDelegate {
  Client(this.remoteAddress) {
    gate = ClientGate(this);
    gate.hub = ClientHub(gate);
  }

  final SocketAddress remoteAddress;

  late final ClientGate gate;

  ClientHub get hub => gate.hub as ClientHub;

  void start() {
    // hub.bind(localAddress);
    hub.connect(remote: remoteAddress);
    gate.start();
  }

  void stop() {
    gate.stop();
  }

  Future<bool> sendData(Uint8List data) async {
    Docker? docker = await gate.fetchDocker([], remote: remoteAddress);
    if (docker == null || docker.isClosed) {
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
    print('!!! connection ($remote, $local) state changed: $previous -> $current, docker: $docker');
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
