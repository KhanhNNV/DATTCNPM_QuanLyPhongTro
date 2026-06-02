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
     * - Kiểm tra tính duy nhất của Số điện thoại.
     * - Tự động mã hóa (Hash) mật khẩu trước khi lưu.
     * - Lưu lại vết thao tác (Activity Log) của người tạo.
     *
     * @param request Payload chứa thông tin đăng ký (Phone, Password, Role, Info...)
     * @param jwt Token xác thực chứa ID của người đang thực hiện tạo tài khoản
     * @return UserResponse Thông tin tài khoản vừa tạo (đã ẩn mật khẩu)
     */
    @PostMapping
    @PreAuthorize("hasAuthority('SCOPE_LANDLORD')")
    public ResponseEntity<UserResponse> createUser(
            @RequestBody UserCreateRequest request,
            @AuthenticationPrincipal Jwt jwt) {

        UUID currentUserId = UUID.fromString(jwt.getSubject());
        UserResponse response = userService.createUser(request, currentUserId);

        return new ResponseEntity<>(response, HttpStatus.CREATED);
    }

    /**
     * API Lấy danh sách toàn bộ người dùng trong hệ thống.
     * Thường được sử dụng cho màn hình Quản lý danh sách khách thuê của Chủ trọ.
     *
     * @return Danh sách các UserResponse
     */
    @GetMapping
    @PreAuthorize("hasAuthority('SCOPE_LANDLORD')")
    public ResponseEntity<List<UserResponse>> getAllUsers() {
        return ResponseEntity.ok(userService.getAllUsers());
    }

    /**
     * API Lấy thông tin chi tiết của một người dùng dựa vào ID.
     *
     * @param id Mã định danh UUID của người dùng cần tra cứu
     * @return UserResponse Thông tin chi tiết của người dùng tương ứng
     */
    @GetMapping("/{id}")
    @PreAuthorize("hasAuthority('SCOPE_LANDLORD')")
    public ResponseEntity<UserResponse> getUserById(@PathVariable UUID id) {
        return ResponseEntity.ok(userService.getUserById(id));
    }

    /**
     * API Xem hồ sơ cá nhân của chính người đang đăng nhập (Current User).
     * Bảo mật cao do định danh người dùng được lấy trực tiếp từ chữ ký Token của Server.
     *
     * @param jwt Token xác thực của phiên đăng nhập hiện tại
     * @return UserResponse Thông tin hồ sơ của người đang đăng nhập
     */
    @GetMapping("/current")
    @PreAuthorize("hasAuthority('SCOPE_LANDLORD')")
    public ResponseEntity<UserResponse> getCurrentUser(@AuthenticationPrincipal Jwt jwt) {
        UUID currentUserId = UUID.fromString(jwt.getSubject());
        return ResponseEntity.ok(userService.getUserById(currentUserId));
    }

    /**
     * API Cập nhật thông tin người dùng (Hỗ trợ Partial Update).
     * - Có thể đổi Số điện thoại (Có kiểm tra chống trùng lặp).
     * - Có thể đổi hoặc cấp lại Mật khẩu mới (Tự động mã hóa).
     * - Các trường để trống hoặc null sẽ được giữ nguyên giá trị cũ.
     * - Lưu lại vết thao tác (Activity Log).
     *
     * @param id Mã định danh UUID của người dùng cần được cập nhật
     * @param request Payload chứa các thông tin muốn thay đổi
     * @param jwt Token xác thực chứa ID của người đang thực hiện lệnh sửa
     * @return UserResponse Thông tin người dùng sau khi đã cập nhật thành công
     */
    @PutMapping("/{id}")
    @PreAuthorize("hasAuthority('SCOPE_LANDLORD')")
    public ResponseEntity<UserResponse> updateUser(
            @PathVariable UUID id,
            @RequestBody UserUpdateRequest request,
            @AuthenticationPrincipal Jwt jwt) {

        UUID currentUserId = UUID.fromString(jwt.getSubject());
        UserResponse response = userService.updateUser(id, request, currentUserId);

        return ResponseEntity.ok(response);
    }

    /**
     * API Xóa tài khoản người dùng vĩnh viễn khỏi hệ thống.
     * Sẽ trích xuất Số điện thoại và Vai trò của người bị xóa để ghi vào Activity Log.
     *
     * @param id Mã định danh UUID của tài khoản cần xóa
     * @param jwt Token xác thực chứa ID của người đang thực hiện lệnh xóa
     * @return Thông báo String xác nhận thao tác thành công
     */
    @DeleteMapping("/{id}")
    @PreAuthorize("hasAuthority('SCOPE_LANDLORD')")
    public ResponseEntity<String> deleteUser(
            @PathVariable UUID id,
            @AuthenticationPrincipal Jwt jwt) {

        UUID currentUserId = UUID.fromString(jwt.getSubject());
        userService.deleteUser(id, currentUserId);

        return ResponseEntity.ok("Xóa tài khoản người dùng thành công");
    }
}