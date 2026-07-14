package ut.edu.be_quanlytro.Dto.Request;

import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.util.UUID;

@Getter @Setter
public class ContractTerminationRequest {
    // Số điện đã dùng tháng cuối (Chỉ số mới - Chỉ số cũ)
    private Integer electricityUsage;
    // Số khối nước đã dùng tháng cuối
    private Integer waterUsage;
}