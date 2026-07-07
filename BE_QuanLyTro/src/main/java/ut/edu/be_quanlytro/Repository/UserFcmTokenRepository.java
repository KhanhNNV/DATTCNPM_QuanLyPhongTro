package ut.edu.be_quanlytro.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import ut.edu.be_quanlytro.Entity.UserFcmToken;

import java.util.List;
import java.util.UUID;

@Repository
public interface UserFcmTokenRepository extends JpaRepository<UserFcmToken, UUID> {

    // 1. Tìm tất cả các Token của 1 người dùng (Vì 1 người có thể xài nhiều điện thoại)
    List<UserFcmToken> findByUserId(UUID userId);

    // 2. Kiểm tra xem Token này đã có trong DB chưa (Để tránh việc user mở app nó lưu trùng data)
    boolean existsByFcmToken(String fcmToken);

    // 3. Xóa Token khi người dùng Đăng xuất (Tránh việc đăng xuất rồi mà máy vẫn kêu ting ting)
    void deleteByFcmToken(String fcmToken);
}