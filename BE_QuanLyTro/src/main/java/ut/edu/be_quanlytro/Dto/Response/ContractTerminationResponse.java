package ut.edu.be_quanlytro.Dto.Response;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.util.UUID;

@Getter @Setter @Builder
public class ContractTerminationResponse {
    private UUID contractId;
    private String roomNumber;
    private BigDecimal depositAmount;      // Tiền cọc ban đầu
    private BigDecimal totalDeduction;     // Tổng tiền phạt/điện nước tháng cuối phải trừ
    private BigDecimal finalAmount;        // Số tiền chênh lệch cuối cùng
    private String settlementAction;       // Hành động: "HOÀN_TRẢ_KHÁCH" hoặc "THU_THÊM_TỪ_KHÁCH"
    private String message;
}