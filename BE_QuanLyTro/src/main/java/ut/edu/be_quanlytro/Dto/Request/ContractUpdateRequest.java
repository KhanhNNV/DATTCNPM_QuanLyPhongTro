package ut.edu.be_quanlytro.Dto.Request;

import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDate;

@Getter @Setter
public class ContractUpdateRequest {
    private LocalDate startDate;
    private LocalDate endDate;
    private BigDecimal depositAmount;
}