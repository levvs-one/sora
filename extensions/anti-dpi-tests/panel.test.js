/* Node test suite for the Anti-DPI extension package
 * (extensions/anti-dpi). Lives OUTSIDE the package directory on
 * purpose: sora-ext pack ships every non-hidden file of the package
 * dir, and tests are not payload.
 *
 * Run:  node extensions/anti-dpi-tests/panel.test.js
 *
 * Covers:
 *  - drift: panel.js embedded STRINGS/PRESETS are byte-identical to
 *    strings.json / presets.json (the README regeneration procedure);
 *  - strict profile import (B-M3): unknown fields named, wrong types
 *    refused, bindings must be a list, global an object or null — the
 *    host parser's semantics (app/lib/src/ext/bypass.dart); a valid
 *    layer passes with its values unchanged;
 *  - midsni scope (mirrors core/ext ValidateBypassBindingStrategy +
 *    matchResolvesMidSNI): marker as global refused, marker on a
 *    tag/IP/CIDR binding refused, marker on a plain domain accepted;
 *  - preset scope data: exactly the three midsni presets are
 *    "bindings"-scoped and carry the marker, no global preset does;
 *  - tune score: the [0,1] contract scale -> clamped percent (B-L3);
 *  - fooling modes: exactly core/engine/validate.go validFooling
 *    (8 modes, no badack) in FOOLING_MODES and the strings (B-L2);
 *  - errorText: a host message rides next to the code (B-M1);
 *  - the Dart bridge bootstrap shim (app/lib/src/ext/bridge.dart):
 *    a {code, message} error payload rejects with .code == code and
 *    .message == message; the legacy bare-code payload still works;
 *  - the sora-ext mock: its tune winner is the full 29-field shape
 *    and passes the panel validator (B-L1), and an untouched layer
 *    omits updated_at like the real host (B-L4).
 */
'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const PKG = path.join(__dirname, '..', 'anti-dpi');
const REPO = path.join(__dirname, '..', '..');

let passed = 0;
function ok(name, fn) {
  return Promise.resolve()
    .then(fn)
    .then(() => { passed++; console.log('ok -', name); })
    .catch((e) => { console.error('FAIL -', name); throw e; });
}
function plain(v) { return JSON.parse(JSON.stringify(v)); }
function throwsMsg(fn, needle) {
  try { fn(); } catch (e) {
    assert.ok(String(e && e.message).includes(needle),
      'error should mention ' + JSON.stringify(needle) + ', got: ' + (e && e.message));
    return;
  }
  assert.fail('expected a throw mentioning ' + JSON.stringify(needle));
}

/* ---------------- load panel.js in a stub DOM context ---------------- */
function loadPanel() {
  const src = fs.readFileSync(path.join(PKG, 'panel.js'), 'utf8');
  const ctx = {
    window: {},
    navigator: { language: 'en-US' },
    document: {
      addEventListener() {},
      createElement() { return { style: {}, appendChild() {}, addEventListener() {} }; },
      getElementById() { return null; },
    },
    console,
    setTimeout,
    clearTimeout,
  };
  ctx.globalThis = ctx;
  vm.createContext(ctx);
  vm.runInContext(src, ctx, { filename: 'panel.js' });
  return ctx;
}

