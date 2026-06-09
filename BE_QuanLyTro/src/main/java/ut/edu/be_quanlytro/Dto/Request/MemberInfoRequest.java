package ut.edu.be_quanlytro.Dto.Request;

import lombok.Getter;
import lombok.Setter;
import java.time.LocalDate;

@Getter @Setter
public class MemberInfoRequest {
    private String phone;
    private String fullName;
    private LocalDate dob; // Frontend gửi dạng yyyy-MM-dd để Spring tự parse
    private String hometown;
    private String idCardFrontUrl; // Nhận lại link từ Giai đoạn 1
    private String idCardBackUrl;  // Nhận lại link từ Giai đoạn 1
}