package ut.edu.be_quanlytro.Dto.Response;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

import java.util.UUID;

@Getter @Setter @Builder
public class ContractCreateResponse {
    private UUID contractId;
    private String tenantUsername;
    private String tenantRawPassword;
    private String message;
}