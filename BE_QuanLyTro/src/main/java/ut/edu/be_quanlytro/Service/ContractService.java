package ut.edu.be_quanlytro.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ut.edu.be_quanlytro.Dto.Request.ContractCreateRequest;
import ut.edu.be_quanlytro.Dto.Request.UserCreateRequest;
import ut.edu.be_quanlytro.Dto.Response.ContractCreateResponse;
import ut.edu.be_quanlytro.Dto.Response.ContractDetailResponse;
import ut.edu.be_quanlytro.Dto.Response.UserResponse;
import ut.edu.be_quanlytro.Entity.Contract;
import ut.edu.be_quanlytro.Entity.ContractMember;
import ut.edu.be_quanlytro.Entity.Enum.ContractStatus;
import ut.edu.be_quanlytro.Entity.Enum.RoleType;
import ut.edu.be_quanlytro.Entity.Room;
import ut.edu.be_quanlytro.Entity.User;
import ut.edu.be_quanlytro.Repository.ContractRepository;
import ut.edu.be_quanlytro.Repository.RoomRepository;
import ut.edu.be_quanlytro.Repository.UserRepository;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Random;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class ContractService {

    private final ContractRepository contractRepository;
    private final RoomRepository roomRepository;
    private final UserRepository userRepository;

    // Tận dụng lại các Service đã có
    private final UserService userService;
    private final ActivityLogService activityLog;

    // ================= 1. KHỞI TẠO HỢP ĐỒNG =================
    @Transactional
    public ContractCreateResponse createContract(ContractCreateRequest request, UUID currentUserId) {

        // 1. Kiểm tra phòng tồn tại
        Room room = roomRepository.findById(request.getRoomId())
                .orElseThrow(() -> new RuntimeException("Phòng không tồn tại"));

        // 2. Tạo tài khoản cho Khách đại diện (Tận dụng UserService)
        String rawPassword = generateRandomPassword();
        User tenant = userRepository.findByPhone(request.getTenantPhone()).orElse(null);

        if (tenant == null) {
            // Đóng gói dữ liệu gửi sang UserService
            UserCreateRequest userReq = new UserCreateRequest();
            userReq.setPhone(request.getTenantPhone());
            userReq.setPassword(rawPassword);
            userReq.setFullName(request.getTenantName());
            userReq.setRole(RoleType.TENANT);

            // Gọi hàm tạo User (Hàm này đã tự động băm mật khẩu và ghi log "CREATE_USER" rồi)
            UserResponse userResponse = userService.createUser(userReq, currentUserId);

            // Lấy lại thực thể User từ DB để gắn vào Hợp đồng
            tenant = userRepository.findById(userResponse.getId())
                    .orElseThrow(() -> new RuntimeException("Lỗi truy xuất tài khoản khách sau khi tạo"));
        } else {
            rawPassword = "Khách đã có tài khoản (Dùng mật khẩu cũ)";
        }

        // 3. Khởi tạo đối tượng Hợp đồng
        Contract contract = Contract.builder()
                .room(room)
                .tenant(tenant)
                .startDate(request.getStartDate())
                .endDate(request.getEndDate())
                .depositAmount(request.getDepositAmount())
                .status(ContractStatus.DRAFT)
                .members(new ArrayList<>()) // Khởi tạo danh sách rỗng để tránh lỗi Null
                .build();

        // 4. Khởi tạo Thành viên và NHÉT VÀO DANH SÁCH của Hợp đồng
        ContractMember mainMember = ContractMember.builder()
                .contract(contract)
                .user(tenant)
                .joinedAt(LocalDate.now())
                .build();

        contract.getMembers().add(mainMember);

        // 5. Lưu Hợp đồng (Spring Boot sẽ tự động lưu luôn cả mainMember)
        Contract savedContract = contractRepository.save(contract);

        // 6. GHI LOG TẠO HỢP ĐỒNG
        User userProxy = userRepository.getReferenceById(currentUserId);
        String action = "CREATE_CONTRACT";
        String entityName = "contracts";
        String description = String.format("Khởi tạo hợp đồng nháp cho phòng %s. Khách đại diện: %s (%s)",
                room.getRoomNumber() != null ? room.getRoomNumber() : "chưa rõ",
                tenant.getFullName() != null ? tenant.getFullName() : "Khách",
                tenant.getPhone());

        activityLog.createLog(userProxy, action, entityName, savedContract.getId(), description);

        // 7. Trả về kết quả
        return ContractCreateResponse.builder()
                .tenantUsername(tenant.getPhone())
                .tenantRawPassword(rawPassword)
                .message("Khởi tạo hợp đồng thành công!")
                .build();
    }

    // ================= 2. XEM CHI TIẾT HỢP ĐỒNG =================
    public ContractDetailResponse getContractDetails(UUID contractId) {
        Contract contract = contractRepository.findById(contractId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy hợp đồng"));

        return ContractDetailResponse.builder()
                .id(contract.getId())
                .roomName(contract.getRoom().getRoomNumber()) // Lấy tên phòng
                .tenantName(contract.getTenant().getFullName())
                .tenantPhone(contract.getTenant().getPhone())
                .startDate(contract.getStartDate())
                .endDate(contract.getEndDate())
                .depositAmount(contract.getDepositAmount())
                .status(contract.getStatus())
                .totalMembers(contract.getMembers().size()) // Đếm xem phòng đang có mấy người
                .build();
    }

    // Hàm phụ trợ
    private String generateRandomPassword() {
        Random random = new Random();
        return String.valueOf(100000 + random.nextInt(900000));
    }
}