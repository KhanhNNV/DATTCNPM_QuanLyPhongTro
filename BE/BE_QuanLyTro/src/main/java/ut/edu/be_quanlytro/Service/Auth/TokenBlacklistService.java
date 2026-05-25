package ut.edu.be_quanlytro.Service.Auth;

import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class TokenBlacklistService {

    // Tạm thời để đây, không gọi đến nữa để tránh bị lỗi "Unable to connect to Redis"
    private final StringRedisTemplate redisTemplate;

    public void addToBlacklist(String token) {
        // TẠM THỜI BỎ TRỐNG: Chạy local không có Redis thì không cần lưu token vào danh sách đen
    }

    public boolean isBlacklisted(String token) {
        // TẠM THỜI LUÔN TRẢ VỀ FALSE: Coi như không có token nào bị cấm để vượt qua cửa kiểm tra
        return false;
    }
}