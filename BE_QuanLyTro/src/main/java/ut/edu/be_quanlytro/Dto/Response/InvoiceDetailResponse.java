package ut.edu.be_quanlytro.Dto.Response;

import lombok.Builder;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Data
@Builder
public class InvoiceDetailResponse {
    private UUID id;
    private String roomNumber;
    private LocalDate invoicePeriod;
    private LocalDate dueDate;
    private BigDecimal roomPrice;
    private BigDecimal totalAmount;
    private String status;
    private List<InvoiceItemResponse> items;
}