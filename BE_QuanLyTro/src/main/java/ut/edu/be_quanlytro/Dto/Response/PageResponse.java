package ut.edu.be_quanlytro.Dto.Response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PageResponse<T> {
    private List<T> content;       // Chứa danh sách dữ liệu thực tế
    private int pageNumber;        // Đang ở trang số mấy
    private int pageSize;          // Kích thước 1 trang
    private long totalElements;    // Tổng số lượng tất cả các dòng
    private int totalPages;        // Tổng số trang
    private boolean isLast;        // Có phải trang cuối cùng chưa
}