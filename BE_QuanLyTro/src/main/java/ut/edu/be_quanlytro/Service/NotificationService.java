package ut.edu.be_quanlytro.Service;

import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.scheduling.annotation.Async;
import org.springframework.security.access.AccessDeniedException; // Thêm import 403
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
// import org.springframework.messaging.simp.SimpMessagingTemplate; // 🌟 Mở ra khi dùng WebSocket

import ut.edu.be_quanlytro.Dto.Response.NotificationResponse;
import ut.edu.be_quanlytro.Dto.Response.PageResponse;
import ut.edu.be_quanlytro.Entity.Enum.NotificationType;
import ut.edu.be_quanlytro.Entity.Notification;
import ut.edu.be_quanlytro.Entity.User;
import ut.edu.be_quanlytro.Entity.UserFcmToken;
import ut.edu.be_quanlytro.Exception.ResourceNotFoundException; // Thêm import 404
import ut.edu.be_quanlytro.Repository.NotificationRepository;
import ut.edu.be_quanlytro.Repository.UserFcmTokenRepository;
import ut.edu.be_quanlytro.Repository.UserRepository;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final UserFcmTokenRepository fcmTokenRepository;
    private final UserRepository userRepository;

    // Tiêm công cụ bắn dữ liệu Real-time (WebSocket)
    // private final SimpMessagingTemplate messagingTemplate; // 🌟 Mở ra khi cấu hình xong WebSocket

    // ================= 1. HÀM TẠO & ĐẨY THÔNG BÁO (REAL-TIME) =================
    @Async
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
        // 4.  FIREBASE TỰ ĐỘNG NGAY TẠI ĐÂY!
        // Lưu DB xong là tự động móc token ra bắn popup rung điện thoại luôn
        sendNotificationToUser(user.getId(), title, content);
    }

    // ================= 2. LẤY DANH SÁCH THÔNG BÁO =================
    @Transactional(readOnly = true)
    public PageResponse<NotificationResponse> getMyNotifications(UUID userId, int page, int size) {
        Pageable pageable = PageRequest.of(page, size);

        // Gọi xuống DB lấy đúng 1 trang dữ liệu
        Page<Notification> notificationPage = notificationRepository.findByUserIdOrderByCreatedAtDesc(userId, pageable);

        // Map sang DTO
        List<NotificationResponse> content = notificationPage.getContent().stream()
                .map(this::mapToResponse)
                .toList();

        // Bọc vào khuôn PageResponse xịn xò
        return PageResponse.<NotificationResponse>builder()
                .content(content)
                .pageNumber(notificationPage.getNumber())
                .pageSize(notificationPage.getSize())
                .totalElements(notificationPage.getTotalElements())
                .totalPages(notificationPage.getTotalPages())
                .isLast(notificationPage.isLast())
                .build();
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
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy thông báo"));

        // Chốt chặn: Chỉ chủ nhân của thông báo mới được đánh dấu đọc
        if (!notification.getUser().getId().equals(userId)) {
            throw new AccessDeniedException("Bạn không có quyền thao tác trên thông báo này");
        }

        notification.setIsRead(true);
        notificationRepository.save(notification);
    }


    // ================= 5. ĐÁNH DẤU TẤT CẢ LÀ ĐÃ ĐỌC =================
    @Transactional
    public void markAllAsRead(UUID userId) {
        // Lấy đúng những thông báo chưa đọc từ DB lên (Tối ưu RAM)
        List<Notification> unreadList = notificationRepository.findByUserIdAndIsReadFalse(userId);

        // Nếu có thông báo chưa đọc thì mới xử lý
        if (!unreadList.isEmpty()) {
            unreadList.forEach(n -> n.setIsRead(true));
            notificationRepository.saveAll(unreadList);
        }
    }

    /**
     * LƯU FCM TOKEN CỦA THIẾT BỊ VÀO DATABASE
     */
    @Transactional
    public void saveFcmToken(UUID userId, String token) {
        // 1. Tìm User hiện tại đang đăng nhập
        User currentUser = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy User!"));

        // 2. Tìm xem Token này đã nằm trong DB chưa
        var existingTokenOpt = fcmTokenRepository.findByFcmToken(token);

        if (existingTokenOpt.isPresent()) {
            UserFcmToken existingToken = existingTokenOpt.get();

            // Nếu Token này đang bị gán cho một User KHÁC (VD: nick cũ chưa đăng xuất)
            if (!existingToken.getUser().getId().equals(userId)) {
                existingToken.setUser(currentUser); // Chuyển chủ cho Token
                fcmTokenRepository.save(existingToken);
                System.out.println("🔄 Đã CẬP NHẬT chủ sở hữu FCM Token cho User: " + currentUser.getPhone());
            } else {
                System.out.println("✅ FCM Token đã tồn tại và đúng chủ sở hữu: " + currentUser.getPhone());
            }
        } else {
            // 3. Nếu Token hoàn toàn mới chưa từng có trong DB -> Lưu mới
            UserFcmToken newToken = UserFcmToken.builder()
                    .user(currentUser)
                    .fcmToken(token)
                    .build();
            fcmTokenRepository.save(newToken);
            System.out.println("🚀 Đã LƯU MỚI FCM Token cho User: " + currentUser.getPhone());
        }
    }
    /**
     * 1. HÀM CƠ BẢN: BẮN THÔNG BÁO TỚI 1 THIẾT BỊ (TOKEN)
     */
    /**
     * 1. HÀM CƠ BẢN: BẮN THÔNG BÁO TỚI 1 THIẾT BỊ (TOKEN)
     */
    public void sendPushNotification(String fcmToken, String title, String body) {
        try {
            com.google.firebase.messaging.Notification firebaseNotification = com.google.firebase.messaging.Notification.builder()
                    .setTitle(title)
                    .setBody(body)
                    .build();

            Message message = Message.builder()
                    .setToken(fcmToken)
                    .setNotification(firebaseNotification)
                    // 🔴 CẤU HÌNH BẮT BUỘC CHO ANDROID ĐỂ HIỆN BIỂU NGỮ (POP-UP)
                    .setAndroidConfig(com.google.firebase.messaging.AndroidConfig.builder()
                            .setPriority(com.google.firebase.messaging.AndroidConfig.Priority.HIGH) // Bắt buộc là HIGH
                            .setNotification(com.google.firebase.messaging.AndroidNotification.builder()
                                    .setChannelId("high_importance_channel") // Khớp với ID kênh trong Flutter
                                    .build())
                            .build())
                    .build();

            String response = FirebaseMessaging.getInstance().send(message);
            System.out.println("✅ Đã bắn FCM thành công tới thiết bị: " + response);
        } catch (Exception e) {
            System.err.println("❌ Lỗi bắn thông báo FCM: " + e.getMessage());
        }
    }

    /**
     * 2. HÀM NÂNG CAO: TÌM TẤT CẢ THIẾT BỊ CỦA KHÁCH THUÊ ĐỂ BẮN
     * (Dùng hàm này để gọi ở các chỗ duyệt hóa đơn)
     */
    public void sendNotificationToUser(UUID userId, String title, String body) {
        // Lấy danh sách tất cả điện thoại/tablet mà Khách thuê đang đăng nhập
        List<UserFcmToken> tokens = fcmTokenRepository.findByUserId(userId);

        // Quét vòng lặp: Có bao nhiêu máy đang đăng nhập thì bắn thông báo hết!
        for (UserFcmToken token : tokens) {
            sendPushNotification(token.getFcmToken(), title, body);
        }
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