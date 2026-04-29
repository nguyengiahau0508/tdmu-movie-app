# 📚 Tài liệu dự án Movie App (MVP)

Thư mục `docs` đã được rút gọn theo hướng **app xem phim đơn giản**, không đi theo mô hình enterprise như Netflix.

## Tài liệu chính

| File | Mục đích |
|---|---|
| [system-overview.md](./system-overview.md) | Phạm vi tính năng MVP |
| [architecture.md](./architecture.md) | Kiến trúc đơn giản, dễ triển khai |
| [database-design.md](./database-design.md) | Thiết kế CSDL tối giản |
| [schema-improved.sql](./schema-improved.sql) | SQL tạo schema chạy ngay |
| [api-specification.md](./api-specification.md) | API REST cho frontend/backend |
| [QUICK-START.md](./QUICK-START.md) | Cách khởi tạo DB nhanh |

## Mục tiêu dự án

Xây dựng app xem phim cơ bản với các chức năng đủ dùng:

1. Đăng ký/đăng nhập.
2. Danh sách phim, tìm kiếm, lọc theo thể loại.
3. Trang chi tiết phim và danh sách tập (nếu là series).
4. Phát video từ URL lưu trong DB.
5. Danh sách yêu thích, lịch sử xem tiếp, đánh giá.
6. Trang admin đơn giản để quản lý phim/tập/thể loại.
