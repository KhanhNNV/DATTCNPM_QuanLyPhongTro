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

    // Thông tin cơ bản của Khách đại diện để hệ thống tạo tài khoản
    private String tenantName;
    private String tenantPhone;
}