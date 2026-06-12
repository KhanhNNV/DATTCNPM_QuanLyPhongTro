package ut.edu.be_quanlytro.Dto.Request;

import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

@Getter @Setter
public class ContractCreateRequest {
    private UUID roomId;
    private LocalDate startDate;
    private LocalDate endDate;
    private BigDecimal depositAmount;

    // Thông tin cơ bản
    private String tenantPhone;

    // Có thể null nếu khách không đặt cọc trước
    private UUID depositId;
}