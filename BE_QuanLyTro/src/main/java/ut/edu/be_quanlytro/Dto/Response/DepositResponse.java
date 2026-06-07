package ut.edu.be_quanlytro.Dto.Response;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;
import ut.edu.be_quanlytro.Entity.Enum.DepositStatus;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

@Getter
@Setter
@Builder
public class DepositResponse {
    private UUID id;
    private UUID roomId;
    private String roomNumber;
    private String phone;
    private String tenantFullName;
    private BigDecimal depositAmount;
    private LocalDate depositDate;
    private LocalDate expectedMoveInDate;
    private String note;
    private DepositStatus status;
}