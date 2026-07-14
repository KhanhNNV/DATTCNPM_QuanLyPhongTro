package ut.edu.be_quanlytro.Dto.Response;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

@Getter @Setter @Builder
public class OcrCccdResponse {
    private String idNumber;
    private String fullName;
    private String dob;
    private String hometown;
}