# RecipeBox — UI/UX Design Specification

> **Version:** 1.0 · **Platform:** Flutter / Android · **Source:** PRM393 Practical Exam, Fall 2026  
> **Design direction:** Warm Culinary Minimalism · **Status:** Implementation-ready specification  
> **Language rule:** All mandatory screen names, options, labels, success strings, empty-state strings, and validation messages from the exam remain **exactly in English**. Design descriptions in this document are in Vietnamese.

---

## 0. Design principles & exam compliance

**Mục tiêu:** một app lưu công thức nấu ăn cá nhân có cảm giác đáng tin cậy, thân thiện, dễ thao tác bằng một tay, sạch và cao cấp nhưng không quá nhiều chi tiết trang trí. UI không được đánh đổi tính đúng đắn của chức năng.

1. **Clarity first:** Mỗi màn hình có một hành động chính; nội dung dễ đọc, phân cấp rõ ràng.
2. **Consistency:** Dùng chung token và component cho Home, Login, Register, List, Add, Detail/Edit.
3. **Instant feedback:** Bộ lọc, tìm kiếm, favorite và danh sách cập nhật ngay; không thêm nút Apply.
4. **Accessibility:** vùng bấm ≥ 48×48 dp; độ tương phản chữ rõ; không chỉ dùng màu để thể hiện trạng thái.
5. **Exam fidelity:** Không tự ý dịch hay sửa các chuỗi tiếng Anh bắt buộc; chỉ bổ sung microcopy không xung đột.
6. **Data isolation:** Danh sách và Detail chỉ hiển thị dữ liệu của người đã đăng nhập; không render nội dung protected khi auth chưa xác định.

### 0.1 Navigation map

```text
App Launch
  └─ Auth gate (loading, no protected content)
       ├─ Logged out → Home → Login ↔ Register
       └─ Logged in → List
                          ├─ Add Recipe (bottom sheet / dedicated screen)
                          └─ Detail → Edit (same screen)
                                     └─ Delete confirmation → List
Logout → Home
```

**Quan trọng:** Sau Login/Register thành công, dùng navigation replacement/clear auth routes để Android Back từ List không quay lại form. Khi mở app và auth chưa rõ, hiển thị splash/loading trung tính.

---

## 1. Visual identity & branding

### 1.1 Tên thương hiệu

- **Tên hiển thị chính xác:** `RecipeBox` (viết liền, R và B viết hoa).
- **Brand promise (chỉ dùng cho mô tả phụ, không thay chuỗi bắt buộc):** “Your recipes, beautifully organized.”
- **Cá tính:** ấm áp, tối giản, gọn gàng, có chút cảm hứng ẩm thực; tránh minh họa quá trẻ con hoặc phong cách neon.

### 1.2 Logo chính — `logo_primary`

**Concept:** chiếc hộp công thức cách điệu kết hợp tờ recipe card và chiếc lá nhỏ. Nhìn rõ ở kích thước 24 dp, không phụ thuộc vào chữ nhỏ.

| Thành phần | Đặc tả chính xác |
|---|---|
| Symbol container | Hình vuông bo góc 14 dp, 48×48 dp ở header; nền `#2F6B4F` |
| Recipe card | Hình chữ nhật 24×27 dp, bo 4 dp, màu `#FFFFFF`, nằm giữa và lệch xuống 1 dp |
| Card detail | Hai đường ngang 11×2 dp, bo đầu tròn, màu `#2F6B4F`, cách nhau 5 dp |
| Leaf accent | Lá hình elip nghiêng khoảng −35°, 10×6 dp, màu `#F6B65B`, góc trên phải của card |
| Wordmark | Chữ `RecipeBox`, font **Manrope Bold 700**, 22 sp, tracking −0.5, màu `#203B2B` |
| Spacing | Symbol cách wordmark 10 dp; cả cụm căn giữa theo trục dọc |
| Safe area | Padding trống ít nhất 12% kích thước tổng quanh symbol |

**Biến thể:** `logo_primary` (symbol + wordmark), `logo_symbol` (chỉ biểu tượng), `logo_inverse` (wordmark trắng trên nền xanh đậm), `logo_monochrome` (1 màu cho in/độ tương phản). Không kéo giãn, không thêm drop shadow vào wordmark, không đổi màu riêng lẻ tùy màn hình.

### 1.3 App icon — `app_icon`

