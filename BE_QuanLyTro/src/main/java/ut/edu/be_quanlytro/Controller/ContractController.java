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
import ut.edu.be_quanlytro.Dto.Request.*;
import ut.edu.be_quanlytro.Dto.Response.ContractCreateResponse;
import ut.edu.be_quanlytro.Dto.Response.ContractDetailResponse;
import ut.edu.be_quanlytro.Dto.Response.ContractTerminationResponse;
import ut.edu.be_quanlytro.Service.ContractService;

import java.util.List;
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

    @PostMapping("/create/manual")
    @PreAuthorize("hasRole('LANDLORD')")
    public ResponseEntity<ContractCreateResponse> createContractManual(
            @RequestBody ContractCreateManualRequest request, // Dùng thẳng @RequestBody vì là JSON mượt mà
            @AuthenticationPrincipal Jwt jwt) {

        UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));
        ContractCreateResponse response = contractService.createContractManual(request, currentUserId);
        return ResponseEntity.ok(response);
    }

    // API 1: Xem chi tiết theo ID (Chỉ Chủ trọ)
    @GetMapping("/{contractId}")
    @PreAuthorize("hasRole('LANDLORD')")
    public ResponseEntity<ContractDetailResponse> getContractDetail(
            @PathVariable UUID contractId,
            @AuthenticationPrincipal Jwt jwt) {

        UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));
        ContractDetailResponse response = contractService.getContractByIdForLandlord(contractId, currentUserId);
        return ResponseEntity.ok(response);
    }

    // API 2: Lấy hợp đồng "Của tôi" (Chỉ Khách thuê)
    @GetMapping("/current")
    @PreAuthorize("hasRole('TENANT')")
    public ResponseEntity<ContractDetailResponse> getMyCurrentContract(
            @AuthenticationPrincipal Jwt jwt) {

        UUID tenantId = UUID.fromString(jwt.getClaimAsString("userId"));
        ContractDetailResponse response = contractService.getMyCurrentContract(tenantId);
        return ResponseEntity.ok(response);
    }

    // API Xem danh sách toàn bộ Hợp đồng của Chủ trọ
    @GetMapping
    @PreAuthorize("hasRole('LANDLORD')")
    public ResponseEntity<List<ContractDetailResponse>> getMyContracts(
            @AuthenticationPrincipal Jwt jwt) {

        UUID landlordId = UUID.fromString(jwt.getClaimAsString("userId"));
        List<ContractDetailResponse> responses = contractService.getContractsByLandlord(landlordId);

        return ResponseEntity.ok(responses);
    }

    // API 4: Thêm thành viên ở ghép vào hợp đồng
    @PostMapping("/add/member")
    @PreAuthorize("hasRole('LANDLORD')") // Nghiệp vụ mặc định: Chỉ chủ trọ mới có quyền khai báo người mới
    public ResponseEntity<ContractDetailResponse> addContractMember(
            @RequestBody ContractMemberAddRequest request,
            @AuthenticationPrincipal Jwt jwt) {

        UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));
        ContractDetailResponse response = contractService.addContractMember(request, currentUserId);

        return ResponseEntity.ok(response);
    }
    // API 5: Thanh lý hợp đồng & Bù trừ cọc
    @PutMapping("/terminate")
    @PreAuthorize("hasRole('LANDLORD')") // Chỉ Chủ trọ được quyền thanh lý
    public ResponseEntity<ContractTerminationResponse> terminateContract(
            @RequestBody ContractTerminationRequest request,
            @AuthenticationPrincipal Jwt jwt) {

        UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));
        ContractTerminationResponse response = contractService.terminateContract(request, currentUserId);

        return ResponseEntity.ok(response);
    }

    // API 6: Cập nhật thông tin hợp đồng (Nháp)
    @PutMapping("/update/{contractId}")
    @PreAuthorize("hasRole('LANDLORD')")
    public ResponseEntity<ContractDetailResponse> updateContract(
            @PathVariable UUID contractId,
            @ModelAttribute ContractUpdateRequest request,
            @RequestParam(value = "file", required = false) MultipartFile file,
            @AuthenticationPrincipal Jwt jwt) {

        UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));

        ContractDetailResponse response = contractService.updateContract(contractId, request, file, currentUserId);

        return ResponseEntity.ok(response);
    }

    // ================= XÓA HỢP ĐỒNG (BẢN NHÁP) =================
    @DeleteMapping("/{contractId}")
    @PreAuthorize("hasRole('LANDLORD')") // Chỉ chủ trọ mới có quyền xóa
    public ResponseEntity<String> deleteContract(
            @PathVariable UUID contractId,
            @AuthenticationPrincipal Jwt jwt) {

        // 1. Trích xuất ID của chủ trọ đang đăng nhập từ Token
        UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));

        // 2. Gọi Service để thực hiện xóa hợp đồng và tự động dọn rác tài khoản
        contractService.deleteContract(contractId, currentUserId);

        // 3. Trả về thông báo thành công cho Frontend
        return ResponseEntity.ok("Xóa bản nháp hợp đồng thành công! Căn phòng đã được giải phóng và dữ liệu đã được dọn dẹp.");
    }

    // ================= KHÁCH THUÊ KÝ HỢP ĐỒNG =================
    @PutMapping("/sign/{contractId}")
    @PreAuthorize("hasRole('TENANT')") // Khóa chặt: Chỉ có Khách thuê mới được ký
    public ResponseEntity<ContractDetailResponse> signContract(
            @PathVariable UUID contractId,
            @RequestParam("signature") MultipartFile signatureImage,
            @AuthenticationPrincipal Jwt jwt) {

        UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));
        ContractDetailResponse response = contractService.signContract(contractId, signatureImage, currentUserId);

        return ResponseEntity.ok(response);
    }

    // ================= GIA HẠN HỢP ĐỒNG (Gia hạn là tạo hợp đồng mới nhưng tài khoản cũ) =================
    @PutMapping("/extend/{contractId}")
    @PreAuthorize("hasRole('LANDLORD')") // Chỉ chủ trọ mới có quyền gia hạn
    public ResponseEntity<ContractDetailResponse> extendContract(
            @PathVariable UUID contractId,
            @RequestBody ContractExtendRequest request,
            @AuthenticationPrincipal Jwt jwt) {

        UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));
        ContractDetailResponse response = contractService.extendContract(contractId, request, currentUserId);

        return ResponseEntity.ok(response);
    }



    // ================= UPLOAD FILE HỢP ĐỒNG =================
    @PostMapping(value = "/upload/file/{id}", consumes = "multipart/form-data")
    @PreAuthorize("hasRole('LANDLORD')")
    public ResponseEntity<ContractDetailResponse> uploadContractFile(
            @PathVariable UUID id,
            @RequestParam("file") MultipartFile file,
            @AuthenticationPrincipal Jwt jwt) {

        UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));

        // Gọi Service và trả kết quả
        return ResponseEntity.ok(contractService.uploadContractFile(id, file, currentUserId));
    }
}