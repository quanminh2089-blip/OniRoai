# OniRoai — Bộ cứu nguồn và dựng APK từ game gốc

## Có gì trong bộ này?

- `base/MinhQuan-TienDon-offline.apk`: APK **gốc** 0.4.0 còn nguyên, dùng làm nguồn khôi phục gameplay, maps, GDScript đã biên dịch.
- `base/OniRoai-recovered.zip`: 221 tài nguyên cứu được từ ZIP OniRoai bị cắt ngang; bao gồm key panel, avatar, loading và model.
- `patches/scripts/oniroai_gate.gd`, `patches/scenes/oniroai_gate.tscn`: **màn hình key mới**, nhập `FreeKey_MinhQuan` rồi chuyển đến màn hình game cũ, avatar quay trong lúc chuyển cảnh.
- `.github/workflows/build-oniroai.yml`: phục hồi dự án từ APK bằng Godot RE Tools, thêm màn hình mới, dựng APK ARM64 bằng Godot 4.5.1.

## Giới hạn quan trọng

Đây là **bộ dựng phục hồi**, KHÔNG phải APK OniRoai hoàn chỉnh và cũng chưa phải dự án nguồn 0.6.0 gốc.
Vì ZIP mất các script `.gd` và scene `.tscn`, GitHub Actions cần giải mã source từ APK 0.4.0 trước. GDRE Tools hỗ trợ Godot 4.x nhưng bước giải mã và toàn bộ build **chưa được thực thi/kiểm chứng** ở môi trường này. Nếu một bước lỗi, artifact vẫn lưu log chẩn đoán.

Các tính năng code chưa có trong ZIP (thay HUD nâng cao, điều khiển mới, thông báo Android, nâng kích cỡ súng) KHÔNG được nhận là đã tích hợp. Bộ này ưu tiên dựng được gameplay cũ + màn hình key/loading mới. Mã key chỉ có tác dụng mở game cục bộ, không phải cơ chế bảo mật.

## Cách dựng APK trên Android không cần máy tính

1. Tải file ZIP này về điện thoại; giải nén bằng ZArchiver hoặc Termux.
2. Tạo **repository trống mới** tên `OniRoai` trên GitHub, không bật README.
3. Mở Termux và chạy (điều chỉnh tên ZIP nếu cần):

```sh
termux-setup-storage
pkg install -y git unzip
cd ~
unzip -o ~/storage/downloads/OniRoai-Build-Kit.zip -d OniRoai-Build-Kit
cd ~/OniRoai-Build-Kit

git init -b main
git add .
git commit -m "Set up Godot APK recovery build"
git remote add origin https://github.com/quanminh2089-blip/OniRoai.git
git push -u origin main
```

4. Mở `https://github.com/quanminh2089-blip/OniRoai/actions`, chọn `Rebuild OniRoai APK from recovered game`.
5. Nếu thành công, tải artifact `OniRoai-Recovered-APK-and-Logs`, giải nén file `OniRoai-recovered.apk` và cài đặt.

APK dựng thử có package `vn.minhquan.oniroai.recovered` để **không ghi đè** bản game cũ do khóa ký đã mất. Bản dựng dùng debug key GitHub Actions, phù hợp kiểm thử, không nên phân phối như bản phát hành chính thức.

## Không sử dụng `git push --force`

Cấu trúc này không thay đổi repo MQUAN-MOD hoặc APK game cũ trên điện thoại.
