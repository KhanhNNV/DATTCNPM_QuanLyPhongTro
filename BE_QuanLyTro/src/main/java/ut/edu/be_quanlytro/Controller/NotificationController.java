package ut.edu.be_quanlytro.Controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;
import ut.edu.be_quanlytro.Dto.Response.NotificationResponse;
import ut.edu.be_quanlytro.Dto.Response.PageResponse;
import ut.edu.be_quanlytro.Service.NotificationService;

import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationService notificationService;

    // 1. Lấy danh sách thông báo (Phân trang)
    @GetMapping
    @PreAuthorize("hasAnyRole('TENANT', 'LANDLORD')") // Chủ trọ hay Khách thuê đều có quyền xem
    public ResponseEntity<PageResponse<NotificationResponse>> getMyNotifications(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @AuthenticationPrincipal Jwt jwt) {

        UUID userId = UUID.fromString(jwt.getClaimAsString("userId"));
        PageResponse<NotificationResponse> response = notificationService.getMyNotifications(userId, page, size);
        return ResponseEntity.ok(response);
    }

    // 2. Lấy số lượng thông báo chưa đọc (Để FE hiện con số màu đỏ trên icon chuông)
    @GetMapping("/unread-count")
    @PreAuthorize("hasAnyRole('TENANT', 'LANDLORD')")
    public ResponseEntity<?> getUnreadCount(@AuthenticationPrincipal Jwt jwt) {
        UUID userId = UUID.fromString(jwt.getClaimAsString("userId"));
        long count = notificationService.getUnreadCount(userId);
        return ResponseEntity.ok(Map.of("unreadCount", count));
    }

    // 3. Đánh dấu 1 thông báo là đã đọc (Khi user click vào thông báo)
    @PutMapping("/{id}/read")
    @PreAuthorize("hasAnyRole('TENANT', 'LANDLORD')")
    public ResponseEntity<String> markAsRead(
            @PathVariable UUID id,
            @AuthenticationPrincipal Jwt jwt) {

        UUID userId = UUID.fromString(jwt.getClaimAsString("userId"));
        notificationService.markAsRead(id, userId);
        return ResponseEntity.ok("Đã đánh dấu đọc!");
    }

    // 4. Đánh dấu TẤT CẢ thông báo là đã đọc (Nút "Mark all as read")
    @PutMapping("/read-all")
    @PreAuthorize("hasAnyRole('TENANT', 'LANDLORD')")
    public ResponseEntity<String> markAllAsRead(@AuthenticationPrincipal Jwt jwt) {

        UUID userId = UUID.fromString(jwt.getClaimAsString("userId"));
        notificationService.markAllAsRead(userId);
        return ResponseEntity.ok("Đã đánh dấu đọc tất cả!");
    }
}