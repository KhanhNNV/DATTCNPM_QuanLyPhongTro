package ut.edu.be_quanlytro.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ut.edu.be_quanlytro.Entity.ActivityLog;
import ut.edu.be_quanlytro.Entity.User;
import ut.edu.be_quanlytro.Repository.ActivityLogRepository;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class ActivityLogService {

    private final ActivityLogRepository activityLogRepository;

    @Transactional
    public void createLog(User user, String action, String entityName, UUID entityId, String description) {
        ActivityLog log = ActivityLog.builder()
                .user(user)
                .action(action)
                .entityName(entityName)
                .entityId(entityId)
                .description(description)
                .build();

        activityLogRepository.save(log);
    }
}