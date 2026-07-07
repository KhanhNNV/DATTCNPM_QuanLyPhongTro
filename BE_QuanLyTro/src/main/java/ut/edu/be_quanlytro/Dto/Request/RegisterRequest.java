package ut.edu.be_quanlytro.Dto.Request;

import jakarta.validation.constraints.Email;
import lombok.Data;

@Data
public class RegisterRequest {
    private String phone;
    private String password;
    private String fullName;
    private String idCardNumber;
    private String hometown;
    @Email(message = "Định dạng email không hợp lệ!")
    private String email;
}