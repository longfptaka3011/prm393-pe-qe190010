# Hoàn thiện bài nộp QE190010

## Thông tin cần bổ sung

- [x] Họ tên: Trần Nguyễn Bảo Long. Mã sinh viên: QE190010.
- [x] Repository được cung cấp: https://github.com/longfptaka3011/prm393-pe-qe190010
- [x] Firebase client Android config trong `assets/firebase_config.json`.
- [x] Firebase project: recipebox-qe190010-20261103.
- [x] Email/Password đã bật, Firestore Standard tại Singapore đã tạo và Rules đã publish.
- [x] Tài khoản kiểm thử thật, đã đăng nhập trong app; còn 4 recipe sau bài kiểm tra xóa. Thông tin đăng nhập nằm trong `.local/phone-test.json` (không commit).
- [x] Kiểm tra account khác không thấy dữ liệu account trước trên điện thoại thật.
- [x] Chụp tự động 27 ảnh hệ thống ADB trên điện thoại 2201123C, Android 15; xem `artifacts/phone/manifest.json`.
- [x] Build và cài bản release; đóng hẳn/mở lại vẫn giữ đăng nhập, 4 recipe, 1 favorite, tổng 97 phút.
- [ ] Repository GitHub public và URL APK release có thể tải công khai.

## Ảnh thật cần chụp, theo thứ tự đề

1. Firebase Authentication: Users và tài khoản kiểm thử.
2. Firestore data: collection recipes với ít nhất 3 document thuộc tài khoản đó.
3. Firestore Rules: Rules đã publish trên console.
4. Register: submit rỗng có validation.
5. Register: Registration successful.
6. Login: form rỗng.
7. List sau đăng nhập: email, Logout và ít nhất 3 recipe.
8. Add Recipe: validation.
9. Add Recipe: Recipe added và recipe mới trong list.
10. Category, difficulty, favorites-only, search thay đổi kết quả.
11. Summary với nhiều category.
12. Detail view với tất cả dữ liệu.
13. Edit validation.
14. Sau Save với giá trị đã cập nhật.
15. Favorite trước/sau; Delete trước/sau.
16. Empty state: No recipes found, dùng tài khoản mới.

Mỗi ảnh cần caption đúng tên màn hình/tính năng. Không dùng ảnh demo, widget test hay mockup làm bằng chứng đăng nhập Firebase thật.

## Đóng gói khi đã có đủ bằng chứng

- `QE190010.docx`: điền mẫu thông tin đúng đề và các ảnh thật có caption.
- `QE190010.zip`: pubspec.yaml tại gốc, pubspec.lock, lib/, android/, assets/, firestore.rules và các file cấu hình cần thiết.
- Loại bỏ build/, .dart_tool/, .git/, node_modules/, log, khóa admin/service-account và keystore riêng.
- Giải nén sang thư mục mới và build lại; thử cài APK từ URL public.

Chưa tạo bộ nộp bài cuối: còn cần ảnh console Authentication/Firestore/Rules, URL APK release công khai và xác minh source đã đẩy lên GitHub. Ảnh app thật đã có trong `artifacts/phone/`.
