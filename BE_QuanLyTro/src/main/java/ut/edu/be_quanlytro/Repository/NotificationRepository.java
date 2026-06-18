package ut.edu.be_quanlytro.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import ut.edu.be_quanlytro.Entity.Notification;

import java.util.List;
import java.util.UUID;

public interface NotificationRepository extends JpaRepository<Notification, UUID> {

    // 1. Lấy danh sách thông báo của 1 user, mới nhất xếp lên đầu
    List<Notification> findByUserIdOrderByCreatedAtDesc(UUID userId);

    // 2. Đếm số lượng thông báo chưa đọc (isRead = false) của 1 user
    long countByUserIdAndIsReadFalse(UUID userId);
}