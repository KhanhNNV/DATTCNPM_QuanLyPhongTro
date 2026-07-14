package ut.edu.be_quanlytro.Repository;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import ut.edu.be_quanlytro.Entity.Notification;

import java.util.List;
import java.util.UUID;

public interface NotificationRepository extends JpaRepository<Notification, UUID> {

    //  Lấy danh sách thông báo của 1 user
    Page<Notification> findByUserIdOrderByCreatedAtDesc(UUID userId, Pageable pageable);

    //  Đếm số lượng thông báo chưa đọc của 1 user
    long countByUserIdAndIsReadFalse(UUID userId);
    // Lấy ra một danh sách (List) các thông báo CHƯA ĐỌC của user
    List<Notification> findByUserIdAndIsReadFalse(UUID userId);
}