- Canvas chuẩn: **1024×1024 px** để xuất asset nguồn; adaptive Android icon dùng foreground/background layers.
- Background: solid `#2F6B4F`; foreground: recipe card trắng, hai đường xanh, leaf vàng ấm.
- Nội dung icon nằm trong vùng an toàn trung tâm khoảng 66–70% canvas; không dùng chữ `RecipeBox` trong app icon.
- Xuất `assets/branding/app_icon.png`, `assets/branding/logo_primary.svg`, `assets/branding/logo_symbol.svg` (hoặc dựng bằng Flutter `CustomPainter`/vector).
- Splash: nền `#FAF8F3`, logo_symbol 76 dp, progress indicator 20 dp dưới logo cách 24 dp; **không render List trước khi auth resolved**.

### 1.4 Logo usage / do & don't

**Do:** dùng logo 40–48 dp ở app bar/Home, logo 64–72 dp trên Login/Register, luôn giữ khoảng trống. **Don't:** đè logo lên ảnh rối, đặt lá quá nhỏ, thêm nhiều màu gradient, thay đổi tỷ lệ hoặc dùng icon dao/đầu bếp không liên quan.

---

## 2. Design tokens

### 2.1 Color palette

| Token | Hex | Vai trò |
|---|---|---|
| `brand.primary` | `#2F6B4F` | Primary CTA, selected state, active favorite context |
| `brand.primaryDark` | `#214C38` | Pressed CTA, high emphasis |
| `brand.primaryLight` | `#E8F2EA` | Selected chips, soft icon background |
| `brand.accent` | `#F6B65B` | Leaf/logo accent, favorite star active |
| `surface.canvas` | `#FAF8F3` | Nền toàn app |
| `surface.card` | `#FFFFFF` | Cards, form fields, dialogs |
| `surface.subtle` | `#F3F5F0` | Section surfaces, secondary backgrounds |
| `text.primary` | `#203127` | Heading, body |
| `text.secondary` | `#647267` | Supporting text, labels |
| `text.placeholder` | `#8B968D` | Placeholder text |
| `border.default` | `#DCE5DC` | Borders, dividers |
| `status.success` | `#277A52` | Success icon/text |
| `status.error` | `#B42318` | Field and Firebase error text |
| `status.errorBg` | `#FFF1EF` | Error alert surface |
| `status.warning` | `#A66316` | Medium difficulty badge |
| `overlay.scrim` | `#203127` at 45% | Dialog / sheet backdrop |

**Contrast:** body trên canvas/card dùng `text.primary`; placeholder không thay thế label; trạng thái lỗi luôn có icon + chữ, không chỉ màu. Không dùng vàng accent cho đoạn văn dài.

### 2.2 Typography

- **Primary font:** `Manrope` (nếu không có font asset, fallback `Roboto`, `sans-serif`).
- **Display / Hero:** 32 sp / 40 line height / weight 800 / letter spacing −0.8.
- **Page title:** 26 sp / 34 / 700 / −0.5.
- **Section title:** 20 sp / 28 / 700 / −0.3.
- **Card title:** 17 sp / 24 / 700.
- **Body:** 14 sp / 21 / 400 hoặc 500.
- **Input label:** 13 sp / 18 / 600.
- **Button:** 15 sp / 20 / 700.
- **Caption/metadata:** 12 sp / 17 / 500.
- **Error:** 12 sp / 17 / 500, `status.error`.
- **Stats number:** 22 sp / 28 / 800, tabular numbers.

Hỗ trợ font scaling hệ thống; tránh fixed-height text container khi chữ có thể dài. Tên recipe tối đa 80 ký tự: trong card hiển thị 2 dòng + ellipsis; trong Detail cho phép wrap đầy đủ.

### 2.3 Spacing, shape, elevation

- **Spacing scale (dp):** `4, 8, 12, 16, 20, 24, 32, 40, 48`.
- **Screen horizontal padding:** 20 dp (màn 360–430 dp); 16 dp nếu viewport hẹp dưới 360 dp.
- **Vertical section gap:** 24 dp; gap giữa cards: 12 dp; field gap: 16 dp.
- **Radius:** `xs=8`, `sm=12`, `md=16`, `lg=20`, `xl=28`, `pill=999` dp.
- **Stroke:** 1 dp bình thường, 1.5–2 dp khi focus/error.
- **Shadow card:** `0 4px 16px rgba(32,49,39,.06)`; dialogs `0 16px 40px rgba(32,49,39,.16)`.
- **App bar:** 64 dp nội dung, không tính status bar; bottom safe area theo hệ điều hành.
- **Max content width:** 600 dp cho điện thoại lớn/tablet; căn giữa.

---

## 3. Iconography — quy chuẩn từng icon

**Bộ icon:** Material Symbols Rounded (Flutter Material Icons hoặc SVG tương đương), stroke cảm nhận 1.8–2 dp; icon thông thường 20–24 dp; tap target ≥48 dp. Không trộn icon filled và outline tùy tiện: outline mặc định, filled cho active.

