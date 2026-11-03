import {spawnSync} from 'node:child_process';
import {readFile, writeFile, mkdir} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import path from 'node:path';

const label = process.argv[2];
if (!label || !/^[a-zA-Z0-9_-]+$/.test(label)) throw new Error('Usage: node tools/capture_phone.mjs SCREEN_LABEL');
const adb = process.env.ADB_PATH || path.join(process.env.LOCALAPPDATA ?? '', 'Android/sdk/platform-tools/adb.exe');
function run(args, binary = false) {
  const result = spawnSync(adb, args, {encoding: binary ? null : 'utf8', maxBuffer: 24 * 1024 * 1024, windowsHide: true});
  if (result.status !== 0) throw new Error(`ADB failed: ${result.stderr?.toString()}`);
  return result.stdout;
}
const devices = run(['devices']).split(/\r?\n/).filter(line => /\tdevice$/.test(line)).map(line => line.split('\t')[0]);
const serial = process.env.ANDROID_SERIAL || (devices.length === 1 ? devices[0] : '');
if (!serial || !devices.includes(serial)) throw new Error('Connect exactly one authorized Android phone, or set ANDROID_SERIAL.');
const args = ['-s', serial];
const foreground = run([...args, 'shell', 'dumpsys', 'activity', 'activities']);
if (!foreground.split(/\r?\n/).some(line => /(?:mResumedActivity|topResumedActivity)/.test(line) && line.includes('com.qe190010.recipe_box'))) throw new Error('RecipeBox must be in the foreground. Capture stopped to avoid other phone content.');
const png = run([...args, 'exec-out', 'screencap', '-p'], true);
if (png.subarray(0, 8).toString('hex') !== '89504e470d0a1a0a') throw new Error('ADB did not return a valid PNG.');
const output = process.env.PHONE_SCREENSHOT_DIR || 'artifacts/phone';
await mkdir(output, {recursive: true});
const target = path.join(output, `${label}.png`);
await writeFile(target, png);
const manifestPath = path.join(output, 'manifest.json');
let records = [];
try { records = JSON.parse(await readFile(manifestPath, 'utf8')); } catch (error) { if (error.code !== 'ENOENT') throw error; }
records = records.filter(record => record.label !== label);
records.push({label, file: `${label}.png`, source: 'Physical Android device / adb exec-out screencap -p', serial, model: run([...args, 'shell', 'getprop', 'ro.product.model']).trim(), capturedAt: new Date().toISOString(), sha256: createHash('sha256').update(png).digest('hex')});
await writeFile(manifestPath, JSON.stringify(records, null, 2));
console.log(`Captured ${target} from phone ${serial}`);
