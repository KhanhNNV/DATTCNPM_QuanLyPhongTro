package ut.edu.be_quanlytro.Dto.Request;

import lombok.Data;

@Data
public class LoginRequest {
    private String phone;
    private String password;
}