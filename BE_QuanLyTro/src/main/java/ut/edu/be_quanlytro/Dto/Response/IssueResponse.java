package ut.edu.be_quanlytro.Dto.Response;

import lombok.Builder;
import lombok.Data;
import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
public class IssueResponse {
    private UUID id;
    private String roomNumber;
    private String tenantName;
    private String description;
    private String imageUrl;
    private String status;
    private String solutionNote;
    private LocalDateTime createdAt;
}