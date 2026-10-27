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

  test('Hello source replaces stale rows on RPC errors and recovers without automatic notices', () async {
    final child = await Process.start('node', ['--input-type=module', '-e', _exerciseHello]);
    final output = child.stdout.transform(utf8.decoder).join();
    final errors = child.stderr.transform(utf8.decoder).join();
    child.stdin.write(jsonEncode({'html': await File('../examples/hello-panel/panel.html').readAsString()}));
    await child.stdin.close();
    try {
      final code = await child.exitCode.timeout(const Duration(seconds: 10));
      expect(code, 0, reason: await errors);
      expect(jsonDecode(await output), {'recovered': true, 'notices': 1});
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

const _exerciseHello = r'''
import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';
const {html} = JSON.parse(fs.readFileSync(0, 'utf8'));
const source = html.match(/<script>([\s\S]*?)<\/script>/)[1];
const elements = Object.fromEntries(['content', 'refresh', 'about', 'info', 'close-info', 'notify'].map(id => [id, {
  innerHTML: '', attributes: {}, listeners: {}, disabled: false,
  setAttribute(name, value) { this.attributes[name] = value; },
  addEventListener(event, callback) { assert.equal(typeof callback, 'function'); this.listeners[event] = callback; },
}]));
let failure = 'not-connected';
let notices = 0;
const context = vm.createContext({
  document: {getElementById: id => elements[id]},
  setInterval(callback, delay) { assert.equal(typeof callback, 'function'); assert.equal(delay, 5000); return 1; },
  console,
  soraExt: {
    onEvent(callback) { assert.equal(typeof callback, 'function'); },
    async call(method) {
      if (method === 'notify') { notices++; return; }
      assert.equal(method, 'getConnections');
      if (failure) throw Object.assign(new Error('synthetic fixture'), {code: failure});
      return [{host: 'fixture<&>', process: 'test', up_bytes: 0, down_bytes: 1}];
    },
  },
});
context.window = context;
vm.runInContext(source, context, {timeout: 1000});
await new Promise(setImmediate);
assert.match(elements.content.innerHTML, /Connect Sora/);
failure = null;
await vm.runInContext('load()', context);
assert.match(elements.content.innerHTML, /fixture&lt;&amp;&gt;/);
for (const code of ['internal', 'permission-denied']) {
  failure = code;
  await vm.runInContext('load()', context);
  assert.doesNotMatch(elements.content.innerHTML, /fixture/);
  assert.match(elements.content.innerHTML, code === 'internal' ? /unavailable/ : /Allow connection access/);
  assert.doesNotMatch(elements.content.innerHTML, /No active connections/);
  assert.equal(elements.refresh.disabled, false);
  assert.equal(elements.refresh.attributes['aria-busy'], 'false');
  assert.equal(notices, 0);
}
await vm.runInContext('load(true)', context);
assert.equal(notices, 1);
failure = null;
await vm.runInContext('load()', context);
assert.match(elements.content.innerHTML, /fixture&lt;&amp;&gt;/);
process.stdout.write(JSON.stringify({recovered: true, notices}));
''';
