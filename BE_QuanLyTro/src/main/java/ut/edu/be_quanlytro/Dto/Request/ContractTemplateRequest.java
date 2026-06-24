package ut.edu.be_quanlytro.Dto.Request;

import lombok.Getter;
import lombok.Setter;

@Getter @Setter
public class ContractTemplateRequest {
    private String name;

    // 4 trường nội dung mới thay thế cho content cũ
    private String rentalContent;   // Nội dung thuê phòng
    private String landlordDuty;    // Trách nhiệm bên A
    private String tenantDuty;      // Trách nhiệm bên B
    private String executionTerms;  // Điều khoản thực hiện
}