| Tên | Icon đề xuất | Kích thước | Màu / hành vi |
|---|---|---|---|
| App / recipe | `menu_book_rounded` | 24 | Primary; dùng logo riêng cho branding |
| Add | `add_rounded` | 20 | Trắng trong CTA |
| Search | `search_rounded` | 20 | Secondary, leading search field |
| Clear search | `close_rounded` | 18 | Secondary; chỉ hiện khi có query |
| Filter | `tune_rounded` | 20 | Primary, section title |
| Category | `restaurant_menu_rounded` | 18 | Secondary |
| Difficulty | `signal_cellular_alt_rounded` hoặc `speed_rounded` | 18 | Secondary |
| Time | `schedule_rounded` | 18 | Secondary |
| Servings | `groups_rounded` | 18 | Secondary |
| Notes | `notes_rounded` | 18 | Secondary |
| Favorite off | `star_border_rounded` | 24 | `#7A867B` |
| Favorite on | `star_rounded` | 24 | `#F6B65B`, accessible label “Remove from favorites” |
| View details | `chevron_right_rounded` | 22 | Secondary |
| Edit | `edit_outlined` | 20 | Primary |
| Delete | `delete_outline_rounded` | 20 | Error |
| Back | `arrow_back_rounded` | 24 | Primary text |
| Logout | `logout_rounded` | 20 | Primary / secondary CTA |
| Show password | `visibility_outlined` | 20 | Secondary |
| Hide password | `visibility_off_outlined` | 20 | Secondary |
| Success | `check_circle_rounded` | 20 | Success |
| Error | `error_outline_rounded` | 18 | Error |
| Empty state | `inventory_2_outlined` | 64 | Primary Light / Secondary |
| Dropdown | `keyboard_arrow_down_rounded` | 22 | Secondary |

**Accessibility:** icon-only buttons phải có `Tooltip`/`Semantics(label: ...)`; star selected phải phản ánh trạng thái `toggled`/`selected` phù hợp.

---

## 4. Component library — chi tiết đến từng trạng thái

### 4.1 Buttons

| Variant | Size / padding | Background / border | Text / icon | Usage |
|---|---|---|---|---|
| `PrimaryButton` | Height 52 dp, horizontal 20, radius 14 | `brand.primary` | Trắng, 15/700 | Login, Register, Add Recipe, Save |
| `SecondaryButton` | Height 48 dp, radius 14 | `brand.primaryLight`, border none | Primary | Navigation phụ, Cancel |
| `OutlineButton` | Height 48 dp, radius 14 | White, 1 dp `border.default` | Primary | Login/Register ở Home, Clear |
| `TextButton` | Min tap height 48 | Transparent | Primary | Back, inline actions |
| `DangerButton` | Height 48, radius 14 | `status.error` hoặc outline error | Trắng hoặc error | Confirm Delete |
| `IconButton` | 48×48 tap target, visual 20–24 | Transparent/soft | Icon theo trạng thái | Star, eye, close, edit |
| `FilterChip` | Min height 36, padding 12×8, pill | White/selected `primaryLight` | 13/600 | Category, difficulty |

**State matrix:**
- Default: như bảng; focus có ring 2 dp `brand.primary` (offset 2 dp).
- Pressed: primary chuyển `primaryDark`, scale 0.98 tối đa 100 ms; không thay đổi layout.
- Disabled: nền `#E5EAE4`, chữ `#97A198`, không thể nhấn.
- Loading: giữ nguyên chiều rộng và height, spinner 18 dp thay icon/text hoặc đi cùng `Saving...` (chỉ là microcopy, không thay success strings); khóa double-submit.
- Destructive: yêu cầu confirmation; không xóa ngay khi chạm Delete ở Detail.

### 4.2 Text inputs

- **Container:** full width, min height 54 dp, white background, radius 12, 1 dp border `border.default`.
- **Label:** nằm trên input, cách 6 dp, 13 sp semibold; dấu `*` nhỏ cho required, không dùng dấu `*` thay validation.
- **Content:** padding 16 dp horizontal, 14 dp vertical, text 14 sp, cursor primary.
- **Placeholder:** `text.placeholder`, ví dụ `Enter recipe name`, `you@example.com`.
- **Focused:** border 2 dp `brand.primary`, giữ layout bằng border alignment.
- **Invalid:** border 1.5 dp `status.error`; error dưới field cách 5 dp, icon error 14 dp + message 12 sp; chừa không gian bằng AnimatedSize, tránh chồng chéo.
- **Password:** `obscureText: true` mặc định, trailing eye toggle 48 dp; không làm mất input focus.
- **Numeric:** keyboardType number, chỉ chấp nhận số nguyên; vẫn validate string để hiển thị exact errors.
- **Notes:** multiline 4–5 lines, max 300 chars, counter `N/300` ở góc dưới; nếu quá 300 phải cho phép thấy lỗi theo đề (không âm thầm truncate input).
- **Submit:** chưa submit lần đầu thì không hiển thị lỗi; sau lần submit, lỗi từng field tự biến mất ngay khi field đó hợp lệ.

