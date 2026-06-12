package ut.edu.be_quanlytro.Controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import ut.edu.be_quanlytro.Dto.Request.UserCreateRequest;
import ut.edu.be_quanlytro.Dto.Request.UserUpdateRequest;
import ut.edu.be_quanlytro.Dto.Response.UserResponse;
import ut.edu.be_quanlytro.Service.UserService;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    /**
     * API Lấy danh sách Khách thuê đang ở trong một Khu trọ cụ thể.
     * Chỉ Chủ trọ (LANDLORD) mới có quyền xem danh sách này.
     *
     * @param areaId Mã định danh UUID của Khu trọ
     * @param jwt Token chứa thông tin xác thực của người gọi API
     * @return Danh sách UserResponse chứa thông tin khách thuê (đã ẩn mật khẩu)
     */
    @GetMapping("/area/{areaId}")
    @PreAuthorize("hasRole('LANDLORD')")
    public ResponseEntity<List<UserResponse>> getUsersByArea(
            @PathVariable UUID areaId,
            @AuthenticationPrincipal Jwt jwt) { // Bổ sung việc hứng Token ở đây

        // 1. Trích xuất ID người dùng từ Token
        UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));

        // 2. Truyền đủ 2 tham số (areaId và currentUserId) xuống Service
        List<UserResponse> tenants = userService.getUsersByArea(areaId, currentUserId);

        return ResponseEntity.ok(tenants);
    }

    /**
     * API 1: Xem hồ sơ cá nhân của CHÍNH NGƯỜI ĐANG ĐĂNG NHẬP (Current Profile).
     * URL: GET /api/users/current
     */
    @GetMapping("/current")
    @PreAuthorize("hasAnyRole('LANDLORD', 'TENANT')")
    public ResponseEntity<UserResponse> getCurrentUser(@AuthenticationPrincipal Jwt jwt) {
        // Trích xuất ID từ Token
        UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));

        // Vì tự xem chính mình nên truyền tham số ID cần xem trùng với ID người gọi
        return ResponseEntity.ok(userService.getUserById(currentUserId, currentUserId));
    }

    /**
     * API 2: Chủ trọ chủ động xem chi tiết thông tin của một Khách thuê qua ID.
     * URL: GET /api/users/{id}
     */
    @GetMapping("/{id}")
    @PreAuthorize("hasRole('LANDLORD')")
    public ResponseEntity<UserResponse> getUserById(
            @PathVariable UUID id,
            @AuthenticationPrincipal Jwt jwt) {

        // Trích xuất ID của Chủ trọ đang gọi từ Token
        UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));

        // Đẩy cả ID khách cần xem và ID chủ trọ xuống để Service check quyền sở hữu
        return ResponseEntity.ok(userService.getUserById(id, currentUserId));
    }

    /**
     * API Cập nhật thông tin người dùng
     */
    @PutMapping("/{id}")
    @PreAuthorize("hasRole('LANDLORD')")
    public ResponseEntity<UserResponse> updateUser(
            @PathVariable UUID id,
            @RequestBody UserUpdateRequest request,
            @AuthenticationPrincipal Jwt jwt) {

        // Lấy đúng trường "userId" từ Token để ghi Log
        UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));
        UserResponse response = userService.updateUser(id, request, currentUserId);

        return ResponseEntity.ok(response);
    }



    @PutMapping("/signature")
    @PreAuthorize("hasRole('LANDLORD')")
    public ResponseEntity<?> updateSignature(
            @RequestParam("file") MultipartFile file,
            @AuthenticationPrincipal Jwt jwt) {

        UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));
        userService.updateSignature(file, currentUserId);

        return ResponseEntity.ok(Map.of("message", "Tải chữ ký lên thành công!"));
    }

    @GetMapping("/signature")
    @PreAuthorize("hasRole('LANDLORD')")
    public ResponseEntity<?> getSignature(@AuthenticationPrincipal Jwt jwt) {

        // 1. Trích xuất ID người dùng từ Jwt Token đang đăng nhập
        UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));

        // 2. Gọi Service lấy URL
        String signatureUrl = userService.getSignature(currentUserId);

        // 3. Bọc kết quả vào Map để trả về JSON chuẩn chỉnh cho Frontend
        return ResponseEntity.ok(Map.of(
                "signatureUrl", signatureUrl != null ? signatureUrl : ""
        ));
    }
}