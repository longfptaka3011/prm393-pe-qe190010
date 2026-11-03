import {spawnSync} from 'node:child_process';
import {readFile, writeFile, stat} from 'node:fs/promises';

const owner = 'longfptaka3011';
const repo = 'prm393-pe-qe190010';
const mode = process.argv[2] || 'status';
const credential = spawnSync('git', ['credential', 'fill'], {input: 'protocol=https\nhost=github.com\npath=longfptaka3011/prm393-pe-qe190010.git\n\n', encoding: 'utf8', windowsHide: true});
if (credential.status !== 0) throw new Error('GitHub credentials are unavailable. Sign in using Git Credential Manager.');
const fields = Object.fromEntries(credential.stdout.trim().split(/\r?\n/).map(line => {const i = line.indexOf('=');return [line.slice(0,i), line.slice(i+1)];}));
if (!fields.password) throw new Error('GitHub did not return a usable credential.');
async function api(url, method = 'GET', body, binary = false) {
  const response = await fetch(url.startsWith('https://') ? url : `https://api.github.com${url}`, {method, headers: {Authorization: `Bearer ${fields.password}`, Accept: 'application/vnd.github+json', 'X-GitHub-Api-Version': '2022-11-28', ...(body ? {'Content-Type': binary ? 'application/vnd.android.package-archive' : 'application/json'} : {})}, ...(body ? {body: binary ? body : JSON.stringify(body)} : {})});
  const result = await response.json();
  if (!response.ok) throw new Error(`GitHub ${response.status}: ${result.message || 'Request failed'}`);
  return result;
}
const repository = await api(`/repos/${owner}/${repo}`);
console.log(JSON.stringify({repository: repository.html_url, private: repository.private, canPush: repository.permissions?.push, defaultBranch: repository.default_branch}));
if (mode === 'status') process.exit(0);
if (repository.private) throw new Error('The submission repository must be public; visibility has not been changed.');
if (mode === 'release') {
  const tag = 'v1.0.0';
  let release;
  const existing = await api(`/repos/${owner}/${repo}/releases`);
  release = existing.find(item => item.tag_name === tag);
  if (!release) release = await api(`/repos/${owner}/${repo}/releases`, 'POST', {tag_name: tag, target_commitish: 'main', name: 'RecipeBox 1.0.0 QE190010', body: 'RecipeBox Android release for PRM393. Student: Trần Nguyễn Bảo Long (QE190010). Firebase Authentication, private Firestore recipes, validation, filters, favorites and summary. Verified on a physical Android 15 phone.', draft: false, prerelease: false});
  const name = 'app-release.apk';
  let asset = release.assets.find(item => item.name === name);
  if (!asset) {
    const apkPath = 'build/app/outputs/flutter-apk/app-release.apk';
    if ((await stat(apkPath)).size < 1000000) throw new Error('APK appears incomplete.');
    asset = await api(`${release.upload_url.split('{')[0]}?name=${name}`, 'POST', await readFile(apkPath), true);
  }
  const metadata = {releaseUrl: release.html_url, apkUrl: asset.browser_download_url, assetId: asset.id, size: asset.size, tag};
  await writeFile('artifacts/release.json', JSON.stringify(metadata, null, 2));
  console.log(JSON.stringify(metadata));
} else throw new Error('Unknown mode. Use status or release.');
