package ut.edu.be_quanlytro.Dto.Request;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class PasswordChangeRequest {
    private String oldPassword;
    private String newPassword;
}