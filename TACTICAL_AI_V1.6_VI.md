# OniRoai v1.6.0 — Tactical AI Extreme

## Mục tiêu

Nâng AI đội đỏ (5 NPC) thành đối thủ có phối hợp, đặc biệt khi người chơi bật Aim Head + ESP xanh lá. Không xóa Aim Head / ESP và không thay đổi luật 500 HP, 10 sát thương thân, 250 sát thương đầu.

## Cấu hình

- **500 ms**: phản ứng sau khi NPC **nhìn thấy** người chơi. Mất rồi bắt lại tầm nhìn sẽ khởi động lại phản ứng.
- **70%**: xác suất ngắm tốt danh nghĩa trong `enemy.gd`. Không cam kết đúng 70% số đạn trúng; va chạm và cự ly còn tác động tới tỷ lệ trúng thực tế.
- **100% phối hợp**: toàn đội chia sẻ liên lạc mục tiêu khi một NPC nhìn thấy người chơi hoặc nghe thấy súng trong phạm vi. **Không cho AI nhìn xuyên tường**.
- Chọn độ khó **Extreme** mặc định. Ở lần đầu nâng cấp cấu hình đã lưu, độ khó được đặt Extreme; sau đó người chơi vẫn có thể tự đổi trong cài đặt.

## Nâng cấp mã nguồn

- Chỉ huy: phân công hướng công kích và đổi đội hình mỗi chu kỳ.
- Tiên phong: áp sát, tạo áp lực trực diện.
- Thiện xạ: giữ góc bắn xa, tận dụng vật chắn.
- Đánh vòng: tìm vị trí ở sườn hoặc sau người chơi.
- Hỗ trợ: phân tán đội hình, bắn xen kẽ để đồng đội di chuyển.
- Hệ thống cover chọn ô trống kề các vật chắn có collider, kiểm tra đường đi A*, đường nhìn và vị trí đồng đội.
- Peek: chọn điểm ở rìa cover có đường nhìn thật tới mục tiêu, bắn theo nhịp lệch nhau; khi bắn phải có LOS.
- Cập nhật hitbox khi NPC hạ thấp tư thế, tránh hiệu ứng ngồi hình ảnh nhưng phần va chạm vẫn đứng.
- Khi trúng đạn: nhận biết hướng nguồn bắn có sai số, đổi cover và né hướng di chuyển; nạp đạn vẫn di chuyển tìm chỗ nấp.
- Khi >13 giây không gây/nhận sát thương: đội chuyển từ thủ sang gây sức ép, tránh đứng nấp vô hạn.
- Aim Head / ESP gốc của người chơi vẫn giữ nguyên.

## Kiểm tra 100 ván — mô phỏng, không phải chạy Godot

Lệnh:

```bash
python3 tools/simulate_tactical_ai.py --rounds 100 --seed 4900 --output tools/ai_simulation_100_rounds.json
```

Mô phỏng 2D giả lập vật chắn, đường bắn, 5 NPC, 500 HP, các thông số sát thương, tốc độ bắn, Aim Head + ESP, định hướng di chuyển và phản ứng theo vai trò. Cùng 100 hạt giống ngẫu nhiên được chạy ở v1.5 mô phỏng và v1.6 mô phỏng.

| Chỉ số | AI 1.5 (proxy) | AI 1.6 (proxy) |
| --- | ---: | ---: |
| Người chơi thắng | 100/100 | 47/100 |
| NPC thắng | 0/100 | 53/100 |
| Hòa / quá 90 giây | 0 | 0 |
| Số NPC bị hạ trung bình | 5.00 | 3.93 |
| Thời lượng trung bình | 9.51s | 29.43s |

**Giới hạn quan trọng:** đây là một mô hình 2D rút gọn có giả định (Aim Head định hướng ngay, ESP chỉ cung cấp thông tin, người chơi chủ động đi tìm NPC sau 2.5 giây mất góc nhìn, vật chắn được xấp xỉ bằng các hình chữ nhật). Nó **không chạy GDScript, hình ảnh, hoạt ảnh, mạng A* 3D hay vật lý Godot thật**. Các tỷ lệ thắng không thể coi là tỷ lệ thực tế trong APK. Cần chạy Godot/Android để xác nhận hiệu năng, hoạt ảnh và độ khó.

## Các tệp quan trọng

- `scripts/arena.gd`: liên lạc, chia đội, tìm cover và điểm ló bắn.
- `scripts/enemy.gd`: state, né, crouch collision, nhận biết, bắn.
- `scripts/game_state.gd`: phiên bản / chọn Extreme mặc định.
- `tools/simulate_tactical_ai.py`: mô phỏng có thể chạy lại.
- `tools/ai_simulation_100_rounds.json`: số liệu gốc.

## Cài bằng Termux

Dùng lệnh `bash` trong câu trả lời hoặc chạy `bash tools/update_from_termux.sh` sau khi giải nén và đặt dự án tại đường dẫn mong muốn. Script đồng bộ **chỉ những tệp được chỉnh**, không xóa APK hay patch cũ trong repo GitHub.
