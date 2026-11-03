# RecipeBox

Ứng dụng Flutter/Android cho PRM393 của **Trần Nguyễn Bảo Long — QE190010**. Giao diện sử dụng tông xanh lá, nền kem và các thông báo tiếng Anh đúng đề.

Repository: https://github.com/longfptaka3011/prm393-pe-qe190010

APK release: https://github.com/longfptaka3011/prm393-pe-qe190010/releases/download/v1.0.0/app-release.apk

## Chạy ngay

```powershell
flutter pub get
flutter run
```

Khi chưa cấu hình Firebase, Home vẫn hoạt động. Chọn **Explore demo** để thử danh sách mẫu, thêm/sửa/xóa, favorite, bộ lọc và thống kê. Demo chỉ giữ dữ liệu trong bộ nhớ cho đến khi thoát; không tạo tài khoản thật và không phải bằng chứng Firebase cho bài nộp.

## Kết nối Firebase thật

Dự án hiện đã kết nối Firebase **recipebox-qe190010-20261103** (Firestore Standard, Singapore, gói miễn phí). Email/Password đã bật và `firestore.rules` đã publish. File `assets/firebase_config.json` và `android/app/google-services.json` chứa cấu hình client của đúng Android app RecipeBox.

1. Tạo Firebase project và thêm Android app với package `com.qe190010.recipe_box`.
2. Bật **Authentication → Sign-in method → Email/Password**.
3. Tạo **Cloud Firestore**. Publish nội dung `firestore.rules` trong Rules tab, hoặc dùng Firebase CLI:

   ```powershell
   firebase login
   firebase deploy --only firestore --project YOUR_PROJECT_ID
   ```

4. Điền **cấu hình client Android** vào `assets/firebase_config.json`, theo `assets/firebase_config.example.json`. Các giá trị lấy từ Firebase project settings / cấu hình FlutterFire của Android. Không dùng appId của Web.

   Nếu có `google-services.json`, ánh xạ như sau:

   | Khóa trong JSON của ứng dụng | Giá trị trong google-services.json |
   | --- | --- |
   | `apiKey` | `client[Android app tương ứng].api_key[0].current_key` |
   | `appId` | `client[Android app tương ứng].client_info.mobilesdk_app_id` |
   | `messagingSenderId` | `project_info.project_number` |
   | `projectId` | `project_info.project_id` |
   | `storageBucket` | `project_info.storage_bucket` (tùy chọn) |

5. Dừng app và chạy lại. Firebase được khởi tạo bằng `FirebaseOptions`; không cần thay Gradle hay thêm service-account key. Sau khi có cấu hình, chế độ demo không hiển thị và auth gate mở List cho tài khoản đã đăng nhập.
6. Đăng ký một tài khoản kiểm thử thực và thêm ít nhất 3 công thức cho bài nộp. Tạo thêm tài khoản thứ hai để kiểm tra cách ly dữ liệu.

## Dữ liệu và tên duy nhất

Chỉ sử dụng collection `recipes`. Mỗi document gồm `id`, `userId`, `name`, `category`, `difficulty`, `cookTime`, `favorite`, `notes`, `createdAt`; `servings` bị bỏ qua khi để trống (không lưu `null`).

**Document ID là hợp đồng bắt buộc, kể cả khi ghi trực tiếp để chấm bài:**

```text
id = userId + '_' + hex(UTF8(trim(name).toLowerCase()))
```

Ví dụ tên `Pho Bo` có phần tên trong ID là `70686f20626f`. Rules tự tính lại ID, nên một người không thể tạo hai document có tên chỉ khác hoa/thường, kể cả dùng random ID. Hai người khác nhau có thể dùng cùng tên. Hex cũng hỗ trợ dấu tiếng Việt và ký tự `/` mà không tạo path mới. Tên được lưu sau khi trim; khi ghi trực tiếp cần trim trước.

