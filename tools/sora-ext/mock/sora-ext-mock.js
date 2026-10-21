/* sora-ext mock: a faithful window.soraExt for desktop browsers.
 *
 * Injected by `sora-ext serve` (never shipped in a .soraext). It mirrors
 * the real host semantics from docs/extensions.md §4 and app/lib/src/ext/bridge.dart:
 *
 *  - methods are allow-listed per granted permission (from sora-extension.json);
 *    calling without the permission rejects with {code: 'permission-denied'};
 *  - notify validates title/body lengths; setSettings validates against
 *    settings_schema; unknown methods reject with {code: 'invalid-argument'};
 *  - onEvent subscribers receive events fired via POST /__soraext__/event;
 *  - every call is POSTed to /__soraext__/calls (see GET /__soraext__/calls).
 *
 * Fixture data comes from /__soraext__/fixtures.json
 * (`sora-ext serve --fixtures`). Defaults are built in.
 *
 * If window.soraExt already exists (a real app), this script does nothing.
 */
(function () {
  'use strict';
  if (window.soraExt) return; // real host wins

  var BASE = '/__soraext__';

  function getJSON(url) {
    return fetch(url).then(function (r) {
      if (!r.ok) throw new Error('mock: GET ' + url + ' -> ' + r.status);
      return r.json();
    });
  }

  function deny(code, message) {
    var e = new Error(message);
    e.code = code;
    return Promise.reject(e);
  }

  var manifest = null;
  var fixtures = null;

  function granted(permission) {
    return !!(manifest && manifest.permissions && manifest.permissions.indexOf(permission) >= 0);
  }

  function check(permission) {
    if (!granted(permission)) {
      return deny(
        'permission-denied',
        'the extension was not granted the "' + permission + '" permission (mock: add it to sora-extension.json)'
      );
    }
    return null;
  }

  // --- settings_schema validation (the subset the manifest allows) ---
  function schemaError(prop, why) {
    return deny('invalid-argument', 'setSettings: property "' + prop + '" ' + why);
  }

  function checkSettings(values) {
    var schema = (manifest && manifest.settings_schema) || {};
    var props = schema.properties || {};
    for (var k in values) {
      if (!Object.prototype.hasOwnProperty.call(values, k)) continue;
      var decl = props[k];
      if (!decl) return schemaError(k, 'is not declared in settings_schema');
      var v = values[k];
      switch (decl.type) {
        case 'string':
          if (typeof v !== 'string') return schemaError(k, 'must be a string');
          if (decl.minLength != null && v.length < decl.minLength) return schemaError(k, 'is too short');
          if (decl.maxLength != null && v.length > decl.maxLength) return schemaError(k, 'is too long');
          break;
        case 'integer':
          if (typeof v !== 'number' || Math.floor(v) !== v) return schemaError(k, 'must be an integer');
          /* falls through */
        case 'number':
          if (typeof v !== 'number') return schemaError(k, 'must be a number');
          if (decl.minimum != null && v < decl.minimum) return schemaError(k, 'is below minimum ' + decl.minimum);
          if (decl.maximum != null && v > decl.maximum) return schemaError(k, 'is above maximum ' + decl.maximum);
          break;
        case 'boolean':
          if (typeof v !== 'boolean') return schemaError(k, 'must be a boolean');
          break;
        default:
          return schemaError(k, 'has an unsupported schema type');
      }
      if (decl.enum && decl.enum.indexOf(v) < 0) {
        return schemaError(k, 'must be one of ' + JSON.stringify(decl.enum));
      }
    }
    return null;
  }

  function defaults() {
    var schema = (manifest && manifest.settings_schema) || {};
    var props = schema.properties || {};
    var out = {};
    for (var k in props) {
      if (Object.prototype.hasOwnProperty.call(props, k) && props[k].default !== undefined) {
        out[k] = props[k].default;
      }
    }
    return out;
  }

  var settingsStore = null; // lazy: defaults merged with setSettings
  // Anti-DPI bypass layer, held in memory like the real host's layer:
  // applyBypassLayer replaces it wholesale, getBypassLayer reads it back.
  var bypassLayer = { global: null, bindings: [] };
  // Null until the first applyBypassLayer: like the real host, an
  // untouched layer's state omits updated_at entirely (the key is
  // optional in sora-ext.d.ts SoraBypassLayerState).
  var bypassUpdatedAt = null;
  var listeners = [];

  function logCall(method, args, outcome) {
    fetch(BASE + '/calls', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ method: method, args: args || null, outcome: outcome, at: new Date().toISOString() }),
    }).catch(function () {});
  }

  function call(method, args) {
    var p;
    switch (method) {
      case 'getConnections': {
        var denied = check('connections.read');
        if (denied) return denied.then(null, function (e) { logCall(method, args, 'denied:' + e.code); throw e; });
        var conns = (fixtures && fixtures.connections) || [
          { id: 'c1', process: 'chrome', host: 'example.com', up_bytes: 10240, down_bytes: 1048576 },
          { id: 'c2', process: 'curl', host: 'api.example.com', up_bytes: 512, down_bytes: 4096 },
        ];
        p = Promise.resolve(conns);
        break;
      }
      case 'getServers': {
        var denied2 = check('servers.read');
        if (denied2) return denied2.then(null, function (e) { logCall(method, args, 'denied:' + e.code); throw e; });
        var servers = (fixtures && fixtures.servers) || [
          { id: 's1', name: 'DE-01 · Frankfurt', country: 'DE', latency_ms: 42 },
          { id: 's2', name: 'NL-02 · Amsterdam', country: 'NL', latency_ms: -1 },
        ];
        p = Promise.resolve(servers);
        break;
      }
      case 'notify': {
        var denied3 = check('notifications');
        if (denied3) return denied3.then(null, function (e) { logCall(method, args, 'denied:' + e.code); throw e; });
        var title = args && args.title, body = args && args.body;
        if (typeof title !== 'string' || typeof body !== 'string') {
          p = deny('invalid-argument', 'notify needs {title, body} strings');
          break;
        }
        // Same text rules as the real hosts (bridge.dart, core/ext
        // host.go): trimmed, title non-empty, title <= 120, body <= 500.
        if (title.trim().length === 0) { p = deny('invalid-argument', 'notify: title must not be empty'); break; }
        if (title.trim().length > 120) { p = deny('invalid-argument', 'notify: title exceeds 120 characters'); break; }
        if (body.trim().length > 500) { p = deny('invalid-argument', 'notify: body exceeds 500 characters'); break; }
        // Visible in the desktop browser, like a real notification would be.
        // eslint-disable-next-line no-console
        console.info('[sora-ext mock] notify:', title, '—', body);
        p = Promise.resolve();
        break;
      }
      case 'getSettings': {
        if (settingsStore === null) settingsStore = defaults();
        p = Promise.resolve(JSON.parse(JSON.stringify(settingsStore)));
        break;
      }
      case 'setSettings': {
        if (!args || typeof args !== 'object') {
          p = deny('invalid-argument', 'setSettings needs an object');
          break;
        }
        var bad = checkSettings(args);
        if (bad) { p = bad.then(null, function (e) { logCall(method, args, 'denied:' + e.code); throw e; }); break; }
        if (settingsStore === null) settingsStore = defaults();
        for (var k in args) {
          if (Object.prototype.hasOwnProperty.call(args, k)) settingsStore[k] = args[k];
        }
        p = Promise.resolve();
        break;
      }
      case 'getBypassCapabilities': {
        var capDenied = check('bypass.read');
        if (capDenied) return capDenied.then(null, function (e) { logCall(method, args, 'denied:' + e.code); throw e; });
        var caps = (fixtures && fixtures.bypass_capabilities) || {
          platform: 'linux (mock)',
          backends: [
            { kind: 'nfqws', available: true, reason: '' },
            { kind: 'tpws', available: true, reason: '' },
          ],
        };
        p = Promise.resolve(caps);
        break;
      }
      case 'getBypassState': {
        var stateDenied = check('bypass.read');
        if (stateDenied) return stateDenied.then(null, function (e) { logCall(method, args, 'denied:' + e.code); throw e; });
        p = Promise.resolve({
          platform: 'linux (mock)',
          global_source: bypassLayer.global ? 'extension' : '',
          global_from: bypassLayer.global ? (manifest && manifest.id) || '' : '',
          session_active: false,
          pending_apply: false,
          bindings_count: bypassLayer.bindings.length,
        });
        break;
      }
      case 'getBypassLayer': {
        var layerDenied = check('bypass.read');
        if (layerDenied) return layerDenied.then(null, function (e) { logCall(method, args, 'denied:' + e.code); throw e; });
        var layerState = {
          global: bypassLayer.global,
          bindings: bypassLayer.bindings,
        };
        if (bypassUpdatedAt !== null) layerState.updated_at = bypassUpdatedAt;
        p = Promise.resolve(JSON.parse(JSON.stringify(layerState)));
        break;
      }
      case 'applyBypassLayer': {
        var applyDenied = check('bypass.write');
        if (applyDenied) return applyDenied.then(null, function (e) { logCall(method, args, 'denied:' + e.code); throw e; });
        if (!args || typeof args !== 'object' ||
            (args.global !== null && args.global !== undefined && typeof args.global !== 'object') ||
            (args.bindings !== undefined && !Array.isArray(args.bindings))) {
          p = deny('invalid-argument', 'applyBypassLayer needs {global: strategy|null, bindings: [...]}');
          break;
        }
        bypassLayer = JSON.parse(JSON.stringify({
          global: args.global || null,
          bindings: args.bindings || [],
        }));
        bypassUpdatedAt = new Date().toISOString();
        p = Promise.resolve({ updated_at: bypassUpdatedAt });
        break;
      }
      case 'tuneDesync': {
        var tuneDenied = check('bypass.tune');
        if (tuneDenied) return tuneDenied.then(null, function (e) { logCall(method, args, 'denied:' + e.code); throw e; });
        // A mock winner, labelled as one: the real tuner probes the
        // core's canary endpoints; the mock never touches the network.
        // The strategy is the FULL 29-field shape the real host returns
        // (bypassStrategyToJson) and a combination core validation
        // accepts: a clean nfqws fake profile (the registry's
        // sni_block/fake-autottl-badseq). An earlier mock shape mixed
        // the tpws-only `disorder` flag with desync methods — a mix
        // the core (and the panel's mirrored validator) rejects.
        p = Promise.resolve({
          winner_id: 'mock/d/fake:fake',
          winner_describe: 'MOCK winner from sora-ext serve — not a real tuning result',
          score: 1,
          attempts: 1,
          strategy: {
            split_pos: ['2'],
            disorder: false,
            oob: false,
            tls_record: '',
            host_case: false,
            domain_case: false,
            method_eol: false,
            disorder_scope: '',
            oob_scope: '',
            host_dot: false,
            host_tab: false,
            host_no_space: false,
            method_space: false,
            unix_eol: false,
            split_any_protocol: false,
            tamper_start: '',
            tamper_cutoff: '',
            oob_data: '',
            mss: '',
            desync: ['fake'],
            fake_tls: 'tls',
            fake_quic: '',
            fooling: 'badseq',
            ttl: 0,
            auto_ttl: true,
            repeats: 0,
            filter_tcp: '80,443',
            filter_udp: '',
            filter_l7: 'tls',
          },
        });
        break;
      }
      default:
        p = deny('invalid-argument', 'unknown method "' + method + '"');
    }
    return p.then(
      function (v) { logCall(method, args, 'ok'); return v; },
      function (e) { logCall(method, args, 'rejected:' + (e && e.code)); throw e; }
    );
  }

  function onEvent(listener) {
    if (typeof listener !== 'function') throw new Error('onEvent needs a function');
    listeners.push(listener);
    return function () {
      var i = listeners.indexOf(listener);
      if (i >= 0) listeners.splice(i, 1);
    };
  }

  function dispatch(kind, detail) {
    listeners.slice().forEach(function (fn) {
      try { fn(kind, detail); } catch (e) { console.error('[sora-ext mock] onEvent listener threw:', e); }
    });
  }

  // Boot: load manifest + fixtures, then expose the bridge.
  Promise.all([getJSON(BASE + '/manifest.json'), getJSON(BASE + '/fixtures.json')])
    .then(function (res) {
      manifest = res[0];
      fixtures = res[1] || {};
      window.soraExt = { call: call, onEvent: onEvent };
      // Events arrive over SSE from the dev server.
      var es = new EventSource(BASE + '/events');
      es.addEventListener('soraext-event', function (ev) {
        try {
          var msg = JSON.parse(ev.data);
          dispatch(msg.kind, msg.detail);
        } catch (e) { /* ignore malformed */ }
      });
      // eslint-disable-next-line no-console
      console.info('[sora-ext mock] bridge ready (mock). Fire events: curl -X POST ' +
        window.location.origin + BASE + '/event -d \'{"kind":"session.connected"}\'');
    })
    .catch(function (e) {
      // eslint-disable-next-line no-console
      console.error('[sora-ext mock] failed to boot:', e);
    });
})();
