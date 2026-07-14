package ut.edu.be_quanlytro.Dto.Request;

import lombok.Getter;
import lombok.Setter;
import ut.edu.be_quanlytro.Entity.Enum.ServiceCalculationType;

import java.math.BigDecimal;

@Getter
@Setter
public class AreaServiceRequest {
    private String name;
    private ServiceCalculationType calcType;
    private BigDecimal price;
}