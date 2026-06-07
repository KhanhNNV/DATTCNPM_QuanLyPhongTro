package ut.edu.be_quanlytro.Dto.Request;

import lombok.Getter;
import lombok.Setter;
import ut.edu.be_quanlytro.Entity.Enum.DepositStatus;

import java.math.BigDecimal;
import java.time.LocalDate;

@Getter
@Setter
public class DepositUpdateRequest {
    private String phone;
    private String tenantFullName;
    private BigDecimal depositAmount;
    private LocalDate expectedMoveInDate;
    private String note;
    private DepositStatus status; // Cho phép chủ trọ đổi trạng thái (VD: Hủy cọc)
}