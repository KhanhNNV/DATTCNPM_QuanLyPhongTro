package ut.edu.be_quanlytro.Dto.Response;

import lombok.Builder;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

@Data
@Builder
public class InvoiceResponse {
    private UUID id;
    private String roomNumber;
    private LocalDate invoicePeriod;
    private LocalDate dueDate;
    private BigDecimal roomPrice; // Tiền phòng gốc
    private BigDecimal totalAmount; // Tổng tiền (Phòng + Điện + Nước + Rác...)
    private String status;
}