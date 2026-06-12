package ut.edu.be_quanlytro.Controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import ut.edu.be_quanlytro.Dto.Request.ContractCreateRequest;
import ut.edu.be_quanlytro.Dto.Response.ContractCreateResponse;
import ut.edu.be_quanlytro.Service.ContractService;

import java.util.UUID;

@RestController
@RequestMapping("/api/contracts")
@RequiredArgsConstructor
public class ContractController {

    private final ContractService contractService;
    private final ObjectMapper objectMapper = new ObjectMapper()
            .registerModule(new com.fasterxml.jackson.datatype.jsr310.JavaTimeModule());

    @PostMapping(value = "/create", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("hasRole('LANDLORD')") // Chỉ chủ trọ mới có quyền tạo hợp đồng
    public ResponseEntity<ContractCreateResponse> createContract(
            @RequestParam("data") String dataJson,
            @RequestParam("frontImage") MultipartFile frontImage,
            @RequestParam("backImage") MultipartFile backImage,
            @AuthenticationPrincipal Jwt jwt) { // Lấy thông tin user từ Token bảo mật

        try {
            // 1. Chuyển chuỗi chữ JSON nhận từ Form-Data thành Object Request
            ContractCreateRequest request = objectMapper.readValue(dataJson, ContractCreateRequest.class);

            // 2. Trích xuất ID của chủ trọ đang đăng nhập từ JWT Token
            // Lưu ý: Thay "userId" bằng đúng tên Claim chứa ID trong Token của dự án bạn
            UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));

            // 3. Gọi Service thực hiện xử lý nghiệp vụ
            ContractCreateResponse response = contractService.createContract(request, frontImage, backImage, currentUserId);

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            // Nếu có bất kỳ lỗi gì (OCR lỗi, phòng đã thuê, thiếu chữ ký...), thảy về mã lỗi 400 kèm tin nhắn
            throw new RuntimeException("Quá trình lập hợp đồng thất bại: " + e.getMessage());
        }
    }
}