### 4.3 Dropdown / select

- Style cùng text input, height ≥54 dp, trailing chevron 22 dp.
- Category placeholder **`Choose category`**; options theo thứ tự **`Breakfast`, `Lunch`, `Dinner`, `Dessert`**.
- Difficulty placeholder **`Choose difficulty`**; options **`Easy`, `Medium`, `Hard`**.
- Placeholder là lựa chọn rỗng, không tự chọn mặc định.
- Dropdown menu bo 12 dp, white, elevation nhẹ, item height ≥48 dp; menu không bị cắt khỏi viewport.
- Filters sử dụng `All` + các giá trị tương ứng; nên dùng dropdown/chips có trạng thái lựa chọn rõ ràng.

### 4.4 Switch, favorite & search

- `Favorites only`: switch track 48×28 dp, thumb 20 dp, off track `#DCE5DC`, on track `brand.primaryLight`, thumb on `brand.primary`; label `Favorites only` đặt bên trái; toàn row tappable ≥48 dp.
- Favorite star: button 48×48 dp; off outline, on filled vàng; cập nhật ngay trên UI và persist Firestore. Nếu filter Favorites only đang bật, item un-starred biến mất ngay.
- Search: search icon trái, hint `Search recipes...`, clear X bên phải khi có chữ; debounce ngắn tùy chọn (100–200 ms) nhưng hiển thị phản hồi tức thì; trim hai đầu và so khớp case-insensitive trên **name hoặc notes**.

### 4.5 Recipe card

```text
┌────────────────────────────────────────┐
│  Creamy Mushroom Pasta            ☆   │
│  [Dinner]  [Easy]                     │
│  ◷ 25 min                  Details  ›  │
└────────────────────────────────────────┘
```

- Full width; white; radius 18 dp; padding 16 dp; border 1 dp `#E8ECE5`; shadow rất nhẹ.
- Title 17/700, tối đa 2 dòng; star bên phải, không che text; name flex 1.
- Category badge nền `#E8F2EA`, chữ primary; difficulty badge theo độ khó: Easy xanh nhạt, Medium vàng nhạt, Hard hồng nhạt (luôn có chữ).
- Metadata time icon 18 dp + `25 min`, 13/600; entire card mở Detail trừ star button, không double trigger.
- Card gap 12 dp; press state nền `#F7FAF6`; có semantic label đầy đủ.

### 4.6 Stat tile & breakdown

- Stats có 3 tile: `Recipes: N`, `Favorites: N`, `Total time: N min` **hiển thị nguyên văn theo mẫu**, N là số nguyên; không viết `1.0`, không viết `mins`.
- Mobile 360 dp: bố trí 1 cột hoặc 2 tile + 1 full-width để không cắt chữ; ưu tiên 1 cột ngang nhỏ gọn nếu không đủ chỗ.
- Category breakdown: header `By category`, mỗi row tên category bên trái, số lượng bên phải; chỉ hiện category đang có; sort count giảm dần, tie: Breakfast → Lunch → Dinner → Dessert.
- Tất cả thống kê dựa trên **danh sách sau filter/search**, không phải toàn bộ database.

### 4.7 Feedback & dialog

- **Success snackbar:** nền `#E8F2EA`, icon check, text primary, radius 12, padding 14, duration 3 s. Nội dung exact: `Registration successful` / `Recipe added`.
- **Firebase form error:** inline alert **dưới submit button**, nền `status.errorBg`, icon error, text từ Firebase; không thay bằng snackbar và không điều hướng khi lỗi.
- **Delete dialog:** width max 340 dp, radius 20, padding 24; title `Delete recipe?`; body `This action cannot be undone.`; buttons **`Cancel`** (secondary) và **`Delete`** (danger). Chỉ xóa sau confirm.
- **Loading:** spinner primary 24 dp ở auth gate; inline progress trong CTA khi đang submit; giữ layout ổn định.
- **Empty state:** icon 64 dp, heading chính xác **`No recipes found`**, optional explanatory text và CTA phụ `Add a recipe` nếu phù hợp; không thay heading bằng câu khác.

---

## 5. Screen-by-screen specifications

### 5.1 `Home` — public / first screen when logged out

**Structure (top → bottom):** SafeArea → Header logo left + `Login` / `Register` right → hero section → feature cards → optional footer.

