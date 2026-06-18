package ut.edu.be_quanlytro.Dto.Response;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;
import ut.edu.be_quanlytro.Entity.Enum.NotificationType;

import java.time.LocalDateTime;
import java.util.UUID;

@Getter @Setter @Builder
public class NotificationResponse {
    private UUID id;
    private String title;
    private String content;
    private NotificationType type;
    private Boolean isRead;
    private LocalDateTime createdAt;
}