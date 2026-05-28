package ut.edu.be_quanlytro.Controller;

import ut.edu.be_quanlytro.Dto.Request.LoginRequest;
import ut.edu.be_quanlytro.Dto.Request.RegisterRequest;
import ut.edu.be_quanlytro.Dto.Response.LoginResponse;
import ut.edu.be_quanlytro.Entity.User;
import ut.edu.be_quanlytro.Repository.UserRepository;
import ut.edu.be_quanlytro.Service.Auth.AuthenticationService;
import ut.edu.be_quanlytro.Service.Auth.JwtService;
import ut.edu.be_quanlytro.Service.Auth.TokenBlacklistService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseCookie;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthenticationService authenticationService;
    private final JwtService jwtService;
    private final TokenBlacklistService tokenBlacklistService;
    private final UserRepository userRepository;

    @PostMapping("/login")
    public ResponseEntity<LoginResponse> login(@RequestBody LoginRequest request) {
        // Gọi service xử lý đăng nhập bằng SĐT và kẹp ID trọ vào Access Token
        LoginResponse response = authenticationService.login(request);

        // Đóng gói Refresh Token vào HttpOnly Cookie để chống tấn công XSS lấy cắp token
        ResponseCookie refreshTokenCookie = ResponseCookie.from("refreshToken", response.getRefreshToken())
                .httpOnly(true)
                .secure(false) // Để false nếu test ở localhost (HTTP), đổi thành true khi deploy production (HTTPS)
                .path("/")
                .maxAge(30 * 24 * 60 * 60) // Hạn định 30 ngày giống thiết kế cũ
                .sameSite("Strict")
                .build();

        // Ẩn Refresh Token ở phần Body trả về, chỉ cho Frontend thấy Access Token nhằm tăng tính bảo mật
        response.setRefreshToken(null);

        return ResponseEntity.ok()
                .header(HttpHeaders.SET_COOKIE, refreshTokenCookie.toString())
                .body(response);
    }

    @PostMapping("/refresh")
    public ResponseEntity<LoginResponse> refresh(
            @CookieValue(name = "refreshToken", required = false) String refreshToken) {

        try {
            // Kiểm tra tính hợp lệ và thời hạn của Refresh Token trong Cookie
            if (refreshToken == null || !jwtService.verifyToken(refreshToken)) {
                return ResponseEntity.status(403).build(); // 403 Forbidden
            }

            // Trích xuất SĐT (Subject) từ token cũ ra thay vì email như dự án cũ
            String phone = jwtService.extractPhone(refreshToken);
            User user = userRepository.findByPhone(phone)
                    .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng hệ thống"));

            // Tạo Access Token mới (Lưu ý: Luồng đơn giản này chưa kẹp lại areaId/roomId,
            // nếu cần thiết bạn có thể gọi lại logic tìm kiếm hợp đồng như ở AuthenticationService)
            String newAccessToken = jwtService.generateAccessToken(user, null, null);

            return ResponseEntity.ok(LoginResponse.builder().accessToken(newAccessToken).build());
        } catch (Exception e) {
            return ResponseEntity.status(403).build();
        }
    }

    @PostMapping("/logout")
    public ResponseEntity<Void> logout(
            HttpServletRequest request,
            @CookieValue(name = "refreshToken", required = false) String refreshToken) {

        // 1. Lấy Access Token từ Header "Authorization: Bearer <token>" để đưa vào Redis Blacklist
        String authHeader = request.getHeader(HttpHeaders.AUTHORIZATION);
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            String accessToken = authHeader.substring(7);
            tokenBlacklistService.addToBlacklist(accessToken);
        }

        // 2. Đưa luôn Refresh Token hiện tại vào Redis Blacklist để hủy hoàn toàn phiên làm việc
        if (refreshToken != null && !refreshToken.isEmpty()) {
            tokenBlacklistService.addToBlacklist(refreshToken);
        }

        // 3. Tiến hành xóa bỏ Cookie lưu Refresh Token ở phía Client (Trình duyệt/Mobile) bằng cách set maxAge = 0
        ResponseCookie cleanCookie = ResponseCookie.from("refreshToken", "")
                .httpOnly(true)
                .secure(false)
                .path("/")
                .maxAge(0) // Hết hạn ngay lập tức
                .build();

        return ResponseEntity.ok()
                .header(HttpHeaders.SET_COOKIE, cleanCookie.toString())
                .build();
    }

    @PostMapping("/register")
    public ResponseEntity<String> register(@RequestBody RegisterRequest request) {
        try {
            authenticationService.register(request);
            return ResponseEntity.ok("Đăng ký tài khoản Khách thuê thành công!");
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());

        }
    }
}