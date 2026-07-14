package ut.edu.be_quanlytro.Dto.Request;

import lombok.Getter;
import lombok.Setter;


@Getter @Setter
public class ContractTerminationRequest {
    private Integer electricityUsage;
    private Integer waterUsage;
}