- Background canvas; app bar horizontal padding 20 dp, logo symbol 36 dp + wordmark 18 sp.
- Header action `Login` dạng outline compact và `Register` dạng primary compact, tap target 48 dp. Ở màn 320 dp, ưu tiên logo wordmark rút gọn/chỉ symbol, tuyệt đối không tràn ngang.
- Hero margin top 44 dp, title **`RecipeBox`** 32/800; subtitle `Keep the recipes you love, all in one place.` 15/23 secondary.
- Hero decorative illustration: 3 recipe cards xếp chồng, icon leaf; **không dùng ảnh món ăn có bản quyền nếu chưa có quyền**.
- Feature cards (ít nhất 3) gồm: **`Save your recipes`**, **`Sort by cooking time`**, **`Mark your favorites`**. Mỗi card icon 24 dp trong soft square 44 dp, title 16/700, mô tả 13/20, padding 16, gap 12.
- CTA tùy chọn `Get started` → Register; không thay `Login`/`Register` bắt buộc.
- Không hiện email hay Logout khi logged out.

### 5.2 `Login`

```text
← Back                  [logo]
                         Welcome back
                         Sign in to your RecipeBox
Email
[ you@example.com                 ]
Password
[ ••••••••••                  eye ]
[              Login             ]
[ Firebase error below button ]
Don't have an account? Register
```

- Single-column max width 440 dp, padding 24, logo 64 dp, title 26/700, vertical spacing 20–24 dp.
- Required: Email, Password; password obscured. Submit button `Login` full width height 52 dp.
- Validation only after first submit; field errors below corresponding field, then auto-clear when valid.
- Exact errors: Email empty `Email is required`; invalid `Please enter a valid email address`; Password empty `Password is required`.
- Firebase error appears **below Login button**; successful sign-in → List with auth route replacement.
- Text link `Register` → Register; do not add a password minimum length validation to Login unless explicitly required (the exam specifies minimum length for Register only).

### 5.3 `Register`

- Same visual shell as Login; title `Create your account`; fields Email, Password, Confirm password.
- Password and Confirm password masked; both have eye toggle.
- Exact errors: Email empty `Email is required`; invalid `Please enter a valid email address`; Password empty `Password is required`; Password under 6 chars `Password must be at least 6 characters`; Confirm empty `Confirm password is required`; mismatch `Passwords do not match`.
- Submit button `Register`; Firebase errors below button. On success show exact **`Registration successful`**, then transition to protected List (ensure success message is visible long enough to capture screenshot).
- Inline `Already have an account? Login`.

### 5.4 `List` — protected / dashboard

**Top-to-bottom order:** app bar with brand + user email + Logout → title `My Recipes` → Add Recipe CTA → Search → Filters → Summary → Recipe list.

- App bar: logo_symbol 32 dp + `RecipeBox` 18 sp left; email secondary 12 sp, ellipsis when long; `Logout` action 48 dp. Nếu chật, email đặt thành dòng riêng ngay dưới header; không truncate Logout.
- Page title `My Recipes` 26/700; `Add Recipe` primary CTA full width hoặc button right khi đủ không gian.
- Search full width, height 52 dp, margin bottom 12 dp.
- Filters card white radius 18, padding 16; category `All` + 4 options, difficulty `All` + 3 options, `Favorites only` switch, `Clear` button. Có thể bố trí 2 dropdown xếp dọc ở điện thoại hẹp.
- Summary: 3 exact text values, breakdown; margin top 20 dp.
- List: card gap 12 dp; sort by cookTime ascending, tie by case-insensitive name; no horizontal scrolling.
- Star toggles and card taps are distinct. List immediately reflects Firestore updates and filter interactions.
- Khi không có recipes phù hợp: hiển thị exact `No recipes found`; vẫn giữ filters và summary (zero counts).
- Android Back không đưa người dùng về Login/Register; dùng root protected route.

### 5.5 `Add Recipe` — form

**Presentation recommendation:** dedicated screen `Add Recipe` (dễ chụp screenshot, xử lý keyboard), không bắt buộc bottom sheet. App bar Back + title; scrollable form + bottom sticky CTA nếu không che keyboard.

| Field label | UI | Placeholder/default | Constraints |
|---|---|---|---|
| Name | Text input | `Enter recipe name` | Required, trim, ≤80 chars |
| Category | Dropdown | `Choose category` (empty) | Breakfast/Lunch/Dinner/Dessert |
| Difficulty | Dropdown | `Choose difficulty` (empty) | Easy/Medium/Hard |
| Cook time | Numeric input | `Minutes` | Whole integer 1–600 |
| Servings | Numeric input | `Optional` / empty | If filled, whole integer 1–20 |
| Notes | Multiline textarea | `Add a note (optional)` / empty | ≤300 chars |

