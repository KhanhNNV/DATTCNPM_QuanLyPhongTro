package ut.edu.be_quanlytro.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;
import ut.edu.be_quanlytro.Dto.Request.UserCreateRequest;
import ut.edu.be_quanlytro.Dto.Request.UserUpdateRequest;
import ut.edu.be_quanlytro.Dto.Response.UserResponse;
import ut.edu.be_quanlytro.Entity.Area;
import ut.edu.be_quanlytro.Entity.Enum.RoleType;
import ut.edu.be_quanlytro.Entity.User;
import ut.edu.be_quanlytro.Repository.AreaRepository;
import ut.edu.be_quanlytro.Repository.UserRepository;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final AreaRepository areaRepository;
    private final PasswordEncoder passwordEncoder;
    private final ActivityLogService activityLog;
    private final CloudinaryService cloudinaryService;

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

    // ================= READ (XEM CHI TIẾT USER CÓ CHECK QUYỀN) =================
    @Transactional(readOnly = true) // Đảm bảo giữ Session mở để check liên kết bảng
    public UserResponse getUserById(UUID id, UUID currentUserId) {
        // 1. Lấy thông tin người dùng cần xem (Target User)
        User targetUser = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng"));

        // 2. Lấy thông tin người đang thực hiện cuộc gọi (Current User)
        User currentUser = userRepository.findById(currentUserId)
                .orElseThrow(() -> new RuntimeException("Người dùng không tồn tại trong hệ thống"));

        // 3. 🔒 KIỂM TRA BẢO MẬT BIẾN THỂ (IDOR)
        // Trường hợp A: Nếu tự xem hồ sơ của chính mình thì luôn luôn hợp lệ
        if (id.equals(currentUserId)) {
            return mapToResponse(targetUser);
        }

        // Trường hợp B: Nếu Chủ trọ muốn xem thông tin của một người khác (Khách thuê)
        if (currentUser.getRole() == RoleType.LANDLORD) {

            // Tiến hành kiểm tra xem targetUser (Khách) có nằm trong bất kỳ Khu trọ nào của Chủ trọ này không
            // Dựa trên hàm findTenantsByAreaId bạn đã viết ở bước trước, chúng ta có thể check ngược lại trong DB:
            boolean isYourTenant = userRepository.existsTenantInLandlordAreas(id, currentUserId);

            if (!isYourTenant) {
                throw new RuntimeException("Truy cập bị từ chối! Khách thuê này không thuộc khu trọ nào do bạn quản lý.");
            }
        } else {
            // Trường hợp C: Khách thuê tuyệt đối không được tự ý điền ID để xem người khác
            throw new RuntimeException("Truy cập bị từ chối! Bạn không có quyền xem thông tin của người dùng khác.");
        }

        // 4. Map sang DTO và trả về nếu hợp lệ
        return mapToResponse(targetUser);
    }

    // ================= READ (LẤY DANH SÁCH THEO KHU TRỌ) =================
    @Transactional(readOnly = true) // 💡 Giữ Session mở để tránh lỗi Lazy Load khi gọi area.getLandlord()
    public List<UserResponse> getUsersByArea(UUID areaId, UUID currentUserId) {

        // 1. Lấy thông tin Khu trọ để kiểm tra quyền sở hữu
        // (Đảm bảo bạn đã inject areaRepository vào class Service này)
        Area area = areaRepository.findById(areaId)
                .orElseThrow(() -> new RuntimeException("Khu trọ không tồn tại"));

        // 2. Lấy thông tin người dùng đang gọi API để xác định Vai trò (Role)
        User currentUser = userRepository.findById(currentUserId)
                .orElseThrow(() -> new RuntimeException("Người dùng không tồn tại trong hệ thống"));

        // 3. 🔒 KIỂM TRA BẢO MẬT: Nếu là Chủ trọ thì chỉ được xem khách thuê thuộc khu của mình
        if (currentUser.getRole() == RoleType.LANDLORD) {
            if (!area.getLandlord().getId().equals(currentUserId)) {
                throw new RuntimeException("Truy cập bị từ chối! Bạn không có quyền xem danh sách khách thuê của khu trọ khác.");
            }
        }

        // 4. Nếu vượt qua vòng bảo mật, tiến hành lấy danh sách và map sang DTO
        return userRepository.findTenantsByAreaId(areaId)
                .stream()
                .map(this::mapToResponse)
                .toList(); // Sử dụng .toList() thay cho .collect(Collectors.toList()) nếu dùng Java 16+ cho code ngắn gọn
    }

    // ================= UPDATE =================
    @Transactional
    public UserResponse updateUser(UUID id, UserUpdateRequest request, UUID currentUserId) {
        // Lấy thông tin người dùng cần chỉnh sửa (Target User)
        User user = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng"));

        // 🔒 KIỂM TRA BẢO MẬT: Xác nhận quyền chỉnh sửa thông tin
        if (!id.equals(currentUserId)) { // Nếu không phải hành vi tự sửa hồ sơ của chính mình

            // Lấy thông tin của người đang thực hiện cuộc gọi từ hệ thống
            User currentUser = userRepository.findById(currentUserId)
                    .orElseThrow(() -> new RuntimeException("Người dùng thực hiện thao tác không tồn tại"));

            if (currentUser.getRole() == RoleType.LANDLORD) {
                // Kiểm tra xem khách thuê này có thuộc quyền quản lý của chủ trọ thông qua hợp đồng không
                boolean isYourTenant = userRepository.existsTenantInLandlordAreas(id, currentUserId);
                if (!isYourTenant) {
                    throw new RuntimeException("Truy cập bị từ chối! Bạn không có quyền chỉnh sửa thông tin của khách thuê thuộc khu trọ khác.");
                }
            } else {
                // Nếu vai trò là TENANT hoặc các vai trò khác cố tình truyền ID người khác lên
                throw new RuntimeException("Truy cập bị từ chối! Bạn không có quyền chỉnh sửa thông tin của người dùng khác.");
            }
        }

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

        // 3. Xử lý các trường thông tin cơ bản khác
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
        // 1. Tìm user trước để lấy thông tin (Target User)
        User user = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng để xóa"));

        // 2. 🔒 KIỂM TRA BẢO MẬT: Xác nhận quyền xóa tài khoản
        if (!id.equals(currentUserId)) { // Nếu không phải tự xóa tài khoản của chính mình

            // Lấy thông tin của người đang thực hiện cuộc gọi
            User currentUser = userRepository.findById(currentUserId)
                    .orElseThrow(() -> new RuntimeException("Người dùng thực hiện thao tác không tồn tại"));

            if (currentUser.getRole() == RoleType.LANDLORD) {
                // Kiểm tra xem khách thuê này có thuộc quyền quản lý của chủ trọ không
                boolean isYourTenant = userRepository.existsTenantInLandlordAreas(id, currentUserId);
                if (!isYourTenant) {
                    throw new RuntimeException("Truy cập bị từ chối! Bạn không có quyền xóa tài khoản khách thuê thuộc khu trọ khác.");
                }
            } else {
                // Các Role khác không được phép xóa tài khoản người khác
                throw new RuntimeException("Truy cập bị từ chối! Bạn không có quyền xóa tài khoản của người dùng khác.");
            }
        }

        // Lấy thông tin trước khi thực hiện xóa để ghi log
        String phone = user.getPhone();
        String role = user.getRole().name();

        // 3. Thực hiện xóa người dùng
        userRepository.delete(user);

        // 4. GHI LOG DELETE
        User userProxy = userRepository.getReferenceById(currentUserId);
        String action = "DELETE_USER";
        String entityName = "users";
        String description = String.format("Xóa tài khoản %s (SĐT: %s)", role, phone);

        activityLog.createLog(userProxy, action, entityName, id, description);
    }



    @Transactional
    public String updateSignature(MultipartFile file, UUID currentUserId) {
        if (file.isEmpty()) {
            throw new RuntimeException("Vui lòng chọn hoặc vẽ chữ ký trước khi tải lên!");
        }

        User user = userRepository.findById(currentUserId)
                .orElseThrow(() -> new RuntimeException("Người dùng không tồn tại"));

        if (user.getRole() != RoleType.LANDLORD) {
            throw new RuntimeException("Truy cập bị từ chối! Chỉ tài khoản Chủ trọ mới có quyền thiết lập chữ ký số.");
        }

        // TỰ ĐỘNG DỌN RÁC: Nếu đã có chữ ký cũ, tiến hành xóa tận gốc trên Cloudinary trước
        if (user.getLandlordSignature() != null && !user.getLandlordSignature().isEmpty()) {
            cloudinaryService.deleteFile(user.getLandlordSignature());
        }

        // Sau đó mới tải ảnh mới lên như bình thường
        String signatureUrl = cloudinaryService.uploadFile(file, "signatures");

        user.setLandlordSignature(signatureUrl);
        userRepository.save(user);

        activityLog.createLog(user, "UPDATE_SIGNATURE", "users", user.getId(), "Cập nhật chữ ký số cá nhân.");

        return signatureUrl;
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