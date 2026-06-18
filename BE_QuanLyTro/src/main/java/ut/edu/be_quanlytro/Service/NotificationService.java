package ut.edu.be_quanlytro.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
// import org.springframework.messaging.simp.SimpMessagingTemplate; // 🌟 Mở ra khi dùng WebSocket

import ut.edu.be_quanlytro.Dto.Response.NotificationResponse;
import ut.edu.be_quanlytro.Entity.Enum.NotificationType;
import ut.edu.be_quanlytro.Entity.Notification;
import ut.edu.be_quanlytro.Entity.User;
import ut.edu.be_quanlytro.Repository.NotificationRepository;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class NotificationService {

    private final NotificationRepository notificationRepository;

    // Tiêm công cụ bắn dữ liệu Real-time (WebSocket)
    // private final SimpMessagingTemplate messagingTemplate; // 🌟 Mở ra khi cấu hình xong WebSocket

    // ================= 1. HÀM TẠO & ĐẨY THÔNG BÁO (REAL-TIME) =================
    @Transactional
    public void createNotification(User user, String title, String content, NotificationType type) {

        // 1. Khởi tạo đối tượng
        Notification notification = Notification.builder()
                .user(user)
                .title(title)
                .content(content)
                .type(type)
                .isRead(false)
                .build();

        // 2. Lưu xuống Database
        Notification savedNotification = notificationRepository.save(notification);

        // 3. 🚀 ĐẨY DỮ LIỆU THỜI GIAN THỰC LÊN FRONTEND (Mô hình Push)
        // Khi cấu hình xong WebSocket, mở comment dòng dưới đây:
        // messagingTemplate.convertAndSendToUser(
        //         user.getId().toString(),
        //         "/queue/notifications",
        //         mapToResponse(savedNotification)
        // );
    }

    // ================= 2. LẤY DANH SÁCH THÔNG BÁO =================
    @Transactional(readOnly = true)
    public List<NotificationResponse> getMyNotifications(UUID userId) {
        return notificationRepository.findByUserIdOrderByCreatedAtDesc(userId)
                .stream()
                .map(this::mapToResponse)
                .toList();
    }

    // ================= 3. ĐẾM SỐ THÔNG BÁO CHƯA ĐỌC =================
    @Transactional(readOnly = true)
    public long getUnreadCount(UUID userId) {
        return notificationRepository.countByUserIdAndIsReadFalse(userId);
    }

    // ================= 4. ĐÁNH DẤU LÀ ĐÃ ĐỌC =================
    @Transactional
    public void markAsRead(UUID notificationId, UUID userId) {
        Notification notification = notificationRepository.findById(notificationId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy thông báo"));

        // Chốt chặn: Chỉ chủ nhân của thông báo mới được đánh dấu đọc
        if (!notification.getUser().getId().equals(userId)) {
            throw new RuntimeException("Bạn không có quyền thao tác trên thông báo này");
        }

        notification.setIsRead(true);
        notificationRepository.save(notification);
    }

    // ================= 5. ĐÁNH DẤU TẤT CẢ LÀ ĐÃ ĐỌC (Tặng thêm) =================
    @Transactional
    public void markAllAsRead(UUID userId) {
        List<Notification> unreadList = notificationRepository.findByUserIdOrderByCreatedAtDesc(userId).stream()
                .filter(n -> !n.getIsRead())
                .toList();

        unreadList.forEach(n -> n.setIsRead(true));
        notificationRepository.saveAll(unreadList);
    }

    // ================= MAPPER =================
    private NotificationResponse mapToResponse(Notification notification) {
        return NotificationResponse.builder()
                .id(notification.getId())
                .title(notification.getTitle())
                .content(notification.getContent())
                .type(notification.getType())
                .isRead(notification.getIsRead())
                .createdAt(notification.getCreatedAt())
                .build();
    }
}