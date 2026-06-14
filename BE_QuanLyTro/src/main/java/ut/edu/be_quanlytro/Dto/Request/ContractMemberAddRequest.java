package ut.edu.be_quanlytro.Dto.Request;

import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;
import java.util.UUID;

@Getter @Setter
public class ContractMemberAddRequest {
    private UUID contractId;
    private String fullName;
    private String phone;
    private LocalDate dob;
    private String hometown;
    private String idCardNumber;
}