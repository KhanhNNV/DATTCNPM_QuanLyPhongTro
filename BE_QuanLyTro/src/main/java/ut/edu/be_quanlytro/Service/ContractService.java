package ut.edu.be_quanlytro.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import ut.edu.be_quanlytro.Dto.Request.ContractCreateManualRequest;
import ut.edu.be_quanlytro.Dto.Request.ContractCreateRequest;
import ut.edu.be_quanlytro.Dto.Request.UserCreateRequest;
import ut.edu.be_quanlytro.Dto.Response.*;
import ut.edu.be_quanlytro.Entity.*;
import ut.edu.be_quanlytro.Entity.Enum.ContractStatus;
import ut.edu.be_quanlytro.Entity.Enum.DepositStatus;
import ut.edu.be_quanlytro.Entity.Enum.RoleType;
import ut.edu.be_quanlytro.Entity.Enum.RoomStatus;
import ut.edu.be_quanlytro.Repository.ContractRepository;
import ut.edu.be_quanlytro.Repository.DepositRepository;
import ut.edu.be_quanlytro.Repository.RoomRepository;
import ut.edu.be_quanlytro.Repository.UserRepository;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
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
    private final DepositRepository depositRepository;
    private final OcrService  ocrService;

    // ================= 1. KHỞI TẠO HỢP ĐỒNG (Quét CCCD)=================
    @Transactional
    public ContractCreateResponse createContract(ContractCreateRequest request, MultipartFile frontImage, MultipartFile backImage, UUID currentUserId) {

        // 1. KIỂM TRA PHÒNG VÀ QUYỀN CHỦ TRỌ
        Room room = roomRepository.findById(request.getRoomId())
                .orElseThrow(() -> new RuntimeException("Phòng không tồn tại"));

        User landlord = room.getArea().getLandlord();
        if (!landlord.getId().equals(currentUserId)) {
            throw new RuntimeException("Bạn không có quyền tạo hợp đồng cho phòng thuộc khu trọ khác");
        }

        if (landlord.getLandlordSignature() == null || landlord.getLandlordSignature().isEmpty()) {
            throw new RuntimeException("Vui lòng thiết lập chữ ký số cá nhân trước khi lập hợp đồng!");
        }

        //Chỉ cho phép tạo hợp đồng khi phòng trống hoặc phòng đã nhận cọc
        if (room.getStatus() != RoomStatus.AVAILABLE && room.getStatus() != RoomStatus.DEPOSITED) {
            throw new RuntimeException("Phòng hiện không ở trạng thái sẵn sàng để lập hợp đồng (Đang ở, bảo trì hoặc đang chờ khách khác ký)!");
        }

        Deposit pendingDeposit = null;

        if (request.getDepositId() != null) {
            // Tìm phiếu cọc theo ID truyền vào
            pendingDeposit = depositRepository.findById(request.getDepositId())
                    .orElseThrow(() -> new RuntimeException("Không tìm thấy phiếu đặt cọc với ID đã cung cấp!"));

            // Kiểm tra chéo 1: Phiếu cọc này có đúng là của phòng đang lập hợp đồng không?
            if (!pendingDeposit.getRoom().getId().equals(room.getId())) {
                throw new RuntimeException("Phiếu đặt cọc này không thuộc về phòng bạn đang chọn!");
            }

            // Kiểm tra chéo 2: Phiếu cọc còn hiệu lực không?
            if (pendingDeposit.getStatus() != DepositStatus.PENDING) {
                throw new RuntimeException("Phiếu đặt cọc này đã được xử lý (đã lên hợp đồng) hoặc đã bị hủy!");
            }

            // Kiểm tra chéo 3: SĐT người làm hợp đồng có khớp với SĐT người đã cọc không?
            if (!pendingDeposit.getPhone().equals(request.getTenantPhone())) {
                throw new RuntimeException("Số điện thoại khách thuê (" + request.getTenantPhone() +
                        ") không khớp với số điện thoại trên phiếu cọc (" + pendingDeposit.getPhone() + ")!");
            }
        }

        // 3. GỌI FPT AI ĐỂ QUÉT CCCD
        // Việc quét lỗi hay thiếu ảnh sẽ được OcrService quăng lỗi (throw RuntimeException) và dừng luồng ngay lập tức
        OcrCccdResponse ocrData = ocrService.extractCccdData(frontImage, backImage);

        // FPT trả về ngày sinh dạng String (VD: "15/05/2001"), cần parse sang LocalDate
        LocalDate parsedDob = null;
        try {
            java.time.format.DateTimeFormatter formatter = java.time.format.DateTimeFormatter.ofPattern("dd/MM/yyyy");
            parsedDob = LocalDate.parse(ocrData.getDob(), formatter);
        } catch (Exception e) {
            System.err.println("Cảnh báo: Không thể parse ngày sinh từ OCR (" + ocrData.getDob() + ")");
        }

        // 4. TẠO TÀI KHOẢN KHÁCH THUÊ (Ưu tiên lấy tên chuẩn xác từ CCCD)
        String rawPassword = generateRandomPassword();
        User tenant = userRepository.findByPhone(request.getTenantPhone()).orElse(null);

        if (tenant == null) {
            UserCreateRequest userReq = new UserCreateRequest();
            userReq.setPhone(request.getTenantPhone());
            userReq.setPassword(rawPassword);
            userReq.setFullName(ocrData.getFullName());
            userReq.setRole(RoleType.TENANT);
            userReq.setDob(parsedDob);
            userReq.setHometown(ocrData.getHometown());
            userReq.setIdCardNumber(ocrData.getIdNumber());



            UserResponse userResponse = userService.createUser(userReq, currentUserId);

            tenant = userRepository.findById(userResponse.getId())
                    .orElseThrow(() -> new RuntimeException("Lỗi truy xuất tài khoản khách sau khi tạo"));
        } else {
            rawPassword = "Khách đã có tài khoản (Dùng mật khẩu cũ)";
        }

        // 5. KHỞI TẠO HỢP ĐỒNG
        Contract contract = Contract.builder()
                .room(room)
                .tenant(tenant)
                .startDate(request.getStartDate())
                .endDate(request.getEndDate())
                .landlordSignature(landlord.getLandlordSignature())
                .depositAmount(pendingDeposit != null ? pendingDeposit.getDepositAmount() : request.getDepositAmount())
                .status(ContractStatus.DRAFT)
                .members(new ArrayList<>())
                .build();

        // 6. KHỞI TẠO THÀNH VIÊN ĐẠI DIỆN VỚI DỮ LIỆU TỪ AI
        ContractMember mainMember = ContractMember.builder()
                .contract(contract)
                .phone(request.getTenantPhone())
                .fullName(ocrData.getFullName())
                .dob(parsedDob)
                .hometown(ocrData.getHometown())
                .idCardNumber(ocrData.getIdNumber())
                .joinedAt(LocalDate.now())
                .build();

        contract.getMembers().add(mainMember);

        // 7. LƯU DỮ LIỆU ĐỒNG LOẠT XUỐNG DATABASE
        Contract savedContract = contractRepository.save(contract);

        // Cập nhật trạng thái Cọc (Nếu có) thành COMPLETED và gắn vào hợp đồng này
        if (pendingDeposit != null) {
            pendingDeposit.setStatus(DepositStatus.COMPLETED);
            pendingDeposit.setContract(savedContract);
            depositRepository.save(pendingDeposit);
        }

        // Cập nhật trạng thái Phòng
        room.setStatus(RoomStatus.RESERVED);
        roomRepository.save(room);

        // 8. GHI LOG
        String description = String.format("Khởi tạo hợp đồng cho phòng %s. Khách: %s",
                room.getRoomNumber(), ocrData.getFullName());
        activityLog.createLog(landlord, "CREATE_CONTRACT", "contracts", savedContract.getId(), description);

        return ContractCreateResponse.builder()
                .contractId(savedContract.getId())
                .tenantUsername(tenant.getPhone())
                .tenantRawPassword(rawPassword)
                .message("Tạo hợp đồng thành công!")
                .build();
    }
    // ================= 2. KHỞI TẠO HỢP ĐỒNG (NHẬP TAY) =================
    @Transactional
    public ContractCreateResponse createContractManual(ContractCreateManualRequest request, UUID currentUserId) {

        // 1. KIỂM TRA PHÒNG VÀ QUYỀN CHỦ TRỌ
        Room room = roomRepository.findById(request.getRoomId())
                .orElseThrow(() -> new RuntimeException("Phòng không tồn tại"));

        User landlord = room.getArea().getLandlord();
        if (!landlord.getId().equals(currentUserId)) {
            throw new RuntimeException("Bạn không có quyền tạo hợp đồng cho phòng thuộc khu trọ khác");
        }

        if (landlord.getLandlordSignature() == null || landlord.getLandlordSignature().isEmpty()) {
            throw new RuntimeException("Vui lòng thiết lập chữ ký số cá nhân trước khi lập hợp đồng!");
        }

        // Chỉ cho phép tạo hợp đồng khi phòng trống hoặc phòng đã nhận cọc
        if (room.getStatus() != RoomStatus.AVAILABLE && room.getStatus() != RoomStatus.DEPOSITED) {
            throw new RuntimeException("Phòng hiện không ở trạng thái sẵn sàng để lập hợp đồng!");
        }

        // 2. KIỂM TRA ĐẶT CỌC
        Deposit pendingDeposit = null;
        if (request.getDepositId() != null) {
            pendingDeposit = depositRepository.findById(request.getDepositId())
                    .orElseThrow(() -> new RuntimeException("Không tìm thấy phiếu đặt cọc với ID đã cung cấp!"));

            if (!pendingDeposit.getRoom().getId().equals(room.getId())) {
                throw new RuntimeException("Phiếu đặt cọc này không thuộc về phòng bạn đang chọn!");
            }

            if (pendingDeposit.getStatus() != DepositStatus.PENDING) {
                throw new RuntimeException("Phiếu đặt cọc này đã được xử lý hoặc đã bị hủy!");
            }

            if (!pendingDeposit.getPhone().equals(request.getTenantPhone())) {
                throw new RuntimeException("Số điện thoại khách không khớp với phiếu cọc!");
            }
        }

        // 3. TẠO TÀI KHOẢN KHÁCH THUÊ (Lấy trực tiếp thông tin từ Request nhập tay)
        String rawPassword = generateRandomPassword();
        User tenant = userRepository.findByPhone(request.getTenantPhone()).orElse(null);

        if (tenant == null) {
            UserCreateRequest userReq = new UserCreateRequest();
            userReq.setPhone(request.getTenantPhone());
            userReq.setPassword(rawPassword);
            userReq.setFullName(request.getTenantName()); // Lấy từ request nhập tay
            userReq.setRole(RoleType.TENANT);
            userReq.setDob(request.getTenantDob());       // Lấy từ request nhập tay
            userReq.setHometown(request.getTenantHometown()); // Lấy từ request nhập tay
            userReq.setIdCardNumber(request.getTenantIdCardNumber()); // Lấy từ request nhập tay

            UserResponse userResponse = userService.createUser(userReq, currentUserId);

            tenant = userRepository.findById(userResponse.getId())
                    .orElseThrow(() -> new RuntimeException("Lỗi truy xuất tài khoản khách sau khi tạo"));
        } else {
            rawPassword = "Khách đã có tài khoản (Dùng mật khẩu cũ)";
        }

        // 4. KHỞI TẠO HỢP ĐỒNG
        Contract contract = Contract.builder()
                .room(room)
                .tenant(tenant)
                .startDate(request.getStartDate())
                .endDate(request.getEndDate())
                .landlordSignature(landlord.getLandlordSignature())
                .depositAmount(pendingDeposit != null ? pendingDeposit.getDepositAmount() : request.getDepositAmount())
                .status(ContractStatus.DRAFT)
                .members(new ArrayList<>())
                .build();

        // 5. KHỞI TẠO THÀNH VIÊN ĐẠI DIỆN
        ContractMember mainMember = ContractMember.builder()
                .contract(contract)
                .phone(request.getTenantPhone())
                .fullName(request.getTenantName())
                .dob(request.getTenantDob())
                .hometown(request.getTenantHometown())
                .idCardNumber(request.getTenantIdCardNumber())
                .joinedAt(LocalDate.now())
                .build();

        contract.getMembers().add(mainMember);

        // 6. LƯU DATABASE
        Contract savedContract = contractRepository.save(contract);

        if (pendingDeposit != null) {
            pendingDeposit.setStatus(DepositStatus.COMPLETED);
            pendingDeposit.setContract(savedContract);
            depositRepository.save(pendingDeposit);
        }

        room.setStatus(RoomStatus.RESERVED);
        roomRepository.save(room);

        // 7. GHI LOG
        String description = String.format("Khởi tạo hợp đồng (Nhập tay) cho phòng %s. Khách: %s",
                room.getRoomNumber(), tenant.getFullName());
        activityLog.createLog(landlord, "CREATE_CONTRACT", "contracts", savedContract.getId(), description);

        return ContractCreateResponse.builder()
                .contractId(savedContract.getId())
                .tenantUsername(tenant.getPhone())
                .tenantRawPassword(rawPassword)
                .message("Tạo hợp đồng nhập tay thành công!")
                .build();
    }

    // ================= MAPPER =================
    private ContractDetailResponse mapToDetailResponse(Contract contract) {

        // 1. Map danh sách khách ở ghép (ContractMembers)
        // Lưu ý: Nếu bạn chưa có class ContractMemberResponse, hãy tạo nó để chứa thông tin thành viên
        List<ContractMemberResponse> memberResponses = contract.getMembers().stream()
                .map(member -> ContractMemberResponse.builder()
                        .id(member.getId())
                        .fullName(member.getFullName())
                        .phone(member.getPhone())
                        .dob(member.getDob())
                        .hometown(member.getHometown())
                        .joinedAt(member.getJoinedAt())
                        .build())
                .toList();

        // 2. Map thông tin tổng thể của Hợp đồng
        return ContractDetailResponse.builder()
                .id(contract.getId())
                .roomId(contract.getRoom().getId())
                .roomNumber(contract.getRoom().getRoomNumber())
                .tenantId(contract.getTenant().getId())
                .tenantName(contract.getTenant().getFullName())
                .tenantPhone(contract.getTenant().getPhone())
                .startDate(contract.getStartDate())
                .endDate(contract.getEndDate())
                .depositAmount(contract.getDepositAmount())
                .status(contract.getStatus())
                .contractFileUrl(contract.getContractFileUrl())
                .members(memberResponses) // Nhúng danh sách thành viên vào đây
                .build();
    }


    // Hàm phụ trợ
    private String generateRandomPassword() {
        Random random = new Random();
        return String.valueOf(100000 + random.nextInt(900000));
    }
}