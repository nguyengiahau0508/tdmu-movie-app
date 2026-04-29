# 🏗️ Kiến trúc hệ thống (MVP)

## 1. Kiến trúc tổng quan

```text
Client (Web/Mobile)
        |
      HTTPS
        |
Backend API (Monolith)
        |
     MariaDB
```

## 2. Lý do chọn kiến trúc này

- Dễ phát triển cho team nhỏ.
- Ít chi phí vận hành.
- Nhanh đưa sản phẩm vào sử dụng.
- Dễ debug hơn so với kiến trúc phân tán.

## 3. Thành phần chính

### Client
- Gọi API để lấy danh sách phim, chi tiết phim, lịch sử xem.
- Phát video bằng URL do backend trả về.

### Backend API (Monolith)
- Auth: đăng ký/đăng nhập.
- Movies: danh sách, tìm kiếm, lọc, chi tiết.
- Episodes: danh sách tập theo phim.
- Watchlist: thêm/xoá yêu thích.
- Watch history: cập nhật tiến độ xem.
- Reviews: tạo/sửa/xoá đánh giá.
- Admin: quản lý phim/tập/thể loại.

### Database (MariaDB)
- Lưu dữ liệu người dùng, phim, tập, thể loại, lịch sử xem, yêu thích, đánh giá.

## 4. Hướng mở rộng sau MVP

Khi tải tăng, có thể mở rộng dần:
1. Thêm Redis cache cho danh sách phim phổ biến.
2. Tách service upload/video nếu cần.
3. Thêm CDN sau khi traffic đủ lớn.
