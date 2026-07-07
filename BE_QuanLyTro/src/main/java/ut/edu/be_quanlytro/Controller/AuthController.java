package ut.edu.be_quanlytro.Controller;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import ut.edu.be_quanlytro.Dto.Request.ChangePasswordRequest;
import ut.edu.be_quanlytro.Dto.Request.LoginRequest;
import ut.edu.be_quanlytro.Dto.Request.RefreshTokenRequest;
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
import org.springframework.security.oauth2.jwt.Jwt;
import ut.edu.be_quanlytro.Service.NotificationService;

import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthenticationService authenticationService;
    private final NotificationService notificationService;

    @PostMapping("/login")
    public ResponseEntity<LoginResponse> login(@RequestBody LoginRequest request) {
        // Gọi Service để tạo ra object chứa cả Access Token và Refresh Token
        LoginResponse response = authenticationService.login(request);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/refresh")
    public ResponseEntity<?> refresh(@RequestBody RefreshTokenRequest request) { // Dùng Body thay vì Cookie
        try {
            LoginResponse response = authenticationService.refreshToken(request.getRefreshToken());
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.status(403).body(e.getMessage());
        }
    }

    @PostMapping("/logout")
    public ResponseEntity<String> logout(
            HttpServletRequest request,
            @RequestBody(required = false) RefreshTokenRequest refreshTokenRequest) {

        String accessToken = null;
        String authHeader = request.getHeader(HttpHeaders.AUTHORIZATION);
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            accessToken = authHeader.substring(7);
        }

        String refreshToken = null;
        if (refreshTokenRequest != null) {
            refreshToken = refreshTokenRequest.getRefreshToken();
        }
        authenticationService.logout(accessToken, refreshToken);

        return ResponseEntity.ok("Đăng xuất thành công, Token đã bị vô hiệu hóa!");
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
    @PostMapping("/change-password")
    public ResponseEntity<String> changePassword(
            @RequestBody ChangePasswordRequest request,
            @AuthenticationPrincipal Jwt jwt) {

        try {
            String phone = jwt.getSubject();
            authenticationService.changePassword(request, phone);

            return ResponseEntity.ok("Đổi mật khẩu thành công! Tài khoản của bạn đã được kích hoạt.");
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    @PostMapping("/fcm-token")
    public ResponseEntity<?> saveFcmToken(@RequestBody Map<String, String> request, @AuthenticationPrincipal Jwt jwt) {
        UUID userId = UUID.fromString(jwt.getClaimAsString("userId"));
        String token = request.get("token");

        // Logic: Kiểm tra nếu user chưa có token này dưới DB thì lưu mới vào bảng user_fcm_tokens
        notificationService.saveFcmToken(userId, token);

        return ResponseEntity.ok(Map.of("message", "Lưu FCM Token thành công!"));
    }
}