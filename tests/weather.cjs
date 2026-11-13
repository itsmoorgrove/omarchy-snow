const fs = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const path = require('node:path');
const api = vm.createContext({});
vm.runInContext(fs.readFileSync(path.join(__dirname,'../Weather.js'),'utf8').replace(/^\.pragma library\s*/, ''), api);
const now = 1794582000;
const report = (code, time=now) => JSON.stringify({current:{weather_code:code,time}});
for (const code of [71,73,75,77,85,86]) assert.equal(api.current(report(code),now).snow,true);
for (const code of [0,3,45,61,65,66,67,80,95]) assert.equal(api.current(report(code),now).snow,false);
for (const raw of ['', '{}', 'null', '<img src="https://example.invalid/tracker">', 'x'.repeat(16385), report(999),report(71,now-5401),report(71,now+901)]) assert.equal(api.current(raw,now),null);
assert.equal(api.current(JSON.stringify({current:{time:now,weather_code:'71'}}),now),null);
const place = {name:'Stockholm',latitude:59.3293,longitude:18.0686};
assert.equal(api.location(JSON.stringify(place)).name,'Stockholm');
for (const place of [{name:'x',latitude:null,longitude:1},{name:'x',latitude:91,longitude:1},{name:'x',latitude:1,longitude:181},{name:'x'.repeat(161),latitude:1,longitude:1}]) assert.equal(api.location(JSON.stringify(place)),null);
const hostile = '<img src="https://example.invalid/tracker">';
assert.equal(api.location(JSON.stringify({...place,name:hostile})).name,hostile);
const panel=fs.readFileSync(path.join(__dirname,'../SettingsPanel.qml'),'utf8');
assert.match(panel,/textFormat: Text.PlainText\s+text: SnowState.location/);
assert.ok(!panel.includes('tooltipText'));
for (const file of ['BarWidget.qml','SettingsPanel.qml','SnowSurface.qml','SnowState.qml','Ledges.js','Weather.js']) {
 const code=fs.readFileSync(path.join(__dirname,'..',file),'utf8');
 assert.ok(!/^\s*\/\//m.test(code),file);
}
console.log('PASS: all snow codes, rain exclusion, fresh/stale/future data, bounds, coordinates, plain-text sinks, no code comments');
