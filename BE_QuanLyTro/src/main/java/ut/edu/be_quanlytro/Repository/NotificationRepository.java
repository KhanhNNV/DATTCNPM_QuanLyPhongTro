package ut.edu.be_quanlytro.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import ut.edu.be_quanlytro.Entity.Notification;
import java.util.UUID;

public interface NotificationRepository extends JpaRepository<Notification, UUID> {
}