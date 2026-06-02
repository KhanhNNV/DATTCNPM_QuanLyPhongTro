package ut.edu.be_quanlytro.Controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;
import ut.edu.be_quanlytro.Dto.Request.UserCreateRequest;
import ut.edu.be_quanlytro.Dto.Request.UserUpdateRequest;
import ut.edu.be_quanlytro.Dto.Response.UserResponse;
import ut.edu.be_quanlytro.Service.UserService;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    /**
     * API Khởi tạo tài khoản người dùng mới.
     * Chỉ Chủ trọ mới được phép tạo tài khoản cho khách.
     */
    @PostMapping
    @PreAuthorize("hasRole('LANDLORD')") // Đã chuyển sang hasRole
    public ResponseEntity<UserResponse> createUser(
            @RequestBody UserCreateRequest request,
            @AuthenticationPrincipal Jwt jwt) {

        // Lấy đúng trường "userId" từ Token
        UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));
        UserResponse response = userService.createUser(request, currentUserId);

        return new ResponseEntity<>(response, HttpStatus.CREATED);
    }

    /**
     * API Lấy danh sách Khách thuê đang ở trong một Khu trọ cụ thể.
     * Chỉ Chủ trọ (LANDLORD) mới có quyền xem danh sách này.
     *
     * @param areaId Mã định danh UUID của Khu trọ
     * @return Danh sách UserResponse chứa thông tin khách thuê (đã ẩn mật khẩu)
     */
    @GetMapping("/area/{areaId}")
    @PreAuthorize("hasRole('LANDLORD')")
    public ResponseEntity<List<UserResponse>> getUsersByArea(@PathVariable UUID areaId) {
        List<UserResponse> tenants = userService.getUsersByArea(areaId);
        return ResponseEntity.ok(tenants);
    }

    /**
     * API Lấy thông tin chi tiết của một người dùng dựa vào ID.
     * Thường Chủ trọ mới có quyền tra cứu thông tin của người khác.
     */
    @GetMapping("/{id}")
    @PreAuthorize("hasRole('LANDLORD')") // Đã chuyển sang hasRole
    public ResponseEntity<UserResponse> getUserById(@PathVariable UUID id) {
        return ResponseEntity.ok(userService.getUserById(id));
    }

    /**
     * API Xem hồ sơ cá nhân của chính người đang đăng nhập (Current User).
     * Cả Chủ trọ và Khách thuê đều có quyền xem hồ sơ của mình.
     */
    @GetMapping("/current")
    @PreAuthorize("hasAnyRole('LANDLORD', 'TENANT')") // Khách và Chủ đều dùng được
    public ResponseEntity<UserResponse> getCurrentUser(@AuthenticationPrincipal Jwt jwt) {

        // Lấy đúng trường "userId" từ Token
        UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));
        return ResponseEntity.ok(userService.getUserById(currentUserId));
    }

    /**
     * API Cập nhật thông tin người dùng (Hỗ trợ Partial Update).
     * Cả Chủ trọ và Khách thuê đều có quyền cập nhật thông tin cá nhân.
     */
    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('LANDLORD', 'TENANT')") // Khách và Chủ đều dùng được
    public ResponseEntity<UserResponse> updateUser(
            @PathVariable UUID id,
            @RequestBody UserUpdateRequest request,
            @AuthenticationPrincipal Jwt jwt) {

        // Lấy đúng trường "userId" từ Token để ghi Log
        UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));
        UserResponse response = userService.updateUser(id, request, currentUserId);

        return ResponseEntity.ok(response);
    }

    /**
     * API Xóa tài khoản người dùng vĩnh viễn khỏi hệ thống.
     * Chỉ có Chủ trọ mới có quyền xóa.
     */
    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('LANDLORD')") // Đã chuyển sang hasRole
    public ResponseEntity<String> deleteUser(
            @PathVariable UUID id,
            @AuthenticationPrincipal Jwt jwt) {

        // Lấy đúng trường "userId" từ Token để ghi Log
        UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));
        userService.deleteUser(id, currentUserId);

        return ResponseEntity.ok("Xóa tài khoản người dùng thành công");
    }
}