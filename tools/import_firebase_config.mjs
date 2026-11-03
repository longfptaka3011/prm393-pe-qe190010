import {readFile, writeFile} from 'node:fs/promises';
const input = process.argv[2] || 'android/app/google-services.json';
const config = JSON.parse(await readFile(input, 'utf8'));
const client = config.client.find(item => item.client_info?.android_client_info?.package_name === 'com.qe190010.recipe_box');
if (!client) throw new Error('The configuration is not registered for com.qe190010.recipe_box.');
const options = {apiKey: client.api_key[0].current_key, appId: client.client_info.mobilesdk_app_id, messagingSenderId: config.project_info.project_number, projectId: config.project_info.project_id, ...(config.project_info.storage_bucket ? {storageBucket: config.project_info.storage_bucket} : {})};
await writeFile('assets/firebase_config.json', JSON.stringify(options, null, 2) + '\n');
console.log(`Configured RecipeBox Android client for ${options.projectId}`);