- Form width max 560 dp, horizontal padding 20 dp; 16 dp between fields, 24 dp before submit.
- Submit button `Add Recipe` height 52 dp, full width; `Cancel` optional text action.
- Exact errors: `Name is required`, `Name must be at most 80 characters`, `Please choose a category`, `Please choose a difficulty`, `Cook time is required`, `Cook time must be a whole number from 1 to 600`, `Servings must be a whole number from 1 to 20`, `Notes must be at most 300 characters`.
- Initial form shows **no errors**; validate on submit; auto-clear each error once valid.
- On success: Firestore write, reset form, show **`Recipe added`**, new recipe appears immediately in sorted List. UI strategy: return to List after success with snackbar visible (screenshot captures recipe + success), or embed Add form inline on List; choose one and keep consistent.
- On duplicate name or other Firestore rejection: show server error **on form** and do not add item to List. Không coi client-side duplicate check là thay thế database enforcement.

### 5.6 `Detail` — view mode

- App bar Back + `Recipe details`; action `Edit` and `Delete` (Delete icon error, accessible label).
- Hero white card radius 20 padding 20: full recipe name 24/700, category/difficulty badges, favorite star 48 dp top-right.
- Detail rows with leading icons: `Category`, `Difficulty`, `Cook time`, `Servings`, `Notes` (read-only). Time display e.g. `25 min`; optional fields empty display `Not specified` (presentation only; stored values still default empty).
- Notes may wrap to multiple lines; allow vertical scrolling; no horizontal overflow.
- Favorite toggle persists immediately. Detail remains consistent with List after returning.

### 5.7 `Detail` — edit mode

- Tapping `Edit` replaces read-only rows with same form components as Add; prefill current data; no validation errors before first Save attempt.
- Bottom action row `Cancel` (secondary) + `Save` (primary), each at least 48 dp; on narrow screen stack vertically to avoid clipping.
- **Reuse exactly Add Recipe validation rules/messages**. Save writes Firestore, returns to Detail view mode with latest values; List immediately updates, including changed sort position.
- Cancel discards unsaved edits and returns to view mode. While saving, disable repeated submits.

### 5.8 Delete confirmation

- Trigger from Detail action `Delete`; modal with title `Delete recipe?`, explanatory copy, buttons exact **`Cancel`** and **`Delete`**.
- `Cancel` closes dialog, keeps recipe. `Delete` calls Firestore; after success navigate to List and remove card immediately. If deletion fails, show error and remain in Detail; never fake successful deletion.

### 5.9 Loading, errors, empty, offline

- **Auth resolving:** neutral splash spinner; do not flash List or Home before Firebase auth state is resolved.
- **Firestore loading:** skeleton cards (3 items, radius 18, no sensitive placeholder data) or centered spinner.
- **No results:** exact `No recipes found` with subtle illustration and optional helper copy.
- **Network error:** inline retry banner `Unable to load recipes. Try again.` (supplemental copy); preserve previously loaded data where safe, never claim a write succeeded when rejected.
- **Offline/pending writes:** avoid showing false success; if optimistic UI is used, revert on rejected write and display error.

---

## 6. Responsive layout & motion

| Viewport | Layout |
|---|---|
| 320–359 dp | 16 dp gutters; stacked controls; title wraps; no side-by-side long CTA |
| 360–430 dp | 20 dp gutters; single-column forms; two filters stacked |
| 431–600 dp | 24 dp gutters; optional two-column stat tiles if text fits |
| >600 dp | Center max-width 600 dp; maintain phone-like information density |

- Wrap all forms in `SingleChildScrollView` / safe area; account for keyboard via `resizeToAvoidBottomInset` and bottom padding.
- Respect system font scale and Android navigation bar inset.
- Animations: button 100–140 ms, card state 150 ms, filter list fade 150–200 ms, dialog 180–220 ms; use easeOutCubic. Support reduced motion.
- No elaborate transitions that delay immediate filter results or Firestore feedback.

---

## 7. Content inventory — exact strings that MUST NOT change

### 7.1 Routes / screens

`Home`, `Register`, `Login`, `List`, `Detail` — preserve these conceptual screen names in app implementation and screenshot captions.

### 7.2 Fixed visible content

