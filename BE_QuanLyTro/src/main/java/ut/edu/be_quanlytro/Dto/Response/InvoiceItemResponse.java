package ut.edu.be_quanlytro.Dto.Response;

import lombok.Builder;
import lombok.Data;
import java.math.BigDecimal;

@Data
@Builder
public class InvoiceItemResponse {
    private String serviceName;
    private Integer oldIndex;    // Sẽ null nếu là Wifi/Rác
    private Integer newIndex;    // Sẽ null nếu là Wifi/Rác
    private Integer quantity;    // Số ký điện, khối nước hoặc số đầu người
    private BigDecimal price;     // Đơn giá
    private BigDecimal totalAmount; // Thành tiền dòng này
}