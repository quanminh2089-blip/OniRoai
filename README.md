# OniRoai v1.4 — ESP xanh lá toàn thân + khoảng cách NPC

## Đã sửa
- **ESP ĐỊCH**: Khi bật trong menu MinhQuan, cả mẫu nhân vật NPC địch chuyển thành xanh lá phát sáng (không chỉ kẻ khung 2D). Được vẽ qua tường nhờ shader `depth_test_disabled`.
- **Số mét trên đầu NPC**: Label3D theo NPC, quay về camera, chữ xanh viền tối, cập nhật mỗi 0.1 giây, ví dụ `28 m`.
- Khi **TẮT ESP**, khôi phục vật liệu gốc của từng MeshInstance3D; NPC đã chết / chưa vào trận / tạm dừng không có ESP.
- ESP được gắn trực tiếp trên model NPC trong `enemy.gd`, tránh lỗi HUD 2D bị sai kích thước/không vẽ và hỗ trợ NPC tái sinh qua từng ván.
- Menu bật/tắt và nhớ trạng thái như bản v1.3; Aim Đầu, headshot -250 HP, phím điều khiển, màn hình key và toàn bộ map giữ nguyên.

## Kiểm thử
Đã kiểm tra cấu trúc Godot, script tham chiếu và ZIP. Chưa build/chạy trên Android; cần tải artifact từ GitHub Actions và thử trực tiếp.

## Cập nhật qua Termux/GitHub
Giải nén ZIP lên thư mục Git của `OniRoai`, rồi `git add -A`, `git commit -m "OniRoai 1.4 green enemy ESP"`, `git pull --rebase origin main` nếu remote tiến lên (xử lý conflict nếu có), `git push origin main`. **Không dùng `git push --force`.**
