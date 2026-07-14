package ut.edu.be_quanlytro.Dto.Response;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.UUID;

@Getter @Setter @Builder
public class ContractTemplateResponse {
    private UUID id;
    private String name;
    private String rentalContent;
    private String landlordDuty;
    private String tenantDuty;
    private String executionTerms;
    private Boolean isActive;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}