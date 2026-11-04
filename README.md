# OniRoai v1.3 — Headshot 250 HP, ESP và Aim Đầu

Mã nguồn trò chơi Godot 4.5.1, sử dụng asset và pipeline APK Android của phiên bản 1.2.

## Đã thay đổi
- Bỏ hẳn phần vẽ **thanh máu phía trên đầu NPC**; thanh máu của người chơi ở HUD giữ nguyên.
- Địch và người chơi vẫn có 500 HP. **Người chơi bắn trúng thân: -10 HP; bắn trúng đầu: -250 HP**. NPC bắn người chơi vẫn -10 HP. Hai headshot sẽ hạ NPC đầy máu nếu đạn thực sự trúng.
- **ESP ĐỊCH** trong bong bóng MinhQuan là công tắc hoạt động thật: khung góc, tâm đầu, tên, khoảng cách. Xanh lá khi có đường ngắm trực tiếp; tím khi sau vật cản. Không hiển thị khi ở lobby, tạm dừng hoặc NPC chết.
- **AIM ĐẦU** là công tắc hoạt động thật: khi người chơi nhấn **Ngắm** hoặc **Bắn**, camera mượt mà kéo về đầu NPC gần tâm ngắm nhất, trong góc 28°, tối đa 65m và **chỉ khi có đường bắn không bị cản**. Không tự bắn và không bắn xuyên tường.
- Hai tùy chọn mặc định **TẮT**, được lưu vào `user://settings.cfg` nên bật rồi sẽ nhớ.
- Menu được thiết kế lại, có trạng thái công tắc BẬT/TẮT thực.
- Sửa thông báo, menu và hướng dẫn về sát thương đầu/thân. Giữ màn hình loading / key và các điều khiển cũ.

## Cách chơi
1. Nhập key MinhQuan như cũ và mở trận.
2. Chạm bong bóng avatar bên phải màn hình, bật **ESP ĐỊCH** và/hoặc **AIM ĐẦU**, đóng menu.
3. Ngắm hoặc bắn khi NPC xuất hiện gần tâm màn hình để Aim đầu hỗ trợ khóa vào phần đầu.

## Build APK qua GitHub Actions
Workflow `.github/workflows/android-build.yml` vẫn build trên Godot 4.5.1. Sau khi đẩy mã nguồn lên GitHub, mở tab Actions và tải artifact APK.

**Kiểm thử:** Đã rà mã nguồn và đóng gói ZIP. Chưa chạy engine Godot để import/export APK hay kiểm thử trên thiết bị Android trong phiên này.
