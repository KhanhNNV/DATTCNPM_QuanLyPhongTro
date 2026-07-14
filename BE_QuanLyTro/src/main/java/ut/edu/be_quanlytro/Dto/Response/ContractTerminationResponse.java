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
    private BigDecimal depositAmount;
    private BigDecimal totalDeduction;
    private BigDecimal finalAmount;
    private String settlementAction;
    private String message;
}