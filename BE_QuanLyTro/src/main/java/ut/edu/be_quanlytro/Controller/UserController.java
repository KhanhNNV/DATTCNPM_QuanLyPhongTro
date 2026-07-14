package ut.edu.be_quanlytro.Controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import ut.edu.be_quanlytro.Dto.Request.BankInfoUpdateRequest;
import ut.edu.be_quanlytro.Dto.Request.PasswordChangeRequest;
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

    @GetMapping("/area/{areaId}")
    @PreAuthorize("hasRole('LANDLORD')")
    public ResponseEntity<List<UserResponse>> getUsersByArea(
            @PathVariable UUID areaId,
            @AuthenticationPrincipal Jwt jwt) {

        UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));

        List<UserResponse> tenants = userService.getUsersByArea(areaId, currentUserId);

        return ResponseEntity.ok(tenants);
    }

    @GetMapping("/current")
    @PreAuthorize("hasAnyRole('LANDLORD', 'TENANT')")
    public ResponseEntity<UserResponse> getCurrentUser(@AuthenticationPrincipal Jwt jwt) {

        UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));

        return ResponseEntity.ok(userService.getUserById(currentUserId, currentUserId));
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasRole('LANDLORD')")
    public ResponseEntity<UserResponse> getUserById(
            @PathVariable UUID id,
            @AuthenticationPrincipal Jwt jwt) {

        UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));

        return ResponseEntity.ok(userService.getUserById(id, currentUserId));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('LANDLORD')")
    public ResponseEntity<UserResponse> updateUser(
            @PathVariable UUID id,
            @RequestBody UserUpdateRequest request,
            @AuthenticationPrincipal Jwt jwt) {

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

        UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));

        String signatureUrl = userService.getSignature(currentUserId);

        return ResponseEntity.ok(Map.of(
                "signatureUrl", signatureUrl != null ? signatureUrl : ""
        ));
    }

    @PutMapping("/profile/bank-info")
    @PreAuthorize("hasRole('LANDLORD')")
    public ResponseEntity<?> updateBankInfo(
            @RequestBody BankInfoUpdateRequest request,
            @AuthenticationPrincipal Jwt jwt
    ) {
        try {

            UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));

            userService.updateBankInfo(currentUserId, request);

            return ResponseEntity.ok("Cập nhật thông tin ngân hàng thành công!");
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @PutMapping("/current/password")
    @PreAuthorize("hasAnyRole('LANDLORD', 'TENANT')")
    public ResponseEntity<?> changePassword(
            @RequestBody PasswordChangeRequest request,
            @AuthenticationPrincipal Jwt jwt) {

        try {
            UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));

            userService.changePassword(currentUserId, request);

            return ResponseEntity.ok(Map.of("message", "Cập nhật mật khẩu thành công!"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }
}