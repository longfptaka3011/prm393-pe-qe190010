import {spawn, spawnSync} from 'node:child_process';
import {readFile, writeFile, mkdir} from 'node:fs/promises';
import {randomBytes, createHash} from 'node:crypto';
import {createServer} from 'node:http';
import path from 'node:path';

const adb = process.env.ADB_PATH || path.join(process.env.LOCALAPPDATA ?? '', 'Android/sdk/platform-tools/adb.exe');
const listed = spawnSync(adb, ['devices'], {encoding: 'utf8', windowsHide: true});
if (listed.status !== 0) throw new Error('ADB could not list connected devices.');
const devices = listed.stdout.split(/\r?\n/).filter(line => /\tdevice$/.test(line)).map(line => line.split('\t')[0]);
const deviceId = process.argv[2] || process.env.ANDROID_SERIAL || (devices.length === 1 ? devices[0] : '');
if (!deviceId || !/^[a-zA-Z0-9_.:-]+$/.test(deviceId)) throw new Error('Connect one phone or pass its Android serial.');
function run(args, binary = false) {
  const result = spawnSync(adb, ['-s', deviceId, ...args], {encoding: binary ? null : 'utf8', windowsHide: true, maxBuffer: 24 * 1024 * 1024});
  if (result.status !== 0) throw new Error(`ADB failed: ${result.stderr?.toString()}`);
  return binary ? result.stdout : result.stdout.trim();
}
if (run(['get-state']) !== 'device') throw new Error('Connect and authorize the phone.');
if (deviceId.startsWith('emulator-') || run(['shell', 'getprop', 'ro.kernel.qemu']) === '1') throw new Error('A physical phone is required.');
const config = JSON.parse(await readFile('assets/firebase_config.json', 'utf8'));
if (!config.apiKey) throw new Error('Configure Firebase before collecting report evidence.');
const output = process.env.PHONE_SCREENSHOT_DIR || 'artifacts/phone';
await mkdir('.local', {recursive: true}); await mkdir(output, {recursive: true});
const device = {serial: deviceId, model: run(['shell', 'getprop', 'ro.product.model']), androidVersion: run(['shell', 'getprop', 'ro.build.version.release']), physicalDevice: true, captureStartedAt: new Date().toISOString()};
await writeFile(path.join(output, 'device.json'), JSON.stringify(device, null, 2));
const screenshotToken = randomBytes(24).toString('hex');
const manifest = [];
const server = createServer(async (request, response) => {
  try {
    if (request.url !== '/capture' || request.method !== 'POST' || request.headers.authorization !== `Bearer ${screenshotToken}`) { response.writeHead(403).end('Forbidden'); return; }
    let body = ''; for await (const chunk of request) { body += chunk; if (body.length > 1024) throw new Error('Request too large.'); }
    const {name} = JSON.parse(body);
    if (!/^[a-zA-Z0-9_-]+$/.test(name)) throw new Error('Invalid screenshot label.');
    const foreground = run(['shell', 'dumpsys', 'activity', 'activities']);
    if (!foreground.split(/\r?\n/).some(line => /(?:mResumedActivity|topResumedActivity)/.test(line) && line.includes('com.qe190010.recipe_box'))) throw new Error('RecipeBox is not in the foreground.');
    const png = run(['exec-out', 'screencap', '-p'], true);
    if (png.subarray(0, 8).toString('hex') !== '89504e470d0a1a0a') throw new Error('Invalid device screenshot.');
    await writeFile(path.join(output, `${name}.png`), png);
    manifest.push({name, file: `${name}.png`, source: 'Physical Android phone / adb exec-out screencap -p', serial: deviceId, capturedAt: new Date().toISOString(), sha256: createHash('sha256').update(png).digest('hex')});
    await writeFile(path.join(output, 'manifest.json'), JSON.stringify(manifest, null, 2));
    console.log(`PHONE_CAPTURE ${name}`);
    response.writeHead(200, {'Content-Type': 'application/json'}).end('{"captured":true}');
  } catch (error) { response.writeHead(500).end(error.message); }
});
await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
const port = server.address().port;
run(['reverse', `tcp:${port}`, `tcp:${port}`]);
const runId = new Date().toISOString().replace(/\D/g, '').slice(0, 14);
const defines = {TEST_EMAIL: `grader.qe190010.${runId}@example.com`, TEST_PASSWORD: `Rb!${randomBytes(12).toString('base64url')}9a`, SECOND_TEST_EMAIL: `fresh.qe190010.${runId}@example.com`, SCREENSHOT_PORT: `${port}`, SCREENSHOT_TOKEN: screenshotToken};
await writeFile('.local/phone-test.json', JSON.stringify(defines, null, 2));
console.log(`Capturing Firebase evidence on phone ${deviceId} for ${defines.TEST_EMAIL}`);
let status;
try {
  const child = spawn('flutter.bat', ['drive', '-d', deviceId, '--driver=test_driver/phone_evidence.dart', '--target=integration_test/phone_evidence_test.dart', '--dart-define-from-file=.local/phone-test.json'], {stdio: 'inherit', shell: true, windowsHide: true, env: {...process.env, PHONE_SCREENSHOT_DIR: output}});
  status = await new Promise((resolve, reject) => { child.once('error', reject); child.once('close', resolve); });
} finally {
  run(['reverse', '--remove', `tcp:${port}`]);
  await new Promise(resolve => server.close(resolve));
}
if (status !== 0) throw new Error('Phone evidence run failed; incomplete screenshots are not submission proof.');
console.log(`Evidence saved: ${manifest.length} system screenshots in ${output}. Account credentials stored only in .local/phone-test.json.`);