- App name: `RecipeBox`.
- Home header buttons: `Login`, `Register`.
- Login/Register success: `Registration successful`.
- List header action: `Logout`.
- Category options: `Breakfast`, `Lunch`, `Dinner`, `Dessert`.
- Difficulty options: `Easy`, `Medium`, `Hard`.
- Add dropdown placeholders: `Choose category`, `Choose difficulty`.
- Add success: `Recipe added`.
- Empty state: `No recipes found`.
- Summary patterns: `Recipes: N`, `Favorites: N`, `Total time: N min`.
- Delete confirmation actions: `Cancel`, `Delete`.
- Edit actions: `Save`, `Cancel`.
- Filter reset: `Clear`.

### 7.3 Exact validation messages

| Form | Condition | Exact message |
|---|---|---|
| Login/Register | Email empty | `Email is required` |
| Login/Register | Email invalid | `Please enter a valid email address` |
| Login/Register | Password empty | `Password is required` |
| Register | Password <6 chars | `Password must be at least 6 characters` |
| Register | Confirm empty | `Confirm password is required` |
| Register | Confirm mismatch | `Passwords do not match` |
| Add/Edit | Name empty or spaces | `Name is required` |
| Add/Edit | Name >80 chars | `Name must be at most 80 characters` |
| Add/Edit | Category empty | `Please choose a category` |
| Add/Edit | Difficulty empty | `Please choose a difficulty` |
| Add/Edit | Cook time empty | `Cook time is required` |
| Add/Edit | Cook time invalid | `Cook time must be a whole number from 1 to 600` |
| Add/Edit | Servings invalid | `Servings must be a whole number from 1 to 20` |
| Add/Edit | Notes >300 chars | `Notes must be at most 300 characters` |

**Implementation rule:** tập trung các chuỗi trên vào constants, không viết lại rải rác ở widget. Không dùng thông báo lỗi thay thế như `Invalid name`.

---

## 8. Flutter architecture & UI handoff

### 8.1 Suggested folder structure

```text
lib/
  main.dart
  app.dart
  core/
    theme/
      app_colors.dart
      app_typography.dart
      app_spacing.dart
      app_theme.dart
    constants/
      ui_strings.dart
      recipe_options.dart
    widgets/
      app_logo.dart
      app_button.dart
      app_text_field.dart
      app_dropdown.dart
      recipe_card.dart
      favorite_button.dart
      stat_tile.dart
      error_banner.dart
      empty_state.dart
      confirmation_dialog.dart
  features/
    auth/
      home_screen.dart
      login_screen.dart
      register_screen.dart
      auth_gate.dart
    recipes/
      recipe_list_screen.dart
      add_recipe_screen.dart
      recipe_detail_screen.dart
      recipe_form.dart
      recipe_filters.dart
      recipe_summary.dart
      recipe_model.dart
      recipe_repository.dart
assets/
  branding/
    logo_primary.svg
    logo_symbol.svg
    app_icon.png
  fonts/
    Manrope-*.ttf
firestore.rules
```

**Note:** cấu trúc trên là gợi ý thiết kế, không phải yêu cầu cứng của đề. Có thể chọn Riverpod/Provider/BLoC tùy triển khai, nhưng phải giữ behavior.

### 8.2 Theme API (illustrative)

```dart
class AppColors {
  static const primary = Color(0xFF2F6B4F);
  static const primaryDark = Color(0xFF214C38);
  static const canvas = Color(0xFFFAF8F3);
  static const textPrimary = Color(0xFF203127);
  static const error = Color(0xFFB42318);
  static const accent = Color(0xFFF6B65B);
}

final theme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: AppColors.canvas,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    surface: Colors.white,
  ),
  fontFamily: 'Manrope',
);
```

### 8.3 Firestore data contract (source-required)

Collection: **`recipes`**, one document per recipe. Required field names (case-sensitive):

| Field | Recommended type | Constraints |
|---|---|---|
| `id` | String | Exactly Firestore document ID |
| `userId` | String | Current Firebase Auth UID |
| `name` | String | Trimmed nonblank, ≤80 chars |
| `category` | String | One of four exact values |
| `difficulty` | String | One of three exact values |
| `cookTime` | int | 1–600 |
| `servings` | int or absent/null | Optional, if present 1–20 |
| `favorite` | bool | Default false |
| `notes` | String | Default empty, ≤300 chars |
| `createdAt` | Timestamp | When added |

**Security and uniqueness are backend requirements, not visual design details:** user can only CRUD own records; anonymous access denied; invalid writes rejected by Firestore rules; same-user duplicate names case-insensitively rejected, even if written directly to Firestore. **Important engineering caveat:** Firestore Security Rules alone cannot query all documents to establish arbitrary case-insensitive uniqueness. Design an enforceable document-ID/normalized-key scheme (or an authorized server-side mechanism) consistent with the exam's **single `recipes` collection** constraint; verify direct Firestore writes from the grader. Do not claim that UI-only checks solve it.

### 8.4 Data presentation logic

