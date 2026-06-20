package ut.edu.be_quanlytro.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import ut.edu.be_quanlytro.Dto.Request.*;
import ut.edu.be_quanlytro.Dto.Response.*;
import ut.edu.be_quanlytro.Entity.*;
import ut.edu.be_quanlytro.Entity.Enum.*;
import ut.edu.be_quanlytro.Repository.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.*;

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
    private final CloudinaryService cloudinaryService;
    private final NotificationService notificationService;
    private final ContractTemplateRepository templateRepository;
    private final PdfExportService pdfExportService;


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


        // 5. LẤY MẪU HỢP ĐỒNG VÀ KHỞI TẠO

        ContractTemplate template = templateRepository.findById(request.getTemplateId())
                .orElseThrow(() -> new RuntimeException("Không tìm thấy mẫu hợp đồng yêu cầu!"));

        // Khởi tạo đối tượng Hợp đồng
        Contract contract = Contract.builder()
                .room(room)
                .tenant(tenant)
                .template(template)
                .startDate(request.getStartDate())
                .endDate(request.getEndDate())
                .landlordSignature(landlord.getLandlordSignature())
                .depositAmount(pendingDeposit != null ? pendingDeposit.getDepositAmount() : request.getDepositAmount())
                .status(ContractStatus.DRAFT)
                .members(new ArrayList<>())
                .build();

        String compiledHtml = compileContractTerms(template, contract, landlord, tenant, room);
        contract.setContractTerms(compiledHtml);

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


        // 5. LẤY MẪU HỢP ĐỒNG VÀ KHỞI TẠO

        ContractTemplate template = templateRepository.findById(request.getTemplateId())
                .orElseThrow(() -> new RuntimeException("Không tìm thấy mẫu hợp đồng yêu cầu!"));

        // Khởi tạo đối tượng Hợp đồng
        Contract contract = Contract.builder()
                .room(room)
                .tenant(tenant)
                .template(template)
                .startDate(request.getStartDate())
                .endDate(request.getEndDate())
                .landlordSignature(landlord.getLandlordSignature())
                .depositAmount(pendingDeposit != null ? pendingDeposit.getDepositAmount() : request.getDepositAmount())
                .status(ContractStatus.DRAFT)
                .members(new ArrayList<>())
                .build();

        // 🌟 Gọi hàm biên dịch HTML và lưu "chết" vào cột contractTerms
        String compiledHtml = compileContractTerms(template, contract, landlord, tenant, room);
        contract.setContractTerms(compiledHtml);

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
    // ================= 3. LẤY CHI TIẾT HỢP ĐỒNG (CHỈ DÀNH CHO CHỦ TRỌ) =================
    @Transactional(readOnly = true)
    public ContractDetailResponse getContractByIdForLandlord(UUID contractId, UUID currentUserId) {
        // 1. Tìm hợp đồng dưới DB
        Contract contract = contractRepository.findById(contractId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy hợp đồng với ID cung cấp!"));

        // 2. Chốt chặn bảo mật (Chỉ Chủ trọ của khu trọ đó mới được xem)
        boolean isLandlord = contract.getRoom().getArea().getLandlord().getId().equals(currentUserId);

        if (!isLandlord) {
            throw new RuntimeException("Bạn không có quyền quản lý, không thể xem thông tin của hợp đồng này!");
        }

        return mapToDetailResponse(contract);
    }

    // ================= 4. LẤY HỢP ĐỒNG HIỆN TẠI (CHỈ DÀNH CHO KHÁCH THUÊ) =================
    @Transactional(readOnly = true)
    public ContractDetailResponse getMyCurrentContract(UUID tenantId) {

        // Chỉ quét tìm các hợp đồng đang là BẢN NHÁP (chờ ký) hoặc ĐANG HOẠT ĐỘNG
        List<ContractStatus> validStatuses = List.of(ContractStatus.DRAFT, ContractStatus.SIGNED);

        // Tìm hợp đồng thỏa mãn điều kiện
        Contract currentContract = contractRepository.findFirstByTenantIdAndStatusInOrderByCreatedAtDesc(tenantId, validStatuses)
                .orElseThrow(() -> new RuntimeException("Bạn hiện tại chưa có hợp đồng nào đang chờ ký hoặc đang hoạt động trong hệ thống!"));

        return mapToDetailResponse(currentContract);
    }

    // ================= 5. LẤY DANH SÁCH HỢP ĐỒNG (CHO CHỦ TRỌ) =================
    @Transactional(readOnly = true)
    public List<ContractDetailResponse> getContractsByLandlord(UUID landlordId) {
        // 1. Lấy toàn bộ danh sách hợp đồng liên quan đến các phòng của chủ trọ
        List<Contract> contracts = contractRepository.findByRoomAreaLandlordIdOrderByCreatedAtDesc(landlordId);

        // 2. Dùng Stream API và hàm Mapper để chuyển đổi List<Entity> sang List<DTO>
        return contracts.stream()
                .map(this::mapToDetailResponse)
                .toList();
    }
    // ================= 6. THÊM THÀNH VIÊN VÀO HỢP ĐỒNG =================
    @Transactional
    public ContractDetailResponse addContractMember(ContractMemberAddRequest request, UUID currentUserId) {

        // 1. Tìm hợp đồng dưới Database
        Contract contract = contractRepository.findById(request.getContractId())
                .orElseThrow(() -> new RuntimeException("Không tìm thấy hợp đồng với ID đã cung cấp!"));

        // 2. Chốt chặn bảo mật (Chỉ Chủ trọ quản lý phòng này mới được thêm người)
        boolean isLandlord = contract.getRoom().getArea().getLandlord().getId().equals(currentUserId);
        if (!isLandlord) {
            throw new RuntimeException("Bạn không có quyền thêm thành viên vào hợp đồng của khu trọ khác!");
        }

        // 3. Chốt chặn nghiệp vụ (Chỉ cho phép thêm khi hợp đồng đang DRAFT hoặc ACTIVE)
        if (contract.getStatus() != ContractStatus.DRAFT && contract.getStatus() != ContractStatus.SIGNED) {
            throw new RuntimeException("Chỉ có thể thêm thành viên khi hợp đồng đang ở trạng thái Nháp hoặc Đang hoạt động!");
        }

        // 4. Kiểm tra trùng lặp (Ngăn chặn thêm 1 người 2 lần)
        boolean isExist = contract.getMembers().stream()
                .anyMatch(member -> member.getIdCardNumber().equals(request.getIdCardNumber())
                        || member.getPhone().equals(request.getPhone()));
        if (isExist) {
            throw new RuntimeException("Thành viên với Số điện thoại hoặc CCCD này đã tồn tại trong hợp đồng!");
        }

        // 5. Khởi tạo đối tượng Thành viên mới
        ContractMember newMember = ContractMember.builder()
                .contract(contract)
                .fullName(request.getFullName())
                .phone(request.getPhone())
                .dob(request.getDob())
                .hometown(request.getHometown())
                .idCardNumber(request.getIdCardNumber())
                .joinedAt(LocalDate.now())
                .build();

        // 6. Gắn vào danh sách của Hợp đồng
        contract.getMembers().add(newMember);

        // 7. Lưu xuống Database
        // Nhờ thuộc tính cascade = CascadeType.ALL ở Entity Contract, ta chỉ cần save Contract là Member sẽ tự động được lưu theo!
        Contract savedContract = contractRepository.save(contract);

        // 8. Ghi Log hệ thống
        String description = String.format("Thêm khách ở ghép: %s vào phòng %s",
                request.getFullName(), contract.getRoom().getRoomNumber());
        activityLog.createLog(contract.getRoom().getArea().getLandlord(), "ADD_MEMBER", "contracts", savedContract.getId(), description);

        // 9. Trả về chi tiết hợp đồng mới nhất (để Frontend tự động cập nhật danh sách)
        return mapToDetailResponse(savedContract);
    }
    // ================= 7. THANH LÝ HỢP ĐỒNG=================
    @Transactional
    public ContractTerminationResponse terminateContract(ContractTerminationRequest request, UUID currentUserId) {

        // 1. Tìm hợp đồng
        Contract contract = contractRepository.findById(request.getContractId())
                .orElseThrow(() -> new RuntimeException("Không tìm thấy hợp đồng!"));

        // 2. Chốt chặn bảo mật
        if (!contract.getRoom().getArea().getLandlord().getId().equals(currentUserId)) {
            throw new RuntimeException("Bạn không có quyền thanh lý hợp đồng này!");
        }

        // 3. Kiểm tra trạng thái hợp đồng
        if (contract.getStatus() != ContractStatus.SIGNED) {
            throw new RuntimeException("Chỉ có thể thanh lý hợp đồng đang ở trạng thái SIGNED");
        }

        // 4. TÍNH TOÁN BÙ TRỪ CỌC
        // a. Tính tổng tiền điện nước tháng cuối
        BigDecimal electricityCost = request.getElectricityPrice().multiply(new BigDecimal(request.getElectricityUsage()));
        BigDecimal waterCost = request.getWaterPrice().multiply(new BigDecimal(request.getWaterUsage()));

        // b. Tổng tiền bị trừ = Điện + Nước + Hư hỏng/Phạt (Nếu có)
        BigDecimal damages = request.getOtherDamagesFee() != null ? request.getOtherDamagesFee() : BigDecimal.ZERO;
        BigDecimal totalDeduction = electricityCost.add(waterCost).add(damages);

        // c. Tính toán chênh lệch với tiền cọc
        BigDecimal depositAmount = contract.getDepositAmount() != null ? contract.getDepositAmount() : BigDecimal.ZERO;
        BigDecimal offsetAmount = depositAmount.subtract(totalDeduction);

        String action;
        BigDecimal finalAmountToShow;

        if (offsetAmount.compareTo(BigDecimal.ZERO) > 0) {
            action = "HOÀN_TRẢ_KHÁCH"; // Cọc > Nợ -> Trả lại tiền dư cho khách
            finalAmountToShow = offsetAmount;
        } else if (offsetAmount.compareTo(BigDecimal.ZERO) < 0) {
            action = "THU_THÊM_TỪ_KHÁCH"; // Cọc < Nợ -> Bắt khách đóng thêm tiền
            finalAmountToShow = offsetAmount.abs(); // Lấy trị tuyệt đối cho dễ nhìn
        } else {
            action = "HÒA_CÔNG_NỢ"; // Cọc = Nợ
            finalAmountToShow = BigDecimal.ZERO;
        }

        // 5. CẬP NHẬT TRẠNG THÁI (Đóng băng dữ liệu)
        contract.setStatus(ContractStatus.TERMINATED);
        Room room = contract.getRoom();
        room.setStatus(RoomStatus.AVAILABLE);

        contractRepository.save(contract);
        roomRepository.save(room);

        // 6. Ghi Log hệ thống
        String logDesc = String.format("Thanh lý hợp đồng phòng %s. %s: %s VNĐ",
                room.getRoomNumber(), action, finalAmountToShow);
        activityLog.createLog(contract.getRoom().getArea().getLandlord(), "TERMINATE_CONTRACT", "contracts", contract.getId(), logDesc);

        // 7. Trả về kết quả
        return ContractTerminationResponse.builder()
                .contractId(contract.getId())
                .roomNumber(room.getRoomNumber())
                .depositAmount(depositAmount)
                .totalDeduction(totalDeduction)
                .finalAmount(finalAmountToShow)
                .settlementAction(action)
                .message("Thanh lý hợp đồng thành công")
                .build();
    }
    // ================= 8. CẬP NHẬT HỢP ĐỒNG (CHỈ ÁP DỤNG KHI LÀ BẢN NHÁP) =================
    @Transactional
    public ContractDetailResponse updateContract(UUID contractId, ContractUpdateRequest request, UUID currentUserId) {

        // 1. Tìm hợp đồng dưới DB
        Contract contract = contractRepository.findById(contractId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy hợp đồng!"));

        // 2. Chốt chặn bảo mật
        if (!contract.getRoom().getArea().getLandlord().getId().equals(currentUserId)) {
            throw new RuntimeException("Bạn không có quyền chỉnh sửa hợp đồng này!");
        }

        // 3. Chốt chặn Nghiệp vụ pháp lý (CỰC KỲ QUAN TRỌNG)
        if (contract.getStatus() != ContractStatus.DRAFT) {
            throw new RuntimeException("Lỗi: Chỉ có thể chỉnh sửa điều khoản khi hợp đồng đang là Bản Nháp. Hợp đồng đã ký không được phép thay đổi!");
        }

        // 4. Cập nhật các trường dữ liệu (Chỉ cập nhật nếu có truyền lên từ Request)
        if (request.getStartDate() != null) {
            contract.setStartDate(request.getStartDate());
        }
        if (request.getEndDate() != null) {
            contract.setEndDate(request.getEndDate());
        }

        if (request.getDepositAmount() != null) {
            contract.setDepositAmount(request.getDepositAmount());
        }

        // 5. Lưu xuống DB
        Contract updatedContract = contractRepository.save(contract);

        // 6. Ghi log hoạt động
        String logDesc = String.format("Cập nhật thông tin bản nháp hợp đồng phòng %s", contract.getRoom().getRoomNumber());
        activityLog.createLog(contract.getRoom().getArea().getLandlord(), "UPDATE_CONTRACT", "contracts", updatedContract.getId(), logDesc);

        // 7. Trả về chi tiết mới nhất
        return mapToDetailResponse(updatedContract);
    }
    // ================= 9. XÓA HỢP ĐỒNG NHÁP (ĐÃ TỐI ƯU DỌN USER RÁC) =================
    @Transactional
    public void deleteContract(UUID contractId, UUID currentUserId) {

        Contract contract = contractRepository.findById(contractId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy hợp đồng!"));

        if (!contract.getRoom().getArea().getLandlord().getId().equals(currentUserId)) {
            throw new RuntimeException("Bạn không có quyền xóa hợp đồng của khu trọ khác!");
        }

        if (contract.getStatus() != ContractStatus.DRAFT) {
            throw new RuntimeException("Chỉ được phép xóa hợp đồng Nháp!");
        }

        //KHÁCH THUÊ TRƯỚC KHI XÓA HỢP ĐỒNG
        UUID tenantId = contract.getTenant().getId();
        Room room = contract.getRoom();


        Optional<Deposit> linkedDeposit = depositRepository.findByContractId(contractId);
        if (linkedDeposit.isPresent()) {
            Deposit deposit = linkedDeposit.get();
            deposit.setStatus(DepositStatus.PENDING);
            deposit.setContract(null);
            depositRepository.save(deposit);
            room.setStatus(RoomStatus.DEPOSITED);
        } else {
            room.setStatus(RoomStatus.AVAILABLE);
        }
        roomRepository.save(room);

        // Ghi log hoạt động
        String logDesc = String.format("Xóa bản nháp hợp đồng của phòng %s", room.getRoomNumber());
        activityLog.createLog(contract.getRoom().getArea().getLandlord(), "DELETE_CONTRACT", "contracts", contract.getId(), logDesc);

        // Thực hiện xóa hợp đồng
        contractRepository.delete(contract);

        // Sau khi tờ hợp đồng này bay màu, ta đếm xem người khách này còn tờ hợp đồng nào khác không?
        long remainingContracts = contractRepository.countByTenantId(tenantId);

        if (remainingContracts == 0) {
            // Nếu bằng 0, chứng tỏ tài khoản User này được sinh ra chỉ cho cái hợp đồng nháp vừa bị hủy.
            // Tiến hành kích hoạt hàm deleteUser tinh gọn bên UserService để quét sạch tài khoản rác này!
            System.out.println("Phát hiện tài khoản khách vãng lai không có hợp đồng thực tế. Tiến hành dọn dẹp...");
            userService.deleteUser(tenantId);
        }
    }
    // ================= 10. KHÁCH THUÊ KÝ HỢP ĐỒNG ĐIỆN TỬ =================
    @Transactional
    public ContractDetailResponse signContract(UUID contractId, MultipartFile signatureImage, UUID currentUserId) {

        // 1. Kiểm tra file chữ ký
        if (signatureImage == null || signatureImage.isEmpty()) {
            throw new RuntimeException("Vui lòng cung cấp hình ảnh chữ ký hợp lệ!");
        }

        // 2. Lấy thông tin hợp đồng
        Contract contract = contractRepository.findById(contractId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy hợp đồng!"));

        // 3. Chốt chặn bảo mật: Chỉ người đứng tên hợp đồng mới được quyền ký
        if (!contract.getTenant().getId().equals(currentUserId)) {
            throw new RuntimeException("Truy cập bị từ chối! Bạn không phải là người đứng tên trên hợp đồng này.");
        }

        // 4. Chốt chặn trạng thái: Chỉ hợp đồng Nháp mới được ký
        if (contract.getStatus() != ContractStatus.DRAFT) {
            throw new RuntimeException("Hợp đồng này đã được ký hoặc không còn ở trạng thái chờ xác nhận!");
        }

        // 5. Upload chữ ký của khách thuê lên Cloudinary
        String signatureUrl = cloudinaryService.uploadFile(signatureImage, "tenant_signatures");

        // 6. Cập nhật dữ liệu Hợp đồng
        contract.setTenantSignature(signatureUrl);
        contract.setStatus(ContractStatus.SIGNED);
        String currentTerms = contract.getContractTerms();
        if (currentTerms != null) {
            // Thay thế đoạn chữ đỏ chờ ký bằng thẻ <img> chứa chữ ký thật của khách thuê
            String signedTerms = currentTerms.replace(
                    "<span style='color:red; font-weight:bold;'>[Chờ khách thuê ký điện tử]</span>",
                    String.format("<img src='%s' width='150'/>", signatureUrl)
            );
            contract.setContractTerms(signedTerms);
        }

        // 7. Cập nhật dữ liệu Phòng
        Room room = contract.getRoom();
        room.setStatus(RoomStatus.RENTED);

        // 8. Lưu xuống DB
        contractRepository.save(contract);
        roomRepository.save(room);

        // 9. Ghi log hệ thống
        String logDesc = String.format("Khách thuê xác nhận ký hợp đồng điện tử. Phòng %s chính thức chuyển sang trạng thái Đang thuê.",
                room.getRoomNumber());
        activityLog.createLog(contract.getTenant(), "SIGN_CONTRACT", "contracts", contract.getId(), logDesc);


        // 10. BẮN THÔNG BÁO CHO CHỦ TRỌ

        User landlord = room.getArea().getLandlord();
        String tenantName = contract.getTenant().getFullName();
        String roomNumber = room.getRoomNumber();

        String title = "Hợp đồng đã được ký";
        String content = String.format("Khách thuê %s đã xác nhận chữ ký điện tử cho phòng %s. Hợp đồng đã chính thức có hiệu lực!", tenantName, roomNumber);

        // Chỉ cần gọi duy nhất 1 dòng này!
        notificationService.createNotification(landlord, title, content, NotificationType.CONTRACT_SIGNED);

        // 11. Trả về hợp đồng đã cập nhật
        return mapToDetailResponse(contract);
    }
    // ================= 11. TỰ ĐỘNG QUÉT HỢP ĐỒNG HẾT HẠN VÀ GỬI THÔNG BÁO =================

    @Transactional
    public void autoCheckAndExpireContracts() {

        LocalDate today = LocalDate.now();

        // 1. Tìm tất cả hợp đồng đang ký (SIGNED) mà hạn chót đã trôi qua
        List<Contract> expiredContracts = contractRepository.findByStatusAndEndDateBefore(ContractStatus.SIGNED, today);

        if (expiredContracts.isEmpty()) {
            System.out.println("Hôm nay không có hợp đồng nào hết hạn.");
            return;
        }

        System.out.println("Bắt đầu xử lý " + expiredContracts.size() + " hợp đồng hết hạn...");

        // 2. Xử lý từng hợp đồng
        for (Contract contract : expiredContracts) {

            // Bước A: Cập nhật trạng thái hợp đồng thành HẾT HẠN
            contract.setStatus(ContractStatus.EXPIRED);
            contractRepository.save(contract);

            // Bước B: Tạo Thông Báo gửi đến Chủ trọ
            User landlord = contract.getRoom().getArea().getLandlord();
            String roomNum = contract.getRoom().getRoomNumber();

            String title = "Hợp đồng hết hạn";
            String content = String.format("Hợp đồng thuê phòng %s đã chính thức hết hạn vào ngày %s. Vui lòng liên hệ khách thuê để tiến hành Thanh lý hợp đồng hoặc Gia hạn.", roomNum, contract.getEndDate().toString());

            // Chỉ cần gọi duy nhất 1 dòng này!
            notificationService.createNotification(landlord, title, content, NotificationType.CONTRACT_EXPIRED);

            // Bước C: Ghi log hệ thống
            String logDesc = String.format("Hệ thống tự động khóa hợp đồng phòng %s do quá hạn. Đã gửi thông báo cho chủ trọ.", roomNum);
            activityLog.createLog(landlord, "AUTO_EXPIRE_CONTRACT", "contracts", contract.getId(), logDesc);
        }

        System.out.println("Hoàn tất quét hợp đồng và gửi thông báo!");
    }

    // ================= 12. GIA HẠN HỢP ĐỒNG =================
    @Transactional
    public ContractDetailResponse extendContract(UUID contractId, ContractExtendRequest request, UUID currentUserId) {

        // 1. Tìm hợp đồng
        Contract contract = contractRepository.findById(contractId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy hợp đồng!"));

        // 2. Chốt chặn bảo mật
        if (!contract.getRoom().getArea().getLandlord().getId().equals(currentUserId)) {
            throw new RuntimeException("Bạn không có quyền gia hạn hợp đồng của khu trọ khác!");
        }

        // 3. Chốt chặn nghiệp vụ
        if (contract.getStatus() != ContractStatus.SIGNED && contract.getStatus() != ContractStatus.EXPIRED) {
            throw new RuntimeException("Chỉ có thể gia hạn hợp đồng đang có hiệu lực (SIGNED) hoặc vừa hết hạn (EXPIRED)!");
        }

        if (request.getNewEndDate() == null || !request.getNewEndDate().isAfter(contract.getEndDate())) {
            throw new RuntimeException("Ngày gia hạn mới bắt buộc phải nằm sau ngày kết thúc cũ!");
        }

        // 4. Cập nhật dữ liệu
        contract.setEndDate(request.getNewEndDate());

        // Nếu hợp đồng trước đó đã bị Cron Job quét và chuyển thành EXPIRED -> Hồi sinh nó
        if (contract.getStatus() == ContractStatus.EXPIRED) {
            contract.setStatus(ContractStatus.SIGNED);

            Room room = contract.getRoom();
            room.setStatus(RoomStatus.RENTED); // Đóng phòng lại để không ai thuê được
            roomRepository.save(room);
        }

        contractRepository.save(contract);

        // 5. Ghi log hoạt động
        String logDesc = String.format("Chủ trọ gia hạn hợp đồng phòng %s đến ngày %s",
                contract.getRoom().getRoomNumber(), request.getNewEndDate().toString());
        activityLog.createLog(contract.getRoom().getArea().getLandlord(), "EXTEND_CONTRACT", "contracts", contract.getId(), logDesc);

        // 6. Bắn thông báo báo hỉ cho Khách thuê
        String title = "Hợp đồng đã được gia hạn";
        String content = String.format("Chủ trọ đã gia hạn thời gian thuê phòng %s của bạn đến ngày %s. Chúc bạn có trải nghiệm lưu trú tuyệt vời!",
                contract.getRoom().getRoomNumber(), request.getNewEndDate().toString());

        // (Lưu ý: Bạn có thể tạo thêm enum NotificationType.SYSTEM hoặc tái sử dụng CONTRACT_SIGNED)
        notificationService.createNotification(contract.getTenant(), title, content, NotificationType.CONTRACT_EXTEND);

        // 7. Trả về dữ liệu mới
        return mapToDetailResponse(contract);
    }
    // ================= HÀM PHỤ TRỢ: BIÊN DỊCH VĂN BẢN HỢP ĐỒNG =================
    private String compileContractTerms(ContractTemplate template, Contract contract, User landlord, User tenant, Room room) {
        String html = template.getContent();

        // 1. Thay thế các biến giữ chỗ bằng dữ liệu thật
        html = html.replace("{{START_DATE}}", contract.getStartDate() != null ? contract.getStartDate().toString() : "")
                .replace("{{END_DATE}}", contract.getEndDate() != null ? contract.getEndDate().toString() : "")
                .replace("{{LANDLORD_NAME}}", landlord.getFullName() != null ? landlord.getFullName() : "")
                .replace("{{TENANT_NAME}}", tenant.getFullName() != null ? tenant.getFullName() : "")
                .replace("{{ROOM_NUMBER}}", room.getRoomNumber())
                .replace("{{RENT_PRICE}}", room.getRentPrice().toString());

        // 2. Chèn chữ ký số của Chủ trọ (Chủ trọ đã cài đặt từ trước)
        String landlordSig = landlord.getLandlordSignature();
        if (landlordSig != null && !landlordSig.trim().isEmpty()) {
            // Chèn ảnh chữ ký với chiều rộng 150px cho đẹp
            html = html.replace("{{LANDLORD_SIGNATURE_PLACEHOLDER}}",
                    String.format("<img src='%s' width='150'/>", landlordSig));
        } else {
            html = html.replace("{{LANDLORD_SIGNATURE_PLACEHOLDER}}", "[Chưa có chữ ký]");
        }

        // 3. Khách thuê lúc này chưa ký, nên hiển thị dòng chữ cảnh báo màu đỏ
        html = html.replace("{{TENANT_SIGNATURE_PLACEHOLDER}}", "<span style='color:red; font-weight:bold;'>[Chờ khách thuê ký điện tử]</span>");

        return html;
    }
    @Transactional(readOnly = true)
    public byte[] downloadContractPdf(UUID contractId, UUID currentUserId) {
        Contract contract = contractRepository.findById(contractId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy hợp đồng!"));

        boolean isLandlord = contract.getRoom().getArea().getLandlord().getId().equals(currentUserId);
        boolean isTenant = contract.getTenant().getId().equals(currentUserId);

        if (!isLandlord && !isTenant) {
            throw new RuntimeException("Truy cập bị từ chối! Bạn không có quyền tải hợp đồng này.");
        }

        return pdfExportService.generatePdfFromHtml(contract.getContractTerms());
    }
    // ================= 13. TẢI LÊN FILE HỢP ĐỒNG (BẢN SCAN / BẢN MỀM) =================
    @Transactional
    public ContractDetailResponse uploadContractFile(UUID contractId, MultipartFile file, UUID currentUserId) {

        // 1. Kiểm tra đầu vào
        if (file == null || file.isEmpty()) {
            throw new RuntimeException("Vui lòng chọn file để tải lên!");
        }

        // 2. Tìm hợp đồng dưới DB
        Contract contract = contractRepository.findById(contractId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy hợp đồng!"));

        // 3. Chốt chặn bảo mật: Chỉ Chủ trọ mới được quyền tải file đính kèm lên
        if (!contract.getRoom().getArea().getLandlord().getId().equals(currentUserId)) {
            throw new RuntimeException("Truy cập bị từ chối! Chỉ chủ trọ của hợp đồng này " +
                    "mới có quyền tải lên file cho hợp đồng này.");
        }

        // 4. Gọi CloudinaryService để đẩy file lên cloud
        String uploadedUrl = cloudinaryService.uploadFile(file, "contract_files");

        // 5. Cập nhật URL vào Entity và lưu DB
        contract.setContractFileUrl(uploadedUrl);
        contractRepository.save(contract);

        // 6. Ghi log hoạt động
        String logDesc = String.format("Tải lên file đính kèm cho hợp đồng phòng %s", contract.getRoom().getRoomNumber());
        activityLog.createLog(contract.getRoom().getArea().getLandlord(), "UPLOAD_CONTRACT_FILE", "contracts", contract.getId(), logDesc);

        // 7. Trả về chi tiết hợp đồng đã được cập nhật
        return mapToDetailResponse(contract);
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
                .rentPrice(contract.getRoom().getRentPrice())
                .status(contract.getStatus())
                .contractFileUrl(contract.getContractFileUrl())
                .contractTerms(contract.getContractTerms())
                .members(memberResponses) // Nhúng danh sách thành viên vào đây
                .build();
    }


    // Hàm phụ trợ
    private String generateRandomPassword() {
        Random random = new Random();
        return String.valueOf(100000 + random.nextInt(900000));
    }
}