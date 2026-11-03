import {spawnSync} from 'node:child_process';
import {mkdir, readFile, writeFile} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import path from 'node:path';
const project = 'recipebox-qe190010-20261103';
const adb = path.join(process.env.LOCALAPPDATA, 'Android/sdk/platform-tools/adb.exe');
const device = JSON.parse(await readFile('artifacts/phone/device.json', 'utf8'));
const output = 'artifacts/console'; await mkdir(output, {recursive: true});
function run(args, binary = false) { const r = spawnSync(adb, ['-s',device.serial,...args], {encoding: binary ? null : 'utf8', maxBuffer:24000000, windowsHide:true}); if(r.status!==0)throw Error(r.stderr.toString()); return binary ? r.stdout : r.stdout.trim(); }
const mode = process.argv[2];
if(mode !== 'open') {
  const foreground=run(['shell','dumpsys','activity','activities']);
  if(!foreground.split(/\r?\n/).some(l=>/(?:mResumedActivity|topResumedActivity)/.test(l)&&l.includes('com.android.chrome')))throw Error('Chrome is not in the foreground; no action was performed.');
}
if(mode === 'open') {
  const section = process.argv[3] || 'authentication/users';
  if(!/^[a-zA-Z0-9_/-]+$/.test(section))throw Error('Invalid console section.');
  console.log(run(['shell','am','start','-W','-a','android.intent.action.VIEW','-d',`https://console.firebase.google.com/project/${project}/${section}`,'-p','com.android.chrome']));
} else if(mode === 'inspect') {
  run(['shell','uiautomator','dump','/sdcard/recipebox_console.xml']);
  run(['pull','/sdcard/recipebox_console.xml',`${output}/current.xml`]);
  const xml = await readFile(`${output}/current.xml`,'utf8');
  for(const match of xml.matchAll(/<node\s+([^>]+)>?/g)) {
    const attrs=Object.fromEntries([...match[1].matchAll(/([a-z-]+)="([^"]*)"/g)].map(m=>[m[1],m[2]]));
    if(attrs.text || attrs['content-desc']) console.log(JSON.stringify({text:attrs.text,label:attrs['content-desc'],bounds:attrs.bounds,clickable:attrs.clickable}));
  }
} else if(mode === 'capture') {
  const name = process.argv[3]; if(!/^[a-zA-Z0-9_-]+$/.test(name))throw Error('Invalid label.');
  const foreground=run(['shell','dumpsys','activity','activities']);
  if(!foreground.split(/\r?\n/).some(l=>/(?:mResumedActivity|topResumedActivity)/.test(l)&&l.includes('com.android.chrome')))throw Error('Chrome is not in the foreground.');
  const png=run(['exec-out','screencap','-p'],true);
  await writeFile(`${output}/${name}.png`,png);
  let records=[];try{records=JSON.parse(await readFile(`${output}/manifest.json`,'utf8'));}catch(e){if(e.code!=='ENOENT')throw e;}
  records=records.filter(r=>r.name!==name);records.push({name,file:`${name}.png`,project,source:'Actual Firebase console in Chrome on physical Android phone, captured with ADB',capturedAt:new Date().toISOString(),sha256:createHash('sha256').update(png).digest('hex')});
  await writeFile(`${output}/manifest.json`,JSON.stringify(records,null,2));console.log(`Captured ${output}/${name}.png`);
} else if(mode === 'tap') {
  const coords=process.argv.slice(3).map(Number);if(coords.length!==2||coords.some(n=>!Number.isInteger(n)||n<0||n>4000))throw Error('Invalid tap coordinates.');
  run(['shell','input','tap',...coords.map(String)]);
} else if(mode === 'scroll') {
  run(['shell','input','swipe','900','1800','900','750','500']);
} else throw Error('Use open, inspect, capture, tap, or scroll.');
