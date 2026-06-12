package ut.edu.be_quanlytro.Dto.Response;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

@Getter @Setter @Builder
public class OcrCccdResponse {
    private String idNumber;     // Số CCCD
    private String fullName;     // Họ và tên
    private String dob;          // Ngày sinh (Có thể để String để Frontend tự parse)
    private String hometown;     // Quê quán
}