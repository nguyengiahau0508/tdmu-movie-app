# 🎬 System Overview – Movie App (MVP)

## 1. Mục tiêu

Dự án tập trung vào một ứng dụng xem phim cơ bản cho web/mobile, ưu tiên:
- Dễ làm, dễ bảo trì.
- Triển khai nhanh.
- Đủ tính năng cốt lõi cho người dùng cuối.

## 2. Phạm vi tính năng

### Người dùng
- Đăng ký, đăng nhập.
- Xem danh sách phim.
- Tìm kiếm phim theo từ khóa.
- Lọc phim theo thể loại.
- Xem chi tiết phim.
- Xem danh sách tập (series).
- Lưu/huỷ yêu thích.
- Lưu tiến độ xem để xem tiếp.
- Đánh giá phim (điểm + bình luận ngắn).

### Quản trị (admin cơ bản)
- CRUD phim.
- CRUD tập phim.
- CRUD thể loại.

## 3. Không nằm trong phạm vi MVP

- Subscription trả phí.
- Đồng bộ nhiều thiết bị phức tạp.
- Microservices, queue, cache cluster.
- DRM, CDN đa vùng, analytics nâng cao.
- Audit log enterprise và các chỉ số SLA/SLO phức tạp.

## 4. Tech stack gợi ý

- Frontend: React hoặc Flutter.
- Backend: Node.js (NestJS/Express).
- Database: MariaDB/MySQL.
- Lưu trữ video: URL file/video service sẵn có.
