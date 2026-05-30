package ut.edu.be_quanlytro.Dto.Request;

import lombok.Getter;
import lombok.Setter;

@Getter @Setter
public class AreaRequest {
    private String name;
    private String address;
    private Integer invoiceDay;
    private Integer dueDate;
}