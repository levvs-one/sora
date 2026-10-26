import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sora/src/ext/bridge.dart';

void main() {
  test('shipped bootstrap executes RPC replies and event subscriptions through the private native channel', () async {
    final child = await Process.start('node', ['--input-type=module', '-e', _exercise]);
    final output = child.stdout.transform(utf8.decoder).join();
    final errors = child.stderr.transform(utf8.decoder).join();
    child.stdin.write(jsonEncode({'source': PanelBridge.bootstrapJs, 'channel': PanelBridge.channelName}));
    await child.stdin.close();
    try {
      final code = await child.exitCode.timeout(const Duration(seconds: 10));
      final stderr = await errors;
      expect(code, 0, reason: stderr);
      expect(jsonDecode(await output), {'sent': 3, 'events': 1, 'stableNativeReference': true});
    } finally {
      child.kill();
      await child.exitCode;
    }
  });
}

const _exercise = r'''
import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';
const {source, channel} = JSON.parse(fs.readFileSync(0, 'utf8'));
assert.notEqual(channel, 'soraExt', 'native channel must not collide with the public API');
const sent = [];
const native = {postMessage: message => sent.push(JSON.parse(message))};
const context = vm.createContext({[channel]: native});
context.window = context;
vm.runInContext(source, context, {timeout: 1000});
const api = context.soraExt;
assert.equal(context[channel], native);
const first = api.call('getSettings');
assert.equal(sent.length, 1);
assert.equal(sent[0].method, 'getSettings');
api._resolve(sent[0].id, true, {interval: 5});
assert.equal(JSON.stringify(await first), JSON.stringify({interval: 5}));
const refused = api.call('getConnections');
const refusal = assert.rejects(refused, error => error.code === 'permission-denied');
api._resolve(sent[1].id, false, 'permission-denied');
await refusal;
const text = 'A quoted "title" / 東京 / </script>';
context[channel] = {postMessage: () => { throw new Error('replaced global must not intercept the captured channel'); }};
const third = api.call('notify', {title: text, body: 'unchanged'});
assert.equal(sent.length, 3);
assert.equal(sent[2].args.title, text);
api._resolve(sent[2].id, true, null);
assert.equal(await third, null);
const events = [];
assert.throws(() => api.onEvent(null), /callback must be a function/);
const off = api.onEvent((kind, detail) => events.push([kind, detail]));
api._event('panel.ready', 'fixture');
off();
api._event('session.connected', 'ignored after unsubscribe');
assert.equal(JSON.stringify(events), JSON.stringify([['panel.ready', 'fixture']]));
api._resolve(999999, true, 'late unmatched reply');
const absent = vm.createContext({});
absent.window = absent;
vm.runInContext(source, absent, {timeout: 1000});
await assert.rejects(absent.soraExt.call('getSettings'), error => error.code === 'internal');
process.stdout.write(JSON.stringify({sent: sent.length, events: events.length, stableNativeReference: true}));
''';
