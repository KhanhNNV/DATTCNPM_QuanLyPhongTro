package ut.edu.be_quanlytro.Dto.Response;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;
import java.util.UUID;

@Getter @Setter @Builder
public class ContractMemberResponse {
    private UUID id;
    private String fullName;
    private String phone;
    private LocalDate dob;
    private String hometown;
    private LocalDate joinedAt;
}