```text
visibleRecipes = allOwnedRecipes
  .where(category == All || category matches)
  .where(difficulty == All || difficulty matches)
  .where(!favoritesOnly || favorite == true)
  .where(lower(name or notes) contains lower(trim(search)))
  .sort(cookTime ASC, lower(name) ASC)

summary.recipes = visibleRecipes.length
summary.favorites = visibleRecipes.where(favorite).length
summary.totalTime = sum(visibleRecipes.cookTime)
summary.categories = groupByCategory(visibleRecipes)
  .sort(count DESC, Breakfast/Lunch/Dinner/Dessert tie-break)
```

UI must recompute when query, filters, favorites, recipe edit, add or delete changes. `Clear` resets all 4 controls: category `All`, difficulty `All`, favoritesOnly `false`, search `''`.

---

## 9. Screenshot/report plan — align with grader

> Screenshots phải lấy từ **app thực tế trên emulator/device**, không dùng mockup/Figma/rendered designs làm bằng chứng. Caption đặt trong `<StudentCode>.docx`.

1. Firebase Authentication — Users list showing test account.
2. Firebase Firestore — `recipes` with ≥3 sample documents.
3. Firebase Firestore — published Security Rules.
4. Register screen — validation (submit empty).
5. Register screen — success (`Registration successful`).
6. Login screen — empty form.
7. List screen — after login (email, Logout, ≥3 recipes).
8. Add Recipe form — validation.
9. Add Recipe form — success (`Recipe added`, new card visible).
10. Filters and search — category filter, difficulty filter, favorites-only switch, search (one per control or one plus clear explanatory note).
11. Summary — Recipes/Favorites/Total time + multiple category rows.
12. Detail screen — view mode (all fields).
13. Detail screen — edit validation.
14. Detail screen — after Save.
15. Favorite toggle — before/after.
16. Delete — before/after showing removal.
17. Empty state — `No recipes found` (fresh test account is easiest).

**Presentation tip:** Android emulator 393×852 dp, consistent font scale 1.0, status bar visible, screenshots in chronological order, caption immediately under each screenshot. Đây là gợi ý kích thước để trình bày, không phải yêu cầu từ đề.

---

## 10. QA acceptance checklist

### Visual QA

- [ ] Logo readable at 32, 48, 72 dp; app icon safe zone correct.
- [ ] All buttons ≥48 dp hit target, no clipping at 320 dp width.
- [ ] No horizontal scrolling; long email/name wraps or ellipsizes gracefully.
- [ ] Same field styles across Login/Register/Add/Edit.
- [ ] Keyboard does not cover focused fields or CTA.
- [ ] Error text appears under its own field only after submit.
- [ ] Focus, pressed, disabled, loading, success, error states distinguishable.
- [ ] Contrast and semantics checked for icons and switches.

### Functional QA

- [ ] Home first when logged out; List first when logged in; no protected flash.
- [ ] Register and Login authenticate with Firebase, errors below submit.
- [ ] Back from List never returns to Login/Register.
- [ ] Add/Edit validate exact messages and write to Firestore.
- [ ] Same-user duplicate names case-insensitively rejected by backend.
- [ ] List sort cookTime ASC, name case-insensitive tie-break.
- [ ] Favorite updates immediately and persists after restart.
- [ ] All four filters combine; Clear resets all; summary reflects visible list.
- [ ] Detail edit/save/delete reflect in List without reload.
- [ ] Different accounts cannot read/write each other's recipes.
- [ ] Empty state exact `No recipes found`.
- [ ] `firestore.rules`, Firebase client config and submission files match exam requirements.

---

## 11. Ready-to-use AI coding brief

> Build a production-quality Flutter Android app called RecipeBox using this document as the UI/UX source of truth and the PRM393 Fall 2026 practical exam as the functional source of truth. Implement reusable Material 3 widgets, responsive layouts, Manrope typography, the exact design tokens, logo, iconography, buttons, forms, recipe cards, filter controls, summary and dialogs specified here. Preserve all exact English labels, success strings and validation messages. Use Firebase Authentication (email/password) and Firestore `recipes` with strict user isolation, server-side validation and case-insensitive same-user name uniqueness. Do not render protected content before auth resolves. Update recipes, favorites, search, filters and summary immediately. Do not omit functionality for visual polish. Ensure screenshots for every exam feature can be captured from a real Android emulator. When implementation constraints conflict, prioritize the exam's explicit requirements over optional visual suggestions.

---

**End of specification.**  
**Source:** User-provided PRM393 Practical Exam, Fall 2026. Design choices (palette, logo, spacing, animations, supplementary microcopy, component structure) are proposed design decisions, not claims from the exam.
