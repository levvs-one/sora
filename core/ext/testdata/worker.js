console.log('worker started');
if (typeof require !== 'undefined' || typeof fetch !== 'undefined' || typeof __call !== 'undefined') {
  throw new Error('native API escaped');
}
let denied = false;
try { await window.soraExt.call('getServers'); }
catch (error) { denied = error.code === 'permission-denied'; }
if (!denied) throw new Error('permission was not enforced');
const response = await window.soraExt.call('net.fetch', {url: 'https://api.example.com/status'});
if (response.status !== 200 || response.body !== 'ready') throw new Error('bad fetch response');
try {
  await window.soraExt.call('net.fetch', {url: 'https://refused.example.org/'});
  throw new Error('allowlist was not enforced');
} catch (error) { if (error.code !== 'permission-denied') throw error; }
window.soraExt.onEvent((kind) => { console.log(kind); });
console.log('worker finished');
