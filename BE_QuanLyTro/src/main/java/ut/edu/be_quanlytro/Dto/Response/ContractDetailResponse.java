package ut.edu.be_quanlytro.Dto.Response;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;
import ut.edu.be_quanlytro.Entity.Enum.ContractStatus;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

@Getter @Setter @Builder
public class ContractDetailResponse {
    private UUID id;
    private UUID roomId;
    private String roomName; // Tên phòng
    private String tenantName; // Tên người đại diện
    private String tenantPhone;
    private LocalDate startDate;
    private LocalDate endDate;
    private BigDecimal depositAmount;
    private ContractStatus status;
    private int totalMembers; // Đếm số lượng người đang ở chung
}