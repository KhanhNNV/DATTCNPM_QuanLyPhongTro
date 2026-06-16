package ut.edu.be_quanlytro.Dto.Response;

import lombok.Builder;
import lombok.Data;
import java.math.BigDecimal;

@Data
@Builder
public class PaymentQrResponse {
    private String bankId;         // Tên viết tắt ngân hàng (VD: MB, VCB)
    private String accountNo;      // Số tài khoản
    private String accountName;    // Tên chủ tài khoản
    private BigDecimal amount;     // Số tiền cần chuyển
    private String content;        // Nội dung chuyển khoản
    private String qrImageUrl;     // Link cái ảnh QR để Frontend đem in ra
}