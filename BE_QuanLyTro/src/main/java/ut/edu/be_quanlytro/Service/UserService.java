package ut.edu.be_quanlytro.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;
import ut.edu.be_quanlytro.Dto.Request.UserCreateRequest;
import ut.edu.be_quanlytro.Dto.Request.UserUpdateRequest;
import ut.edu.be_quanlytro.Dto.Response.UserResponse;
import ut.edu.be_quanlytro.Entity.User;
import ut.edu.be_quanlytro.Repository.UserRepository;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final ActivityLogService activityLog;

    // ================= CREATE =================
    @Transactional
    public UserResponse createUser(UserCreateRequest request, UUID currentUserId) {
        if (userRepository.existsByPhone(request.getPhone())) {
            throw new RuntimeException("Số điện thoại này đã được đăng ký!");
        }

        User user = User.builder()
                .phone(request.getPhone())
                .password(passwordEncoder.encode(request.getPassword())) // Băm mật khẩu
                .role(request.getRole())
                .fullName(request.getFullName())
                .dob(request.getDob())
                .hometown(request.getHometown())
                .isFirstLogin(true) // Mặc định là true
                .build();

        User savedUser = userRepository.save(user);

        // GHI LOG CREATE
        User userProxy = userRepository.getReferenceById(currentUserId);
        String action = "CREATE_USER";
        String entityName = "users";
        String description = String.format("Tạo mới tài khoản %s (SĐT: %s) với vai trò %s",
                savedUser.getFullName() != null ? savedUser.getFullName() : "chưa cập nhật tên",
                savedUser.getPhone(),
                savedUser.getRole().name());

        activityLog.createLog(userProxy, action, entityName, savedUser.getId(), description);

        return mapToResponse(savedUser);
    }

    // ================= READ =================
    public UserResponse getUserById(UUID id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng"));
        return mapToResponse(user);
    }

    public List<UserResponse> getAllUsers() {
        return userRepository.findAll()
                .stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    // ================= UPDATE =================
    @Transactional
    public UserResponse updateUser(UUID id, UserUpdateRequest request, UUID currentUserId) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng"));

        // 1. Xử lý cập nhật Số điện thoại (Tên đăng nhập)
        if (StringUtils.hasText(request.getPhone())) {
            String newPhone = request.getPhone().trim();
            // Chỉ kiểm tra trùng nếu số điện thoại mới KHÁC với số điện thoại cũ
            if (!user.getPhone().equals(newPhone)) {
                if (userRepository.existsByPhone(newPhone)) {
                    throw new RuntimeException("Số điện thoại mới này đã tồn tại trong hệ thống!");
                }
                user.setPhone(newPhone);
            }
        }

        // 2. Xử lý cập nhật/cấp lại Mật khẩu
        if (StringUtils.hasText(request.getPassword())) {
            // TUYỆT ĐỐI KHÔNG lưu plain-text, BẮT BUỘC phải băm mã hóa lại
            user.setPassword(passwordEncoder.encode(request.getPassword()));
        }

        // 3. Xử lý các trường thông tin cơ bản khác (Như cũ)
        if (StringUtils.hasText(request.getFullName())) {
            user.setFullName(request.getFullName().trim());
        }

        if (request.getDob() != null) {
            user.setDob(request.getDob());
        }

        if (StringUtils.hasText(request.getHometown())) {
            user.setHometown(request.getHometown().trim());
        }

        User updatedUser = userRepository.save(user);

        // GHI LOG UPDATE
        User userProxy = userRepository.getReferenceById(currentUserId);
        String action = "UPDATE_USER";
        String entityName = "users";
        String description = String.format("Cập nhật thông tin tài khoản của %s (SĐT hiện tại: %s)",
                updatedUser.getFullName() != null ? updatedUser.getFullName() : "khách",
                updatedUser.getPhone());

        activityLog.createLog(userProxy, action, entityName, updatedUser.getId(), description);

        return mapToResponse(updatedUser);
    }

    // ================= DELETE =================
    @Transactional
    public void deleteUser(UUID id, UUID currentUserId) {
        // Tìm user trước để lấy thông tin SĐT ghi log (Thay vì chỉ dùng existsById)
        User user = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng để xóa"));

        String phone = user.getPhone();
        String role = user.getRole().name();

        userRepository.delete(user);

        // GHI LOG DELETE
        User userProxy = userRepository.getReferenceById(currentUserId);
        String action = "DELETE_USER";
        String entityName = "users";
        String description = String.format("Xóa tài khoản %s (SĐT: %s)", role, phone);

        activityLog.createLog(userProxy, action, entityName, id, description);
    }

    // ================= HELPER / MAPPER =================
    private UserResponse mapToResponse(User user) {
        if (user == null) return null;

        return UserResponse.builder()
                .id(user.getId())
                .phone(user.getPhone())
                .role(user.getRole())
                .fullName(user.getFullName())
                .dob(user.getDob())
                .hometown(user.getHometown())
                .idCardFront(user.getIdCardFront())
                .idCardBack(user.getIdCardBack())
                .isFirstLogin(user.getIsFirstLogin())
                .landlordSignature(user.getLandlordSignature())
                .build();
    }
}