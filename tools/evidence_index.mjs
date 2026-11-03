import {readFile, writeFile} from 'node:fs/promises';
const folder = process.env.PHONE_SCREENSHOT_DIR || 'artifacts/phone';
const records = JSON.parse(await readFile(`${folder}/manifest.json`, 'utf8')).map(record => ({...record, name: record.name || record.label}));
const result = JSON.parse(await readFile(`${folder}/result.json`, 'utf8'));
const device = JSON.parse(await readFile(`${folder}/device.json`, 'utf8'));
const captions = {
  '00_home': 'Home — public screen',
  '04_register_validation': 'Register screen — validation',
  '04b_register_confirm_validation': 'Register screen — confirm password validation',
  '05_register_success': 'Register screen — success: Registration successful',
  '06_login': 'Login screen — empty form',
  '07_list_after_login_header': 'List screen — after login: email and Logout',
  '07b_list_after_login_recipes': 'List screen — after login: saved recipes',
  '08_add_validation': 'Add Recipe form — validation',
  '08b_add_time_validation': 'Add Recipe form — cook time validation',
  '09_add_success': 'Add Recipe form — success: Recipe added',
  '10_category_filter': 'Filters and search — category',
  '10b_difficulty_filter': 'Filters and search — difficulty',
  '10c_favorites_filter': 'Filters and search — Favorites only',
  '10d_search_filter': 'Filters and search — search by notes, trimmed and case-insensitive',
  '11_summary': 'Summary — Recipes, Favorites and Total time',
  '11b_category_breakdown': 'Summary — category breakdown',
  '12_detail_view': 'Detail screen — view mode',
  '13_edit_validation': 'Detail screen — edit mode, validation',
  '14_detail_after_save': 'Detail screen — after Save',
  '15_favorite_before': 'Favorite toggle — before',
  '15b_favorite_after': 'Favorite toggle — after',
  '15c_delete_before': 'Delete — before',
  '15d_delete_confirmation': 'Delete — confirmation dialog',
  '15e_delete_after': 'Delete — after: recipe removed from List',
  '16_empty_state': 'Empty state — No recipes found',
  '16b_second_account_empty': 'Empty state — separate account cannot see the first account’s recipes',
  '17_final_collection': 'List — primary account restored with persisted changes',
  '18_release_after_reopen': 'Release APK — launched on the physical phone',
  '19_release_signed_in': 'Release APK — signed in with the grader account',
  '20_release_persistence': 'Release APK — login and 4 recipes persist after a cold restart',
};
if (!Object.keys(captions).filter(name => !name.startsWith('18_') && !name.startsWith('19_') && !name.startsWith('20_')).every(name => records.some(record => record.name === name)) || !result.primaryEmail || result.recipesRemaining !== 4) throw new Error('The evidence run has not completed successfully.');
const selected = records.filter(record => captions[record.name]);
const lines = [
  '# RecipeBox — ảnh minh chứng trên điện thoại thật', '',
  'Sinh viên: Trần Nguyễn Bảo Long — QE190010.', '',
  `Thiết bị: ${device.model}, Android ${device.androidVersion}. Firebase project: ${result.projectId}.`, '',
  `Tài khoản kiểm thử: ${result.primaryEmail}. Còn ${result.recipesRemaining} công thức sau bài kiểm tra xóa. Mật khẩu lưu trong file cục bộ .local/phone-test.json ở thư mục gốc dự án.`, '',
  'Ảnh được chụp tự động bằng lệnh hệ thống ADB trên điện thoại đang chạy ứng dụng và đăng nhập Firebase thật. Manifest ghi thời điểm chụp và SHA-256 của từng ảnh. Không dùng ảnh demo hoặc widget render.', '',
  '| Ảnh | Caption để dùng trong báo cáo |', '| --- | --- |',
  ...selected.map(record => `| [${record.name}](${record.file}) | ${captions[record.name]} |`), '',
  'Còn cần chụp 3 ảnh Firebase console: Authentication Users, Firestore data và Rules đã publish. Các ảnh này chưa được tạo và không được thay thế bằng ảnh giả.', '',
];
await writeFile(`${folder}/README.md`, lines.join('\n'));
console.log(`Indexed ${selected.length} actual phone screenshots, including the release checks.`);
