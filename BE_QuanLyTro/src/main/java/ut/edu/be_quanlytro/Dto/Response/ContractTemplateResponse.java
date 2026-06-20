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
    private String content;
    private Boolean isSystemTemplate; // true nếu là mẫu hệ thống (landlord = null)
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}