package ut.edu.be_quanlytro.Dto.Request;
import lombok.Data;

@Data
public class ChangePasswordRequest {
    private String oldPassword;
    private String newPassword;
}
