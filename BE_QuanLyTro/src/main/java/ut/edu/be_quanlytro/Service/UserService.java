package ut.edu.be_quanlytro.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException; // Import thêm lỗi 403
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;
import ut.edu.be_quanlytro.Dto.Request.BankInfoUpdateRequest;
import ut.edu.be_quanlytro.Dto.Request.UserCreateRequest;
import ut.edu.be_quanlytro.Dto.Request.UserUpdateRequest;
import ut.edu.be_quanlytro.Dto.Response.UserResponse;
import ut.edu.be_quanlytro.Entity.Area;
import ut.edu.be_quanlytro.Entity.Enum.RoleType;
import ut.edu.be_quanlytro.Entity.User;
import ut.edu.be_quanlytro.Exception.BadRequestException; // Import thêm lỗi 400
import ut.edu.be_quanlytro.Exception.ResourceNotFoundException; // Import thêm lỗi 404
import ut.edu.be_quanlytro.Repository.AreaRepository;
import ut.edu.be_quanlytro.Repository.UserRepository;

import java.util.List;
import java.util.UUID;

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
            throw new BadRequestException("Số điện thoại này đã được đăng ký!");
        }

        User user = User.builder()
                .phone(request.getPhone())
                .password(passwordEncoder.encode(request.getPassword())) // Băm mật khẩu
                .role(request.getRole())
                .fullName(request.getFullName())
                .dob(request.getDob())
                .hometown(request.getHometown())
                .idCardNumber(request.getIdCardNumber())
                .isFirstLogin(true)
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
    @Transactional(readOnly = true)
    public UserResponse getUserById(UUID id, UUID currentUserId) {
        // 1. Lấy thông tin người dùng cần xem
        User targetUser = userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy người dùng"));

        // 2. Lấy thông tin người đang thực hiện cuộc gọi
        User currentUser = userRepository.findById(currentUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Người dùng không tồn tại trong hệ thống"));

        // 3. KIỂM TRA BẢO MẬT BIẾN THỂ (IDOR)
        if (id.equals(currentUserId)) {
            return mapToResponse(targetUser);
        }

        if (currentUser.getRole() == RoleType.LANDLORD) {
            boolean isYourTenant = userRepository.existsTenantInLandlordAreas(id, currentUserId);
            if (!isYourTenant) {
                throw new AccessDeniedException("Truy cập bị từ chối! Khách thuê này không thuộc khu trọ nào do bạn quản lý.");
            }
        } else {
            throw new AccessDeniedException("Truy cập bị từ chối! Bạn không có quyền xem thông tin của người dùng khác.");
        }

        return mapToResponse(targetUser);
    }

    // ================= READ (LẤY DANH SÁCH THEO KHU TRỌ) =================
    @Transactional(readOnly = true)
    public List<UserResponse> getUsersByArea(UUID areaId, UUID currentUserId) {
        Area area = areaRepository.findById(areaId)
                .orElseThrow(() -> new ResourceNotFoundException("Khu trọ không tồn tại"));

        User currentUser = userRepository.findById(currentUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Người dùng không tồn tại trong hệ thống"));

        if (currentUser.getRole() == RoleType.LANDLORD) {
            if (!area.getLandlord().getId().equals(currentUserId)) {
                throw new AccessDeniedException("Truy cập bị từ chối! Bạn không có quyền xem danh sách khách thuê của khu trọ khác.");
            }
        }

        return userRepository.findTenantsByAreaId(areaId)
                .stream()
                .map(this::mapToResponse)
                .toList();
    }

    // ================= UPDATE =================
    @Transactional
    public UserResponse updateUser(UUID id, UserUpdateRequest request, UUID currentUserId) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy người dùng"));

        // KIỂM TRA BẢO MẬT
        if (!id.equals(currentUserId)) {
            User currentUser = userRepository.findById(currentUserId)
                    .orElseThrow(() -> new ResourceNotFoundException("Người dùng thực hiện thao tác không tồn tại"));

            if (currentUser.getRole() == RoleType.LANDLORD) {
                boolean isYourTenant = userRepository.existsTenantInLandlordAreas(id, currentUserId);
                if (!isYourTenant) {
                    throw new AccessDeniedException("Truy cập bị từ chối! Bạn không có quyền chỉnh sửa thông tin của khách thuê thuộc khu trọ khác.");
                }
            } else {
                throw new AccessDeniedException("Truy cập bị từ chối! Bạn không có quyền chỉnh sửa thông tin của người dùng khác.");
            }
        }

        if (StringUtils.hasText(request.getPhone())) {
            String newPhone = request.getPhone().trim();
            if (!user.getPhone().equals(newPhone)) {
                if (userRepository.existsByPhone(newPhone)) {
                    throw new BadRequestException("Số điện thoại mới này đã tồn tại trong hệ thống!");
                }
                user.setPhone(newPhone);
            }
        }

        if (StringUtils.hasText(request.getPassword())) {
            user.setPassword(passwordEncoder.encode(request.getPassword()));
        }

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
    public void deleteUser(UUID id) {
        User targetUser = userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy tài khoản cần xóa!"));
        userRepository.delete(targetUser);
    }

    // ================= UPDATE SIGNATURE =================
    @Transactional
    public void updateSignature(MultipartFile file, UUID currentUserId) {
        if (file.isEmpty()) {
            throw new BadRequestException("Vui lòng chọn hoặc vẽ chữ ký trước khi tải lên!");
        }

        User user = userRepository.findById(currentUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Người dùng không tồn tại"));

        if (user.getRole() != RoleType.LANDLORD) {
            throw new AccessDeniedException("Truy cập bị từ chối! Chỉ tài khoản Chủ trọ mới có quyền thiết lập chữ ký số.");
        }

        if (user.getLandlordSignature() != null && !user.getLandlordSignature().isEmpty()) {
            cloudinaryService.deleteFile(user.getLandlordSignature());
        }

        String signatureUrl = cloudinaryService.uploadFile(file, "signatures");

        user.setLandlordSignature(signatureUrl);
        userRepository.save(user);

        activityLog.createLog(user, "UPDATE_SIGNATURE", "users", user.getId(), "Cập nhật chữ ký số cá nhân.");
    }

    // ================= GET SIGNATURE =================
    @Transactional(readOnly = true)
    public String getSignature(UUID currentUserId) {
        User user = userRepository.findById(currentUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Người dùng không tồn tại"));

        if (user.getRole() != RoleType.LANDLORD) {
            throw new AccessDeniedException("Truy cập bị từ chối! Chỉ tài khoản Chủ trọ mới có chữ ký số.");
        }

        return user.getLandlordSignature();
    }

    // ================= UPDATE BANK INFO =================
    @Transactional
    public void updateBankInfo(UUID currentUserId, BankInfoUpdateRequest request) {
        User user = userRepository.findById(currentUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy người dùng!"));

        if (user.getRole() != RoleType.LANDLORD) {
            throw new AccessDeniedException("Chỉ Chủ trọ mới được cấu hình tài khoản ngân hàng!");
        }

        user.setBankId(request.getBankId());
        user.setAccountNo(request.getAccountNo());
        user.setAccountName(request.getAccountName().toUpperCase());

        userRepository.save(user);
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
                .idCardNumber(user.getIdCardNumber())
                .isFirstLogin(user.getIsFirstLogin())
                .build();
    }
}