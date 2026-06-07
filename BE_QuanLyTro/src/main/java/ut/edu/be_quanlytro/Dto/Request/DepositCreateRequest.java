package ut.edu.be_quanlytro.Dto.Request;

import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

@Getter
@Setter
public class DepositCreateRequest {
    private UUID roomId;
    private String phone;
    private String tenantFullName;
    private BigDecimal depositAmount;
    private LocalDate expectedMoveInDate;
    private String note;
}