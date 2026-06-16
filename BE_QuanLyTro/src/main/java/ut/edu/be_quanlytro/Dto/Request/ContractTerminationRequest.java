package ut.edu.be_quanlytro.Dto.Request;

import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.util.UUID;

@Getter @Setter
public class ContractTerminationRequest {
    private UUID contractId;

    // Số điện đã dùng tháng cuối (Chỉ số mới - Chỉ số cũ)
    private Integer electricityUsage;
    // Đơn giá điện
    private BigDecimal electricityPrice;
    // Số khối nước đã dùng tháng cuối
    private Integer waterUsage;
    // Đơn giá nước
    private BigDecimal waterPrice;

    // Các khoản phát sinh khác
    private BigDecimal otherDamagesFee;
    // Lý do thanh lý (Khách chuyển đi, Vi phạm hợp đồng...)
    private String note;
}