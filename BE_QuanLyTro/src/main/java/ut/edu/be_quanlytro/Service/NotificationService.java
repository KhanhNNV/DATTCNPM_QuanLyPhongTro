package ut.edu.be_quanlytro.Service;

import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.scheduling.annotation.Async;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import ut.edu.be_quanlytro.Dto.Response.NotificationResponse;
import ut.edu.be_quanlytro.Dto.Response.PageResponse;
import ut.edu.be_quanlytro.Entity.Enum.NotificationType;
import ut.edu.be_quanlytro.Entity.Notification;
import ut.edu.be_quanlytro.Entity.User;
import ut.edu.be_quanlytro.Entity.UserFcmToken;
import ut.edu.be_quanlytro.Exception.ResourceNotFoundException;
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

    @Async
    @Transactional
    public void createNotification(User user, String title, String content, NotificationType type) {
        Notification notification = Notification.builder()
                .user(user)
                .title(title)
                .content(content)
                .type(type)
                .isRead(false)
                .build();

        Notification savedNotification = notificationRepository.save(notification);

        sendNotificationToUser(user.getId(), title, content);
    }

    @Transactional(readOnly = true)
    public PageResponse<NotificationResponse> getMyNotifications(UUID userId, int page, int size) {
        Pageable pageable = PageRequest.of(page, size);

        Page<Notification> notificationPage = notificationRepository.findByUserIdOrderByCreatedAtDesc(userId, pageable);

        List<NotificationResponse> content = notificationPage.getContent().stream()
                .map(this::mapToResponse)
                .toList();

        return PageResponse.<NotificationResponse>builder()
                .content(content)
                .pageNumber(notificationPage.getNumber())
                .pageSize(notificationPage.getSize())
                .totalElements(notificationPage.getTotalElements())
                .totalPages(notificationPage.getTotalPages())
                .isLast(notificationPage.isLast())
                .build();
    }

    @Transactional(readOnly = true)
    public long getUnreadCount(UUID userId) {
        return notificationRepository.countByUserIdAndIsReadFalse(userId);
    }

    @Transactional
    public void markAsRead(UUID notificationId, UUID userId) {
        Notification notification = notificationRepository.findById(notificationId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy thông báo"));

        if (!notification.getUser().getId().equals(userId)) {
            throw new AccessDeniedException("Bạn không có quyền thao tác trên thông báo này");
        }

        notification.setIsRead(true);
        notificationRepository.save(notification);
    }

    @Transactional
    public void markAllAsRead(UUID userId) {
        List<Notification> unreadList = notificationRepository.findByUserIdAndIsReadFalse(userId);

        if (!unreadList.isEmpty()) {
            unreadList.forEach(n -> n.setIsRead(true));
            notificationRepository.saveAll(unreadList);
        }
    }

    @Transactional
    public void saveFcmToken(UUID userId, String token) {
        User currentUser = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy User!"));

        var existingTokenOpt = fcmTokenRepository.findByFcmToken(token);

        if (existingTokenOpt.isPresent()) {
            UserFcmToken existingToken = existingTokenOpt.get();

            if (!existingToken.getUser().getId().equals(userId)) {
                existingToken.setUser(currentUser);
                fcmTokenRepository.save(existingToken);
                System.out.println(" Đã CẬP NHẬT chủ sở hữu FCM Token cho User: " + currentUser.getPhone());
            } else {
                System.out.println("FCM Token đã tồn tại và đúng chủ sở hữu: " + currentUser.getPhone());
            }
        } else {
            UserFcmToken newToken = UserFcmToken.builder()
                    .user(currentUser)
                    .fcmToken(token)
                    .build();
            fcmTokenRepository.save(newToken);
            System.out.println(" Đã LƯU MỚI FCM Token cho User: " + currentUser.getPhone());
        }
    }

    public void sendPushNotification(String fcmToken, String title, String body) {
        try {
            com.google.firebase.messaging.Notification firebaseNotification = com.google.firebase.messaging.Notification.builder()
                    .setTitle(title)
                    .setBody(body)
                    .build();

            Message message = Message.builder()
                    .setToken(fcmToken)
                    .setNotification(firebaseNotification)
                    .setAndroidConfig(com.google.firebase.messaging.AndroidConfig.builder()
                            .setPriority(com.google.firebase.messaging.AndroidConfig.Priority.HIGH)
                            .setNotification(com.google.firebase.messaging.AndroidNotification.builder()
                                    .setChannelId("high_importance_channel")
                                    .build())
                            .build())
                    .build();

            String response = FirebaseMessaging.getInstance().send(message);
            System.out.println(" Đã bắn FCM thành công tới thiết bị: " + response);
        } catch (Exception e) {
            System.err.println(" Lỗi bắn thông báo FCM: " + e.getMessage());
        }
    }

    public void sendNotificationToUser(UUID userId, String title, String body) {
        List<UserFcmToken> tokens = fcmTokenRepository.findByUserId(userId);

        for (UserFcmToken token : tokens) {
            sendPushNotification(token.getFcmToken(), title, body);
        }
    }

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