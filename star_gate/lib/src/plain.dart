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
import 'dart:convert';
import 'dart:typed_data';

import 'package:startrek/startrek.dart';


class PlainArrival extends ArrivalShip {
  PlainArrival(this._completed, [super.now]);

  final Uint8List _completed;

  Uint8List get payload => _completed;

  @override
  dynamic get sn => null;  // plain ship has no SN

  @override
  Arrival? assemble(Arrival income) {
    assert(income == this, 'plain arrival error: $income, $this');
    // plain arrival needs no assembling
    return this;
  }

}


class PlainDeparture extends DepartureShip {
  PlainDeparture(Uint8List pack, int prior, bool needsRespond)
      : _completed = pack,
        _fragments = [pack],
        _important = needsRespond,
        super(priority: prior, maxTries: 1);

  final Uint8List _completed;
  final List<Uint8List> _fragments;
  final bool _important;

  Uint8List get payload => _completed;

  @override
  dynamic get sn => null;  // plain ship has no SN

  @override
  List<Uint8List> get fragments => _fragments;

  @override
  bool checkResponse(Arrival response) => false;
  // plain departure needs no response

  @override
  bool get isImportant => _important;

}


class PlainPorter extends StarPorter {
  PlainPorter({super.remote, super.local});

  // protected
  Arrival createArrival(Uint8List pack) => PlainArrival(pack);

  // protected
  Departure createDeparture(Uint8List pack, int priority, bool needsRespond) =>
      PlainDeparture(pack, priority, needsRespond);

  @override
  List<Arrival> getArrivals(Uint8List data) => [createArrival(data)];

  @override
  Future<Arrival?> checkArrival(Arrival income) async {
    assert(income is PlainArrival, 'arrival ship error: $income');
    Uint8List data = (income as PlainArrival).payload;
    if (data.length == 4) {
      if (_equals(data, PING)) {
        // PING -> PONG
        /*await */respond(PONG);
        return null;
      } else if (_equals(data, PONG) || _equals(data, NOOP)) {
        // ignore
        return null;
      }
    }
    return income;
  }

  //
  //  Sending
  //

  /// sending response
  Future<bool> respond(Uint8List payload) async =>
      await sendShip(createDeparture(payload, DeparturePriority.SLOWER, false));

  /// sending payload with priority
  Future<bool> send(Uint8List payload, int priority) async =>
      await sendShip(createDeparture(payload, priority, true));

  @override
  Future<bool> sendData(Uint8List payload) async =>
      await send(payload, DeparturePriority.NORMAL);

  @override
  Future<void> heartbeat() async =>
    await sendShip(createDeparture(PING, DeparturePriority.SLOWER, false));

  // ignore_for_file: non_constant_identifier_names
  static final Uint8List PING = _bytes('PING');
  static final Uint8List PONG = _bytes('PONG');
  static final Uint8List NOOP = _bytes('NOOP');
  // static final Uint8List OK = _bytes('OK');

}

Uint8List _bytes(String text) => Uint8List.fromList(utf8.encode(text));

bool _equals(Uint8List a, Uint8List b) {
  if (identical(a, b)) {
    return true;
  } else if (a.length != b.length) {
    return false;
  }
  for (int i = a.length - 1; i >= 0; --i) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
