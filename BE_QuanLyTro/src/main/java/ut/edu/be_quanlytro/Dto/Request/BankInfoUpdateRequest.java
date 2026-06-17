package ut.edu.be_quanlytro.Dto.Request;

import lombok.Data;

@Data
public class BankInfoUpdateRequest {
    private String bankId;
    private String accountNo;
    private String accountName;
}