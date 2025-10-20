/* license: https://mit-license.org
 *
 *  Star Trek: Interstellar Transport
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
import 'package:startrek/fsm.dart';
import 'package:startrek/nio.dart';
import 'package:startrek/pair.dart';
import 'package:startrek/startrek.dart';


/// Active connection for client
class ActiveConnection extends BaseConnection implements Runnable {
  ActiveConnection({super.remote, super.local});

  WeakReference<Hub>? _hubRef;

  // // private
  // Hub? get hub => _hubRef?.target;

  bool inBackground = false;

  // // protected
  // bool get autoReconnect => !inBackground;

  @override
  bool get isClosed => stateMachine == null;

  @override
  Future<void> start(Hub hub) async {
    _hubRef = WeakReference(hub);
    // 1. start state machine
    await startMachine();
    // 2. start a background thread to check channel
    /*await */run();
  }

  @override
  Future<void> run() async {
    final Duration interval = Duration(milliseconds: 1024);
    final Duration sleeping = Duration(milliseconds: 4096);
    // connection processor with current channel
    await Runner.sleep(interval);
    var driver = _ConnectionDriver(remote: remoteAddress);
    driver.setChannel(channel);
    //
    //  run loop
    //
    while (true) {
      await Runner.sleep(interval);
      // get new socket channel via hub
      Hub? hub = _hubRef?.target;
      if (hub == null) {
        // error
        assert(false, 'hub not found: $localAddress -> $remoteAddress');
        break;
      } else if (isClosed) {
        // connection closed
        logInfo('connection closed: $localAddress -> $remoteAddress');
        break;
      } else if (inBackground) {
        // inactive
        logInfo('connection in background: $localAddress -> $remoteAddress'
            ', connected: $isConnected');
        await Runner.sleep(sleeping);
        continue;
      }
      //
      //  check for reconnecting
      //
      try {
        Channel? sock = await driver.drive(hub);
        if (sock != null) {
          logInfo('new socket channel: $sock, $this');
          await setChannel(sock);
        }
      } catch (e, st) {
        logError('connection error: $e, $st');
        var error = IOError(e);
        await delegate?.onConnectionError(error, this);
      }
    }
    // done
    logInfo('connection exits: $remoteAddress');
  }

  // protected
  void logInfo(String msg) {
    print('[ActiveConnection]         | $msg');
  }

  // protected
  void logError(String msg) {
    print('[ActiveConnection]  ERROR  | $msg');
  }

}

class _ConnectionDriver extends AddressPairObject {
  _ConnectionDriver({super.remote});

  // ignore: non_constant_identifier_names
  static int EXPIRED_INTERVAL = Duration(seconds: 128).inMilliseconds;
  // ignore: non_constant_identifier_names
  static int RETRY_INTERVAL = Duration(seconds: 32).inMilliseconds;

  // timestamps in milliseconds
  int _expiredTime = 0;
  int _retryTime = 0;

  WeakReference<Channel>? _channelRef;

  void setChannel(Channel? sock) {
    if (sock == null) {
      _channelRef = null;
    } else {
      _channelRef = WeakReference(sock);
    }
  }

  // protected
  Future<Channel?> removeChannel(Channel sock, Hub hub) async {
    if (hub is BaseHub) {
      // assert(false, 'hub error: $hub');
    } else {
      assert(false, 'hub error: $hub');
      return null;
    }
    Channel? cached = hub.removeChannel(sock,
      remote: sock.remoteAddress,
      local: sock.localAddress,
    );
    if (cached != null) {
      logWarning('remove cached channel: $cached');
    } else {
      logWarning('channel removed: $sock');
    }
    // close removed/error channels
    if (cached == null || identical(cached, sock)) {} else {
      await hub.closeChannel(cached);
    }
    await hub.closeChannel(sock);
    return cached;
  }

  Future<Channel?> drive(Hub hub) async {
    int now = DateTime.now().millisecondsSinceEpoch;
    // check status for socket channel
    // if current socket channel not found, and the retry time is expired,
    // then try to reconnect.
    Channel? sock = _channelRef?.target;
    if (sock != null) {
      if (sock.isAlive) {
        // the status of socket channel is normal now
        // clear the expired time
        _expiredTime = 0;
      } else if (sock.isClosed) {
        // connection lost
        logWarning('connection lost: $remoteAddress, $sock');
        await removeChannel(sock, hub);
        _channelRef = null;
        _expiredTime = 0;
      } else if (0 < _expiredTime && _expiredTime < now) {
        // connect timeout
        logWarning('connect timeout: $remoteAddress, $sock');
        await removeChannel(sock, hub);
        _channelRef = null;
        _expiredTime = 0;
      }
      return null;
    } else if (now < _retryTime) {
      // wait for next retry
      return null;
    } else {
      _retryTime = now + RETRY_INTERVAL;
    }
    // try to open a new socket channel from the hub.
    // the returned socket channel is opened for connecting,
    // but maybe failed,
    // so set an expired time to close it after timeout.
    sock = await hub.open(remote: remoteAddress, local: localAddress);
    if (sock != null) {
      logInfo('open socket channel: $remoteAddress, $sock');
      _channelRef = WeakReference(sock);
      _expiredTime = now + EXPIRED_INTERVAL;
    } else {
      logError('failed to open socket channel: $remoteAddress');
    }
    return sock;
  }

  // protected
  void logInfo(String msg) {
    print('[ConnectionDriver]         | $msg');
  }

  // protected
  void logWarning(String msg) {
    print('[ConnectionDriver] WARNING | $msg');
  }

  // protected
  void logError(String msg) {
    print('[ConnectionDriver]  ERROR  | $msg');
  }

}