Thao tác Add dùng transaction: đọc target, từ chối nếu đã tồn tại, sau đó tạo document. Đổi tên thay đổi ID, vì vậy Edit dùng transaction tạo target mới và xóa document cũ một cách nguyên tử; nếu trùng tên thì không thay đổi document cũ. Cập nhật cùng ID vẫn được phép cho Edit/favorite; ghi `set` vào chính document hiện hữu là cập nhật document đó, không tạo bản sao. Không dùng kiểm tra UI để thay thế Rules.

Truy vấn duy nhất phía server là `where('userId', isEqualTo: uid)`. Lọc và sắp xếp trên dữ liệu của chính người dùng ở client nên không cần composite index. Summary được tính trên danh sách sau tất cả bộ lọc.

## Kiểm thử

```powershell
flutter analyze
flutter test
```

Kiểm thử trực tiếp Firestore Rules, cần Node.js 20+ và Java 21+:

```powershell
npm --prefix rules-tests ci
.\rules-tests\node_modules\.bin\firebase.cmd emulators:exec --only firestore --project demo-recipebox "npm --prefix rules-tests test"
```

Các test bao gồm owner CRUD, cách ly tài khoản, anonymous bị chặn, validation backend, ID tên duy nhất, transaction tạo mới và đổi tên. Không cần tài khoản Firebase thật cho Emulator.

Có thể chạy app với Emulator bằng cấu hình client của project demo và:

```powershell
flutter run --dart-define=FIREBASE_EMULATOR_HOST=10.0.2.2
```

`10.0.2.2` áp dụng cho Android Emulator trên máy phát triển. Thiết bị thật cần IP LAN của máy và mở cổng Auth 9099/Firestore 8080. Manifest debug cho phép HTTP đến Emulator; bản release không bật cleartext.

## Build Android

```powershell
flutter build apk --debug
flutter build apk --release
```

APK debug ở `build/app/outputs/flutter-apk/app-debug.apk`. Bản release hiện dùng debug signing mặc định của Flutter để cài kiểm thử; cần cấu hình keystore riêng khi phát hành chính thức. Chỉ build bản nộp sau khi đã thêm Firebase client config thật.

## Cấu trúc

- `lib/app.dart`: auth gate, flow navigation và vòng đời session.
- `lib/auth/screens.dart`: Home, Login, Register.
- `lib/core.dart`: theme, logo vector, thành phần dùng chung, thông báo và validation.
- `lib/recipes/`: model, repository, List, Add, Detail/Edit, bộ lọc và summary.
- `firestore.rules`: cách ly người dùng, validation backend và ID duy nhất.
- `rules-tests/`: kiểm thử Security Rules với Firebase Emulator.
- `docs/`: thiết kế đầu vào và checklist để hoàn thiện bài nộp.

## Trạng thái

Đã triển khai các luồng giao diện, tạo Firebase project thật, bật Email/Password và publish Rules. Đã chạy thành công trên điện thoại 2201123C (Android 15), chụp 27 ảnh hệ thống ADB và kiểm tra cách ly tài khoản. APK release đã cài lên điện thoại và kiểm tra sau khi đóng hẳn/mở lại: vẫn đăng nhập, 4 recipe, 1 favorite, tổng 97 phút. Xem ảnh và caption trong `artifacts/phone/README.md`.

Quy trình `node tools/phone_evidence.mjs` tự chọn điện thoại duy nhất đang kết nối, đăng ký tài khoản kiểm thử mới, thao tác và chụp ảnh hệ thống bằng ADB (bao gồm thanh trạng thái). Ảnh lưu ở `artifacts/phone/`, thông tin tài khoản kiểm thử lưu cục bộ ở `.local/phone-test.json` và không đưa lên GitHub. Chỉ dùng ảnh khi quy trình hoàn tất thành công. Source đã đẩy lên GitHub public và APK đã đăng trong Release v1.0.0. Source giải nén mới đã build APK thành công với cấu hình Firebase kèm sẵn. Xem `docs/SUBMISSION_CHECKLIST.md` trước khi nộp.

Tài liệu SDK tham khảo: https://firebase.google.com/docs/flutter/setup và https://firebase.google.com/docs/reference/rules/rules.Bytes.
