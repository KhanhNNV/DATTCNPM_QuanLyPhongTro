package ut.edu.be_quanlytro.Dto.Request;

import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;

@Getter @Setter
public class UserUpdateRequest {
    private String phone;
    private String password;
    private String fullName;
    private LocalDate dob;
    private String hometown;
}