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
import ut.edu.be_quanlytro.Entity.Enum.RoomStatus;
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

        // 2. KIỂM TRA BẢO MẬT: Chỉ Chủ trọ của phòng này mới được phép tạo hợp đồng
        User landlord = room.getArea().getLandlord();
        if (!landlord.getId().equals(currentUserId)) {
            throw new RuntimeException("Bạn không có quyền tạo hợp đồng cho phòng thuộc khu trọ khác");
        }

        // 3. CHỐT CHẶN CHỮ KÝ SỐ: Bắt buộc chủ trọ phải cài chữ ký Cloudinary trước
        if (landlord.getLandlordSignature() == null || landlord.getLandlordSignature().isEmpty()) {
            throw new RuntimeException("Vui lòng thiết lập chữ ký số cá nhân trước khi tiến hành lập hợp đồng!");
        }

        // 4. KIỂM TRA TRẠNG THÁI PHÒNG: Không cho phép lập hợp đồng đè lên phòng đang có người ở
        if (room.getStatus() == RoomStatus.RENTED || room.getStatus() == RoomStatus.MAINTENANCE) {
            throw new RuntimeException("Phòng đang ở trạng thái không thể cho thuê (Đang ở hoặc Bảo trì)!");
        }

        // 5. Tạo tài khoản cho Khách đại diện (Tận dụng UserService)
        String rawPassword = generateRandomPassword();
        User tenant = userRepository.findByPhone(request.getTenantPhone()).orElse(null);

        if (tenant == null) {
            UserCreateRequest userReq = new UserCreateRequest();
            userReq.setPhone(request.getTenantPhone());
            userReq.setPassword(rawPassword);
            userReq.setFullName(request.getTenantName());
            userReq.setRole(RoleType.TENANT);

            UserResponse userResponse = userService.createUser(userReq, currentUserId);

            tenant = userRepository.findById(userResponse.getId())
                    .orElseThrow(() -> new RuntimeException("Lỗi truy xuất tài khoản khách sau khi tạo"));
        } else {
            rawPassword = "Khách đã có tài khoản (Dùng mật khẩu cũ)";
        }

        // 6. Khởi tạo đối tượng Hợp đồng
        Contract contract = Contract.builder()
                .room(room)
                .tenant(tenant)
                .startDate(request.getStartDate())
                .endDate(request.getEndDate())
                .depositAmount(request.getDepositAmount())
                .status(ContractStatus.DRAFT) // Mặc định trạng thái bản nháp
                .members(new ArrayList<>())
                .build();

        // 7. Khởi tạo Thành viên chính thức (Khách đại diện) đưa vào phòng
        ContractMember mainMember = ContractMember.builder()
                .contract(contract)
                .joinedAt(LocalDate.now())
                .build();

        contract.getMembers().add(mainMember);

        // 8. Lưu Hợp đồng & Thành viên
        Contract savedContract = contractRepository.save(contract);

        // 9. TỰ ĐỘNG CHUYỂN TRẠNG THÁI PHÒNG SANG RENTED (ĐÃ THUÊ)
        room.setStatus(RoomStatus.RENTED);
        roomRepository.save(room);

        // 10. GHI LOG HOẠT ĐỘNG
        String description = String.format("Khởi tạo hợp đồng cho phòng %s. Khách đại diện: %s (%s)",
                room.getRoomNumber(), tenant.getFullName(), tenant.getPhone());
        activityLog.createLog(landlord, "CREATE_CONTRACT", "contracts", savedContract.getId(), description);

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