package ut.edu.be_quanlytro.Dto.Response;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;
import ut.edu.be_quanlytro.Entity.Enum.RoleType;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter @Setter @Builder
public class UserResponse {
    private UUID id;
    private String phone;
    private RoleType role;
    private String fullName;
    private LocalDate dob;
    private String hometown;
    private String idCardFront;
    private String idCardBack;
    private Boolean isFirstLogin;
}