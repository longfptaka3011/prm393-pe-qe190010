import {createRequire} from 'node:module';
const require = createRequire(import.meta.url);
const {getGlobalDefaultAccount, getAccessToken} = require('../rules-tests/node_modules/firebase-tools/lib/auth.js');
const account = getGlobalDefaultAccount();
if (!account) throw new Error('Sign in with the project-local Firebase CLI first.');
const {readFile} = await import('node:fs/promises');
const project = JSON.parse(await readFile('.firebaserc', 'utf8')).projects.default;
const token = (await getAccessToken(account.tokens.refresh_token, ['https://www.googleapis.com/auth/cloud-platform'])).access_token;
async function api(url, method = 'GET', body) {
  const response = await fetch(url, {method, headers: {Authorization: `Bearer ${token}`, 'Content-Type': 'application/json'}, ...(body ? {body: JSON.stringify(body)} : {})});
  const result = await response.json();
  if (!response.ok) { const error = new Error(`${response.status}: ${result.error?.message || 'Google API error'}`); error.status = response.status; throw error; }
  return result;
}
for (const service of ['identitytoolkit.googleapis.com', 'firestore.googleapis.com', 'firebaserules.googleapis.com']) {
  await api(`https://serviceusage.googleapis.com/v1/projects/${project}/services/${service}:enable`, 'POST', {});
  console.log(`Enabled ${service}`);
}
const endpoint = `https://identitytoolkit.googleapis.com/v2/projects/${project}/config`;
await api(`${endpoint}?updateMask=signIn.email.enabled,signIn.email.passwordRequired`, 'PATCH', {name: `projects/${project}/config`, signIn: {email: {enabled: true, passwordRequired: true}}});
const config = await api(endpoint);
if (!config.signIn?.email?.enabled || !config.signIn?.email?.passwordRequired) throw new Error('Email/password provider was not enabled.');
console.log(`Verified Email/Password enabled for ${project}. No admin/service-account key was created.`);
