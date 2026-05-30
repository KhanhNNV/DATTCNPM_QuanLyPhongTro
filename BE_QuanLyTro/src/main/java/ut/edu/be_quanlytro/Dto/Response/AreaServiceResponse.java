package ut.edu.be_quanlytro.Dto.Response;

import lombok.Builder;
import lombok.Getter;
import ut.edu.be_quanlytro.Entity.Enum.ServiceCalculationType;

import java.math.BigDecimal;
import java.util.UUID;

@Getter @Builder
public class AreaServiceResponse {
    private String name;
    private ServiceCalculationType calcType;
    private BigDecimal price;
    private Boolean isActive;
}