async function main() {
  const panel = loadPanel();
  const stringsJson = JSON.parse(fs.readFileSync(path.join(PKG, 'strings.json'), 'utf8'));
  const presetsJson = JSON.parse(fs.readFileSync(path.join(PKG, 'presets.json'), 'utf8'));

  await ok('drift: embedded STRINGS == strings.json, PRESETS == presets.json', () => {
    assert.deepStrictEqual(JSON.parse(JSON.stringify(panel.STRINGS)),
      { en: stringsJson.en, ru: stringsJson.ru });
    assert.deepStrictEqual(JSON.parse(JSON.stringify(panel.PRESETS)), presetsJson.presets);
  });

  /* ---------------- strict import (B-M3) ---------------- */
  await ok('strict import: unknown strategy field refused by name', () => {
    throwsMsg(() => panel.strictLayerFromJson({ global: { split_pos: ['1'], bogus: 1 } }),
      'unknown bypass strategy field "bogus"');
  });
  await ok('strict import: unknown layer field refused by name', () => {
    throwsMsg(() => panel.strictLayerFromJson({ global: null, extra: 1 }),
      'unknown bypass layer field "extra"');
  });
  await ok('strict import: ttl as a string refused (no coercion)', () => {
    throwsMsg(() => panel.strictLayerFromJson({ global: { ttl: '7' } }),
      'bypass strategy field "ttl" must be an integer');
  });
  await ok('strict import: fractional ttl refused', () => {
    throwsMsg(() => panel.strictLayerFromJson({ global: { ttl: 1.5 } }),
      'must be an integer');
  });
  await ok('strict import: boolean as string refused', () => {
    throwsMsg(() => panel.strictLayerFromJson({ global: { disorder: 'yes' } }),
      'bypass strategy field "disorder" must be a boolean');
  });
  await ok('strict import: list field as string refused', () => {
    throwsMsg(() => panel.strictLayerFromJson({ global: { split_pos: '1' } }),
      'bypass strategy field "split_pos" must be a list of strings');
  });
  await ok('strict import: bindings as an object refused', () => {
    throwsMsg(() => panel.strictLayerFromJson({ global: null, bindings: { match: 'x' } }),
      'bypass layer "bindings" must be a list');
  });
  await ok('strict import: global neither object nor null refused', () => {
    throwsMsg(() => panel.strictLayerFromJson({ global: 'split' }),
      'bypass layer "global" must be an object or null');
    throwsMsg(() => panel.strictLayerFromJson({ global: 3 }),
      'bypass layer "global" must be an object or null');
  });
  await ok('strict import: binding without a match / strategy refused', () => {
    throwsMsg(() => panel.strictLayerFromJson({ bindings: [{ strategy: {} }] }),
      'bypass binding "match" must be a non-empty string');
    throwsMsg(() => panel.strictLayerFromJson({ bindings: [{ match: 'domain:a.b' }] }),
      'bypass binding "strategy" must be an object');
  });
  await ok('strict import: a valid layer passes with values unchanged', () => {
    const input = {
      global: { split_pos: ['1', 'midsld'], disorder: true, host_case: true },
      bindings: [
        { match: 'domain:example.com', strategy: { desync: ['fake'], fake_tls: 'tls', auto_ttl: true, repeats: 2 } },
        { match: 'example.org', strategy: { tls_record: 'sniext+1' } },
      ],
    };
    const layer = panel.strictLayerFromJson(JSON.parse(JSON.stringify(input)));
    assert.deepStrictEqual(plain(panel.toWire(layer.global)), input.global);
    assert.strictEqual(layer.bindings.length, 2);
    assert.strictEqual(layer.bindings[0].match, 'domain:example.com');
    assert.deepStrictEqual(plain(panel.toWire(layer.bindings[0].strategy)), input.bindings[0].strategy);
    assert.deepStrictEqual(plain(panel.toWire(layer.bindings[1].strategy)), input.bindings[1].strategy);
    // And the parsed layer passes the panel's own core-mirrored validation.
    assert.deepStrictEqual(plain(panel.validateStrategy(layer.global)), []);
    layer.bindings.forEach((b) => assert.deepStrictEqual(plain(panel.validateStrategy(b.strategy)), []));
  });

  /* ---------------- midsni scope ---------------- */
  const marker = () => panel.normalizeStrategy({ split_pos: ['midsni'] });
  const markerTls = () => panel.normalizeStrategy({ tls_record: 'midsni' });
  await ok('midsni: marker as the global strategy is a client error', () => {
    assert.strictEqual(panel.validateMidsniScope(marker(), null).length, 1);
    assert.strictEqual(panel.validateMidsniScope(markerTls(), null).length, 1);
  });
  await ok('midsni: marker on tag/IP/CIDR bindings is a client error', () => {
    for (const m of ['geosite:category-ads', 'geoip:ru', 'ruleset:proxy', 'process:chrome',
      '1.2.3.4', '10.0.0.0/8', 'example.com:443', '2001:db8::1']) {
      assert.strictEqual(panel.validateMidsniScope(marker(), m).length, 1, m);
      assert.strictEqual(panel.matchIsPlainDomain(m), false, m);
    }
  });
  await ok('midsni: marker on a plain domain is fine', () => {
    for (const m of ['domain:example.com', 'full:example.com', 'example.com', 'sub.example.org']) {
      assert.deepStrictEqual(plain(panel.validateMidsniScope(marker(), m)), [], m);
      assert.strictEqual(panel.matchIsPlainDomain(m), true, m);
    }
  });
  await ok('midsni: strategies without the marker are scope-free', () => {
    const noMarker = panel.normalizeStrategy({ split_pos: ['1'] });
    assert.deepStrictEqual(plain(panel.validateMidsniScope(noMarker, null)), []);
    assert.deepStrictEqual(plain(panel.validateMidsniScope(noMarker, 'geosite:x')), []);
  });
  await ok('presets: exactly the three midsni presets are bindings-scoped', () => {
    const scoped = panel.PRESETS.filter((p) => p.scope === 'bindings').map((p) => p.id).sort();
    assert.deepStrictEqual(plain(scoped),
      ['kz_variant/split-midsni', 'sni_block/disorder-midsni', 'sni_block/split-midsni']);
    for (const p of panel.PRESETS) {
      const has = panel.strategyHasMidsni(panel.normalizeStrategy(p.strategy));
      if (p.scope === 'bindings') assert.ok(has, p.id + ' must carry the marker');
      else {
        assert.strictEqual(p.scope, 'global', p.id);
        assert.ok(!has, p.id + ' is global-scoped but carries the marker');
      }
      // Every shipped preset strategy passes the panel validator in its scope.
      assert.deepStrictEqual(plain(panel.validateStrategy(panel.normalizeStrategy(p.strategy))), [], p.id);
    }
  });

  /* ---------------- score (B-L3) ---------------- */
  await ok('tune score: [0,1] contract scale, clamped percent', () => {
    assert.strictEqual(panel.tuneScorePercent(0), 0);
    assert.strictEqual(panel.tuneScorePercent(0.5), 50);
    assert.strictEqual(panel.tuneScorePercent(1), 100);
    assert.strictEqual(panel.tuneScorePercent(1.7), 100);
    assert.strictEqual(panel.tuneScorePercent(-0.3), 0);
    assert.strictEqual(panel.tuneScorePercent(0.994), 99);
  });

  /* ---------------- fooling modes (B-L2) ---------------- */
  await ok('fooling: exactly the core validFooling set, no badack anywhere', () => {
    assert.deepStrictEqual(plain(panel.FOOLING_MODES),
      ['md5sig', 'ts', 'badsum', 'badseq', 'datanoack', 'hopbyhop', 'hopbyhop2', 'none']);
    for (const lang of ['en', 'ru']) {
      const s = panel.STRINGS[lang];
      assert.ok(!s.fields.fooling.hint.includes('badack'), lang + ' hint');
      assert.ok(!s.v_fooling_mode.includes('badack'), lang + ' v_fooling_mode');
      for (const m of panel.FOOLING_MODES) {
        assert.ok(s.v_fooling_mode.includes(m), lang + ' v_fooling_mode lists ' + m);
      }
    }
  });

  /* ---------------- error text (B-M1, panel side) ---------------- */
  await ok('errorText: the core message is shown next to the code text', () => {
    const e = new Error('ядро сказало X');
    e.code = 'invalid-argument';
    const txt = panel.errorText(e);
    assert.ok(txt.includes('ядро сказало X'), txt);
    const bare = new Error('invalid-argument');
    bare.code = 'invalid-argument';
    assert.ok(!panel.errorText(bare).includes('ядро'), 'no invented message');
  });

  /* ---------------- bridge bootstrap shim (B-M1, Dart side) ---------------- */
  await ok('bootstrap shim: {code, message} payload rejects with .code and .message', async () => {
    const dart = fs.readFileSync(path.join(REPO, 'app', 'lib', 'src', 'ext', 'bridge.dart'), 'utf8');
    const start = dart.indexOf("bootstrapJs = '''");
    const end = dart.indexOf("''';", start);
    assert.ok(start >= 0 && end > start, 'bootstrapJs literal found');
    const js = dart.slice(dart.indexOf('\n', start) + 1, end);
    let posted = null;
    const ctx = {
      window: {},
      soraExt: { postMessage(msg) { posted = JSON.parse(msg); } },
      JSON, Promise, Error,
    };
    ctx.globalThis = ctx;
    vm.createContext(ctx);
    vm.runInContext(js, ctx, { filename: 'bootstrap.js' });
    const p = ctx.window.soraExt.call('applyBypassLayer', { global: null });
    assert.ok(posted && posted.method === 'applyBypassLayer');
    ctx.window.soraExt._resolve(posted.id, false, { code: 'invalid-argument', message: 'ядро сказало X' });
    await p.then(
      () => assert.fail('the call must reject'),
      (e) => {
        assert.strictEqual(e.code, 'invalid-argument');
        assert.strictEqual(e.message, 'ядро сказало X');
      });
    // Legacy bare-code payload still works.
    const p2 = ctx.window.soraExt.call('getBypassLayer', {});
    ctx.window.soraExt._resolve(posted.id, false, 'permission-denied');
    await p2.then(
      () => assert.fail('the call must reject'),
      (e) => assert.strictEqual(e.code, 'permission-denied'));
  });

  /* ---------------- the mock (B-L1 winner, B-L4 updated_at) ---------------- */
  await ok('mock: tune winner is a full valid 29-field strategy; empty layer omits updated_at', async () => {
    const src = fs.readFileSync(path.join(REPO, 'tools', 'sora-ext', 'mock', 'sora-ext-mock.js'), 'utf8');
    const manifest = {
      id: 'org.sora.anti-dpi',
      permissions: ['ui.panel', 'bypass.read', 'bypass.write', 'bypass.tune', 'notifications'],
      settings_schema: { properties: {} },
    };
    const ctx = {
      window: { location: { origin: 'http://mock' } },
      fetch(url) {
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve(String(url).includes('manifest') ? manifest : {}),
        });
      },
      EventSource: class { addEventListener() {} },
      Promise, JSON, Date, Error, console,
    };
    ctx.globalThis = ctx;
    vm.createContext(ctx);
    vm.runInContext(src, ctx, { filename: 'sora-ext-mock.js' });
    await new Promise((r) => setTimeout(r, 20));
    assert.ok(ctx.window.soraExt, 'mock bridge booted');

    const layer0 = await ctx.window.soraExt.call('getBypassLayer');
    assert.ok(!('updated_at' in layer0), 'untouched layer must omit updated_at');
    assert.strictEqual(layer0.global, null);

    const tune = await ctx.window.soraExt.call('tuneDesync', { engine: '' });
    assert.strictEqual(Object.keys(tune.strategy).length, 29, 'full 29-field shape');
    assert.deepStrictEqual(
      plain(panel.validateStrategy(panel.normalizeStrategy(tune.strategy))), [],
      'mock winner must pass the panel validator (no disorder x desync mix)');
    assert.ok(tune.score >= 0 && tune.score <= 1, 'score on the [0,1] contract scale');

    await ctx.window.soraExt.call('applyBypassLayer', { global: tune.strategy, bindings: [] });
    const layer1 = await ctx.window.soraExt.call('getBypassLayer');
    assert.ok(typeof layer1.updated_at === 'string' && layer1.updated_at.length > 0,
      'applied layer carries updated_at');
  });

  console.log('\n' + passed + ' checks passed');
}

/* A hung promise must fail loudly, not exit 0 on an empty event loop. */
const watchdog = setTimeout(() => {
  console.error('FAIL - suite timed out (a promise never settled)');
  process.exit(1);
}, 30000);
main()
  .then(() => clearTimeout(watchdog))
  .catch((e) => { console.error(e); process.exit(1); });
