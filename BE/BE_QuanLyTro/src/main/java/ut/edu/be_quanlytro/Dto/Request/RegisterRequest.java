package ut.edu.be_quanlytro.Dto.Request;

import lombok.Data;

@Data
public class RegisterRequest {
    private String phone;
    private String password;
    private String fullName;
}