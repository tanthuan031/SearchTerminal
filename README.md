# ⚡️ SearchTerminal for macOS

**SearchTerminal** là ứng dụng cá nhân chạy native trên macOS (viết bằng **Swift** & **SwiftUI**), thiết kế theo phong cách **Spotlight** thanh lịch và siêu nhẹ. 

Ứng dụng giúp bạn tìm nhanh bất kỳ thư mục hoặc file nào trên máy tính, hiển thị rõ ràng đường dẫn và mở ngay vào **Terminal**, **Finder**, hoặc **VS Code** chỉ với một nút bấm hoặc phím tắt.

---

## ✨ Tính Năng Nổi Bật

1. **Giao diện nổi dạng Spotlight (Floating HUD)**:
   - Cửa sổ nổi giữa màn hình với hiệu ứng kính mờ (frosted glass blur) cao cấp của macOS.
   - Bấm phím tắt là xuất hiện ngay lập tức, bấm `Esc` hoặc click ra ngoài là tự động ẩn.
   - Chạy ngầm trên Menu Bar, không làm phiền Dock (`LSUIElement = true`).

2. **Phím tắt toàn hệ thống (Global Hotkey)**:
   - Mặc định: `⌥ + Space` (Option + Space).
   - Có thể đổi trong Cài đặt sang: `⌘ + ⇧ + Space`, `⌥ + P`, hoặc `⌘ + ⇧ + F`.

3. **Cấu hình Thư Mục Cho Phép (Allowed Folders)**:
   - Bạn tự chọn các thư mục muốn tìm kiếm (ví dụ: `~/Projects`, `~/Documents`, `~/Desktop`, `~/Work`,...).
   - Tự động quét đệ quy các thư mục con bên trong theo độ sâu tùy chỉnh (1 đến 10 cấp).
   - Tự động bỏ qua các folder rác/nặng (`.git`, `node_modules`, `Pods`, `DerivedData`, `.build`, `vendor`, `.venv`,...).

4. **Tìm kiếm thông minh & Hỗ trợ tiếng Việt không dấu**:
   - Tốc độ tìm kiếm tức thì `< 1ms` trong bộ nhớ RAM.
   - Hỗ trợ gõ tắt (subsequence) và **tiếng Việt không dấu** (gõ `du an` vẫn tìm ra `Dự Án`).

5. **Hiển thị trực quan**:
   - Hiển thị Icon chuẩn macOS cho từng folder/file.
   - Tên folder/file in đậm nổi bật.
   - **Hiển thị đầy đủ đường dẫn** (ví dụ: `~/Projects/frontend/client/src`) giúp bạn không bị nhầm lẫn giữa các folder trùng tên.

6. **Các Thao Tác Nhanh (Keyboard Shortcuts)**:
   - `↑` / `↓`: Di chuyển chọn folder trong danh sách kết quả.
   - `Enter` (`↩`): **Mở Terminal tại thư mục đó** (`open -a Terminal <path>`).
   - `Cmd + Enter` (`⌘↩`): **Mở và hiển thị trong Finder**.
   - `Cmd + O` (`⌘O`): **Mở thẳng trong Visual Studio Code**.
   - `Cmd + ,` (`⌘,`): Mở cửa sổ Cài đặt (Settings).
   - `Esc`: Đóng thanh tìm kiếm.

---

## 🚀 Cách Cài Đặt và Sử Dụng

### 1. Khởi chạy ứng dụng ngay
Ứng dụng đã được biên dịch sẵn thành file `SearchTerminal.app` trong thư mục này. Bạn chỉ cần chạy lệnh sau hoặc click đúp vào file:
```bash
open SearchTerminal.app
```

### 2. Cài đặt vào hệ thống (Khuyên dùng)
Kéo file `SearchTerminal.app` vào thư mục **Applications** (Ứng dụng) của máy Mac:
```bash
cp -R SearchTerminal.app /Applications/
```

### 3. Tự khởi động cùng macOS (Tùy chọn)
Để mỗi khi bật máy lên là phím tắt có thể dùng được ngay:
1. Mở **System Settings** (Cài đặt hệ thống) trên Mac.
2. Vào **General** > **Login Items** (Mục đăng nhập).
3. Bấm dấu `+` và chọn `SearchTerminal.app`.

---

## ⚙️ Tùy Chỉnh & Cấu Hình

- **Thêm/bớt thư mục tìm kiếm**:
  - Bấm vào icon bánh răng `⚙️` ở góc dưới thanh tìm kiếm, hoặc click chuột phải vào icon Terminal trên thanh Menu Bar của Mac > chọn **Settings...**.
  - Bấm **Add Folder** để chọn thư mục bạn muốn cho phép tìm kiếm.
  - Bấm **Re-index Now** để cập nhật danh sách thư mục mới.
- **Đổi Terminal ưa thích**: Hỗ trợ chọn mở bằng **Terminal.app mặc định**, **iTerm2**, hoặc **Warp**.
- **Tìm cả file**: Bật tùy chọn *"Include individual files in search"* nếu muốn tìm cả file lẻ thay vì chỉ tìm folder.

---

## 🛠️ Biên dịch lại Source Code (Nếu muốn chỉnh sửa thêm)

Mã nguồn được viết 100% bằng Swift gốc, không phụ thuộc thư viện ngoài:
```bash
# Cấp quyền và chạy script build:
./build_app.sh
```
File thực thi và App Bundle sẽ được tự động tạo lại tại `SearchTerminal.app`.

