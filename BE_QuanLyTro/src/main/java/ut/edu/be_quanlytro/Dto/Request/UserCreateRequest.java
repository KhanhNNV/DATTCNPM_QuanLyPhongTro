package ut.edu.be_quanlytro.Dto.Request;

import jakarta.persistence.Column;
import lombok.Getter;
import lombok.Setter;
import ut.edu.be_quanlytro.Entity.Enum.RoleType;

import java.time.LocalDate;

@Getter @Setter
public class UserCreateRequest {
    private String phone;
    private String password;
    private RoleType role;
    private String fullName;
    private LocalDate dob;
    private String hometown;
    private String idCardNumber;
}