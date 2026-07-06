package ut.edu.be_quanlytro.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException; // Thêm import 403
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import ut.edu.be_quanlytro.Dto.Request.*;
import ut.edu.be_quanlytro.Dto.Response.*;
import ut.edu.be_quanlytro.Entity.*;
import ut.edu.be_quanlytro.Entity.Enum.*;
import ut.edu.be_quanlytro.Exception.BadRequestException; // Thêm import 400
import ut.edu.be_quanlytro.Exception.ResourceNotFoundException; // Thêm import 404
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
    private final InvoiceRepository invoiceRepository;
    private final InvoiceDetailRepository invoiceDetailRepository;
    private final PaymentRepository  paymentRepository;

    // Tận dụng lại các Service đã có
    private final UserService userService;
    private final ActivityLogService activityLog;
    private final DepositRepository depositRepository;
    private final OcrService  ocrService;
    private final CloudinaryService cloudinaryService;
    private final NotificationService notificationService;
    private final ContractTemplateRepository templateRepository;

    private final ContractHtmlCompiler contractHtmlCompiler;


    // ================= 1. KHỞI TẠO HỢP ĐỒNG (Quét CCCD)=================
    @Transactional
    public ContractCreateResponse createContract(ContractCreateRequest request, MultipartFile frontImage, MultipartFile backImage, UUID currentUserId) {

        // 1. KIỂM TRA PHÒNG VÀ QUYỀN CHỦ TRỌ
        Room room = roomRepository.findById(request.getRoomId())
                .orElseThrow(() -> new ResourceNotFoundException("Phòng không tồn tại"));

        User landlord = room.getArea().getLandlord();
        if (!landlord.getId().equals(currentUserId)) {
            throw new AccessDeniedException("Bạn không có quyền tạo hợp đồng cho phòng thuộc khu trọ khác");
        }

        if (landlord.getLandlordSignature() == null || landlord.getLandlordSignature().isEmpty()) {
            throw new BadRequestException("Vui lòng thiết lập chữ ký số cá nhân trước khi lập hợp đồng!");
        }
        if (landlord.getIdCardNumber() == null || landlord.getIdCardNumber().isEmpty() ||
                landlord.getHometown() == null || landlord.getHometown().isEmpty()) {
            throw new BadRequestException("Vui lòng cập nhật đầy đủ số CCCD và Quê quán trong Hồ sơ cá nhân trước khi lập hợp đồng!");
        }

        //Chỉ cho phép tạo hợp đồng khi phòng trống hoặc phòng đã nhận cọc
        if (room.getStatus() != RoomStatus.AVAILABLE && room.getStatus() != RoomStatus.DEPOSITED) {
            throw new BadRequestException("Phòng hiện không ở trạng thái sẵn sàng để lập hợp đồng (Đang ở, bảo trì hoặc đang chờ khách khác ký)!");
        }

        Deposit pendingDeposit = null;

        if (request.getDepositId() != null) {
            // Tìm phiếu cọc theo ID truyền vào
            pendingDeposit = depositRepository.findById(request.getDepositId())
                    .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy phiếu đặt cọc với ID đã cung cấp!"));

            // Kiểm tra chéo 1: Phiếu cọc này có đúng là của phòng đang lập hợp đồng không?
            if (!pendingDeposit.getRoom().getId().equals(room.getId())) {
                throw new BadRequestException("Phiếu đặt cọc này không thuộc về phòng bạn đang chọn!");
            }

            // Kiểm tra chéo 2: Phiếu cọc còn hiệu lực không?
            if (pendingDeposit.getStatus() != DepositStatus.PENDING) {
                throw new BadRequestException("Phiếu đặt cọc này đã được xử lý (đã lên hợp đồng) hoặc đã bị hủy!");
            }

            // Kiểm tra chéo 3: SĐT người làm hợp đồng có khớp với SĐT người đã cọc không?
            if (!pendingDeposit.getPhone().equals(request.getTenantPhone())) {
                throw new BadRequestException("Số điện thoại khách thuê (" + request.getTenantPhone() +
                        ") không khớp với số điện thoại trên phiếu cọc (" + pendingDeposit.getPhone() + ")!");
            }
        }

        // 3. GỌI FPT AI ĐỂ QUÉT CCCD
        // Việc quét lỗi hay thiếu ảnh sẽ được OcrService quăng lỗi (throw BadRequestException) và dừng luồng ngay lập tức
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
                    .orElseThrow(() -> new ResourceNotFoundException("Lỗi truy xuất tài khoản khách sau khi tạo"));
        } else {
            rawPassword = "Khách đã có tài khoản (Dùng mật khẩu cũ)";
        }


        // 5. LẤY MẪU HỢP ĐỒNG VÀ KHỞI TẠO

        ContractTemplate template = templateRepository.findByLandlordIdAndIsActiveTrue(currentUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Bạn chưa thiết lập Mẫu hợp đồng mặc định! Vui lòng vào mục Quản lý mẫu hợp đồng để kích hoạt một mẫu."));

        // Khởi tạo đối tượng Hợp đồng
        Contract contract = Contract.builder()
                .room(room)
                .tenant(tenant)
                .creator(landlord)
                .template(template)
                .startDate(request.getStartDate())
                .endDate(request.getEndDate())
                .landlordSignature(landlord.getLandlordSignature())
                .depositAmount(pendingDeposit != null ? pendingDeposit.getDepositAmount() : request.getDepositAmount())
                .status(ContractStatus.DRAFT)
                .members(new ArrayList<>())
                .build();

        String compiledHtml = contractHtmlCompiler.compileContractTerms(template, contract, landlord, tenant, room);
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
                .orElseThrow(() -> new ResourceNotFoundException("Phòng không tồn tại"));

        User landlord = room.getArea().getLandlord();
        if (!landlord.getId().equals(currentUserId)) {
            throw new AccessDeniedException("Bạn không có quyền tạo hợp đồng cho phòng thuộc khu trọ khác");
        }

        if (landlord.getLandlordSignature() == null || landlord.getLandlordSignature().isEmpty()) {
            throw new BadRequestException("Vui lòng thiết lập chữ ký số cá nhân trước khi lập hợp đồng!");
        }
        if (landlord.getIdCardNumber() == null || landlord.getIdCardNumber().isEmpty() ||
                landlord.getHometown() == null || landlord.getHometown().isEmpty()) {
            throw new BadRequestException("Vui lòng cập nhật đầy đủ số CCCD và Quê quán trong Hồ sơ cá nhân trước khi lập hợp đồng!");
        }

        // Chỉ cho phép tạo hợp đồng khi phòng trống hoặc phòng đã nhận cọc
        if (room.getStatus() != RoomStatus.AVAILABLE && room.getStatus() != RoomStatus.DEPOSITED) {
            throw new BadRequestException("Phòng hiện không ở trạng thái sẵn sàng để lập hợp đồng!");
        }

        // 2. KIỂM TRA ĐẶT CỌC
        Deposit pendingDeposit = null;
        if (request.getDepositId() != null) {
            pendingDeposit = depositRepository.findById(request.getDepositId())
                    .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy phiếu đặt cọc với ID đã cung cấp!"));

            if (!pendingDeposit.getRoom().getId().equals(room.getId())) {
                throw new BadRequestException("Phiếu đặt cọc này không thuộc về phòng bạn đang chọn!");
            }

            if (pendingDeposit.getStatus() != DepositStatus.PENDING) {
                throw new BadRequestException("Phiếu đặt cọc này đã được xử lý hoặc đã bị hủy!");
            }

            if (!pendingDeposit.getPhone().equals(request.getTenantPhone())) {
                throw new BadRequestException("Số điện thoại khách không khớp với phiếu cọc!");
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
                    .orElseThrow(() -> new ResourceNotFoundException("Lỗi truy xuất tài khoản khách sau khi tạo"));
        } else {
            rawPassword = "Khách đã có tài khoản (Dùng mật khẩu cũ)";
        }


        // 5. LẤY MẪU HỢP ĐỒNG VÀ KHỞI TẠO

        ContractTemplate template = templateRepository.findByLandlordIdAndIsActiveTrue(currentUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Bạn chưa thiết lập Mẫu hợp đồng mặc định! Vui lòng vào mục Quản lý mẫu hợp đồng để kích hoạt một mẫu."));

        // Khởi tạo đối tượng Hợp đồng
        Contract contract = Contract.builder()
                .room(room)
                .tenant(tenant)
                .creator(landlord)
                .template(template)
                .startDate(request.getStartDate())
                .endDate(request.getEndDate())
                .landlordSignature(landlord.getLandlordSignature())
                .depositAmount(pendingDeposit != null ? pendingDeposit.getDepositAmount() : request.getDepositAmount())
                .status(ContractStatus.DRAFT)
                .members(new ArrayList<>())
                .build();

        String compiledHtml = contractHtmlCompiler.compileContractTerms(template, contract, landlord, tenant, room);
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
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy hợp đồng với ID cung cấp!"));

        // 2. Chốt chặn bảo mật (Chỉ Chủ trọ của khu trọ đó mới được xem)
        boolean isLandlord = contract.getRoom().getArea().getLandlord().getId().equals(currentUserId);

        if (!isLandlord) {
            throw new AccessDeniedException("Bạn không có quyền quản lý, không thể xem thông tin của hợp đồng này!");
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
                .orElseThrow(() -> new ResourceNotFoundException("Bạn hiện tại chưa có hợp đồng nào đang chờ ký hoặc đang hoạt động trong hệ thống!"));

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
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy hợp đồng với ID đã cung cấp!"));

        // 2. Chốt chặn bảo mật (Chỉ Chủ trọ quản lý phòng này mới được thêm người)
        boolean isLandlord = contract.getRoom().getArea().getLandlord().getId().equals(currentUserId);
        if (!isLandlord) {
            throw new AccessDeniedException("Bạn không có quyền thêm thành viên vào hợp đồng của khu trọ khác!");
        }

        // 3. Chốt chặn nghiệp vụ (Chỉ cho phép thêm khi hợp đồng đang DRAFT hoặc ACTIVE)
        if (contract.getStatus() != ContractStatus.DRAFT && contract.getStatus() != ContractStatus.SIGNED) {
            throw new BadRequestException("Chỉ có thể thêm thành viên khi hợp đồng đang ở trạng thái Nháp hoặc Đang hoạt động!");
        }

        // 4. Kiểm tra trùng lặp (Ngăn chặn thêm 1 người 2 lần)
        boolean isExist = contract.getMembers().stream()
                .anyMatch(member -> member.getIdCardNumber().equals(request.getIdCardNumber())
                        || member.getPhone().equals(request.getPhone()));
        if (isExist) {
            throw new BadRequestException("Thành viên với Số điện thoại hoặc CCCD này đã tồn tại trong hợp đồng!");
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
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy hợp đồng!"));

        // 2. Chốt chặn bảo mật
        if (!contract.getRoom().getArea().getLandlord().getId().equals(currentUserId)) {
            throw new AccessDeniedException("Bạn không có quyền thanh lý hợp đồng này!");
        }

        // 3. Kiểm tra trạng thái hợp đồng
        if (contract.getStatus() != ContractStatus.SIGNED) {
            throw new BadRequestException("Chỉ có thể thanh lý hợp đồng đang ở trạng thái SIGNED");
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
    public ContractDetailResponse updateContract(UUID contractId, ContractUpdateRequest request, MultipartFile file, UUID currentUserId) {

        // 1. TÌM HỢP ĐỒNG VÀ CHỐT CHẶN BẢO MẬT
        Contract contract = contractRepository.findById(contractId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy hợp đồng!"));

        if (!contract.getRoom().getArea().getLandlord().getId().equals(currentUserId)) {
            throw new AccessDeniedException("Bạn không có quyền chỉnh sửa hợp đồng này!");
        }

        if (contract.getStatus() != ContractStatus.DRAFT) {
            throw new BadRequestException("Lỗi: Chỉ có thể chỉnh sửa điều khoản khi hợp đồng đang là Bản Nháp. Hợp đồng đã ký không được phép thay đổi!");
        }

        boolean isDataChanged = false; // Biến cờ hiệu quyết định việc in lại HTML

        // =================================================================
        // 2. CẬP NHẬT THÔNG TIN CƠ BẢN (Ngày tháng, Tiền cọc, Mẫu hợp đồng)
        // =================================================================
        if (request.getStartDate() != null && !request.getStartDate().equals(contract.getStartDate())) {
            contract.setStartDate(request.getStartDate());
            isDataChanged = true;
        }
        if (request.getEndDate() != null && !request.getEndDate().equals(contract.getEndDate())) {
            contract.setEndDate(request.getEndDate());
            isDataChanged = true;
        }
        if (request.getDepositAmount() != null) {
            if (contract.getDepositAmount() == null || contract.getDepositAmount().compareTo(request.getDepositAmount()) != 0) {
                contract.setDepositAmount(request.getDepositAmount());
                isDataChanged = true;
            }
        }
        if (request.getTemplateId() != null &&
                (contract.getTemplate() == null || !request.getTemplateId().equals(contract.getTemplate().getId()))) {

            ContractTemplate newTemplate = templateRepository.findById(request.getTemplateId())
                    .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy mẫu hợp đồng mới!"));
            if (!newTemplate.getLandlord().getId().equals(currentUserId)) {
                throw new AccessDeniedException("Mẫu hợp đồng này không thuộc quyền sở hữu của bạn!");
            }
            contract.setTemplate(newTemplate);
            isDataChanged = true;
        }

        // =================================================================
        // 3. CẬP NHẬT THÔNG TIN KHÁCH THUÊ CHÍNH (MAIN TENANT)
        // =================================================================
        User tenant = contract.getTenant();
        boolean isTenantChanged = false;

        if (request.getTenantFullName() != null && !request.getTenantFullName().equals(tenant.getFullName())) {
            tenant.setFullName(request.getTenantFullName());
            isTenantChanged = true;
        }
        if (request.getTenantIdCardNumber() != null && !request.getTenantIdCardNumber().equals(tenant.getIdCardNumber())) {
            tenant.setIdCardNumber(request.getTenantIdCardNumber());
            isTenantChanged = true;
        }
        if (request.getTenantDob() != null && !request.getTenantDob().equals(tenant.getDob())) {
            tenant.setDob(request.getTenantDob());
            isTenantChanged = true;
        }
        if (request.getTenantHometown() != null && !request.getTenantHometown().equals(tenant.getHometown())) {
            tenant.setHometown(request.getTenantHometown());
            isTenantChanged = true;
        }

        if (isTenantChanged) {
            userRepository.save(tenant);
            isDataChanged = true;

            // Đồng bộ thông tin vào bảng ContractMember (để lúc hiển thị danh sách người ở không bị lệch)
            contract.getMembers().stream()
                    .filter(m -> m.getPhone().equals(tenant.getPhone()))
                    .findFirst()
                    .ifPresent(mainMember -> {
                        mainMember.setFullName(tenant.getFullName());
                        mainMember.setIdCardNumber(tenant.getIdCardNumber());
                        mainMember.setDob(tenant.getDob());
                        mainMember.setHometown(tenant.getHometown());
                    });
        }

        // =================================================================
        // 4. CẬP NHẬT DANH SÁCH THÀNH VIÊN Ở GHÉP (CO-TENANTS)
        // =================================================================
        if (request.getMembers() != null) {
            String mainTenantPhone = tenant.getPhone();

            // Nhờ orphanRemoval = true, lệnh removeIf này sẽ ra lệnh cho Database xóa hẳn các thành viên cũ
            contract.getMembers().removeIf(m -> !m.getPhone().equals(mainTenantPhone));

            // Thêm danh sách thành viên mới từ Request
            for (ContractMemberAddRequest memberReq : request.getMembers()) {
                // Bỏ qua nếu frontend lỡ gửi kèm số điện thoại của người đại diện vào list này
                if (memberReq.getPhone().equals(mainTenantPhone)) continue;

                ContractMember newMember = ContractMember.builder()
                        .contract(contract)
                        .fullName(memberReq.getFullName())
                        .phone(memberReq.getPhone())
                        .idCardNumber(memberReq.getIdCardNumber())
                        .dob(memberReq.getDob())
                        .hometown(memberReq.getHometown())
                        .joinedAt(LocalDate.now())
                        .build();
                contract.getMembers().add(newMember);
            }
            isDataChanged = true;
        }

        // =================================================================
        // 5. RENDER LẠI BẢN CHỤP HTML NẾU CÓ THAY ĐỔI
        // =================================================================
        if (isDataChanged) {
            String newCompiledHtml = contractHtmlCompiler.compileContractTerms(
                    contract.getTemplate(),
                    contract,
                    contract.getCreator(),
                    contract.getTenant(),
                    contract.getRoom()
            );
            contract.setContractTerms(newCompiledHtml);
        }

        // =================================================================
        // 6. XỬ LÝ FILE ĐÍNH KÈM (CLOUDINARY)
        // =================================================================
        if (file != null && !file.isEmpty()) {
            String oldFileUrl = contract.getContractFileUrl();
            if (oldFileUrl != null && !oldFileUrl.trim().isEmpty()) {
                try {
                    cloudinaryService.deleteFile(oldFileUrl);
                } catch (Exception e) {
                    System.err.println("Cảnh báo: Không thể xóa file hợp đồng cũ trên Cloud - " + e.getMessage());
                }
            }
            String newFileUrl = cloudinaryService.uploadFile(file, "contract_files");
            contract.setContractFileUrl(newFileUrl);
        }

        // =================================================================
        // 7. LƯU DATABASE & GHI LOG
        // =================================================================
        Contract updatedContract = contractRepository.save(contract);

        String logDesc = String.format("Cập nhật thông tin bản nháp hợp đồng phòng %s", contract.getRoom().getRoomNumber());
        activityLog.createLog(contract.getRoom().getArea().getLandlord(), "UPDATE_CONTRACT", "contracts", updatedContract.getId(), logDesc);

        return mapToDetailResponse(updatedContract);
    }
    // ================= 9. XÓA HỢP ĐỒNG (BẢN NHÁP & QUÁ HẠN - DỌN RÁC TRIỆT ĐỂ) =================
    @Transactional
    public void deleteContract(UUID contractId, UUID currentUserId) {

        Contract contract = contractRepository.findById(contractId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy hợp đồng!"));

        if (!contract.getRoom().getArea().getLandlord().getId().equals(currentUserId)) {
            throw new AccessDeniedException("Bạn không có quyền xóa hợp đồng của khu trọ khác!");
        }

        // CHỐT CHẶN: Chỉ cho xóa bản DRAFT (Nháp) hoặc EXPIRED (Quá hạn)
        if (contract.getStatus() != ContractStatus.DRAFT && contract.getStatus() != ContractStatus.EXPIRED) {
            throw new BadRequestException("Chỉ được phép xóa hợp đồng Nháp hoặc Hợp đồng đã Quá hạn!");
        }

        UUID tenantId = contract.getTenant().getId();
        Room room = contract.getRoom();

        // ==============================================================
        // 1. DỌN DẸP CLOUD (XÓA FILE PDF VÀ CHỮ KÝ ĐỂ TIẾT KIỆM DUNG LƯỢNG)
        // ==============================================================
        try {
            if (contract.getContractFileUrl() != null && !contract.getContractFileUrl().isEmpty()) {
                cloudinaryService.deleteFile(contract.getContractFileUrl());
            }
            if (contract.getTenantSignature() != null && !contract.getTenantSignature().isEmpty()) {
                cloudinaryService.deleteFile(contract.getTenantSignature());
            }
        } catch (Exception e) {
            System.err.println("Cảnh báo: Không thể xóa file trên Cloudinary - " + e.getMessage());
        }

        // ==============================================================
        // 2. XỬ LÝ LIÊN KẾT DATABASE (CỌC & HÓA ĐƠN) DỰA THEO TRẠNG THÁI
        // ==============================================================
        Optional<Deposit> linkedDeposit = depositRepository.findByContractId(contractId);

        if (contract.getStatus() == ContractStatus.DRAFT) {
            // NẾU LÀ DRAFT: GIỮ LẠI CỌC, gỡ liên kết và trả phòng về DEPOSITED
            if (linkedDeposit.isPresent()) {
                Deposit deposit = linkedDeposit.get();
                deposit.setStatus(DepositStatus.PENDING);
                deposit.setContract(null);
                depositRepository.save(deposit);

                room.setStatus(RoomStatus.DEPOSITED);
            } else {
                // Nếu trường hợp HĐ nháp này tạo ra mà không qua bước cọc
                room.setStatus(RoomStatus.AVAILABLE);
            }
            roomRepository.save(room);

        } else if (contract.getStatus() == ContractStatus.EXPIRED) {
            // NẾU LÀ EXPIRED: XÓA SẠCH CỌC
            if (linkedDeposit.isPresent()) {
                depositRepository.delete(linkedDeposit.get());
            }

            // DỌN RÁC 3 TẦNG: PAYMENT + INVOICE DETAIL -> INVOICE
            List<Invoice> oldInvoices = invoiceRepository.findByContractId(contractId);

            for (Invoice inv : oldInvoices) {
                invoiceDetailRepository.deleteAllByInvoiceId(inv.getId());
                paymentRepository.deleteAllByInvoiceId(inv.getId());
            }
            invoiceRepository.deleteAllByContractId(contractId);
        }

        // ==============================================================
        // 3. GHI LOG VÀ THỰC HIỆN XÓA HỢP ĐỒNG
        // ==============================================================
        String logDesc = String.format("Xóa triệt để hợp đồng [%s] của phòng %s.",
                contract.getStatus().name(), room.getRoomNumber());
        activityLog.createLog(contract.getRoom().getArea().getLandlord(), "DELETE_CONTRACT", "contracts", contract.getId(), logDesc);

        // Xóa Hợp đồng (Lúc này ContractMembers sẽ tự động bị xóa theo nhờ CascadeType.ALL)
        contractRepository.delete(contract);

        // ==============================================================
        // 4. DỌN DẸP USER RÁC (KHÁCH VÃNG LAI)
        // ==============================================================
        long remainingContracts = contractRepository.countByTenantId(tenantId);
        if (remainingContracts == 0) {
            System.out.println("Phát hiện tài khoản khách vãng lai không còn hợp đồng nào. Tiến hành dọn dẹp...");
            userService.deleteUser(tenantId);
        }
    }
    // ================= 10. KHÁCH THUÊ KÝ HỢP ĐỒNG ĐIỆN TỬ =================
    @Transactional
    public ContractDetailResponse signContract(UUID contractId, MultipartFile signatureImage, UUID currentUserId) {

        // 1. Kiểm tra file chữ ký
        if (signatureImage == null || signatureImage.isEmpty()) {
            throw new BadRequestException("Vui lòng cung cấp hình ảnh chữ ký hợp lệ!");
        }

        // 2. Lấy thông tin hợp đồng
        Contract contract = contractRepository.findById(contractId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy hợp đồng!"));

        // 3. Chốt chặn bảo mật: Chỉ người đứng tên hợp đồng mới được quyền ký
        if (!contract.getTenant().getId().equals(currentUserId)) {
            throw new AccessDeniedException("Truy cập bị từ chối! Bạn không phải là người đứng tên trên hợp đồng này.");
        }

        // 4. Chốt chặn trạng thái: Chỉ hợp đồng Nháp mới được ký
        if (contract.getStatus() != ContractStatus.DRAFT) {
            throw new BadRequestException("Hợp đồng này đã được ký hoặc không còn ở trạng thái chờ xác nhận!");
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

    // ================= 12. GIA HẠN HỢP ĐỒNG (BẰNG CÁCH TẠO BẢN KẾ THIẾT MỚI) =================
    @Transactional
    public ContractDetailResponse extendContract(UUID oldContractId, ContractExtendRequest request, UUID currentUserId) {

        // 1. TÌM HỢP ĐỒNG CŨ
        Contract oldContract = contractRepository.findById(oldContractId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy hợp đồng cũ!"));

        // 2. CHỐT CHẶN BẢO MẬT VÀ NGHIỆP VỤ
        if (!oldContract.getRoom().getArea().getLandlord().getId().equals(currentUserId)) {
            throw new AccessDeniedException("Bạn không có quyền gia hạn hợp đồng của khu trọ khác!");
        }

        if (oldContract.getStatus() != ContractStatus.SIGNED && oldContract.getStatus() != ContractStatus.EXPIRED) {
            throw new BadRequestException("Chỉ có thể gia hạn khi hợp đồng cũ đang có hiệu lực (SIGNED) hoặc vừa hết hạn (EXPIRED)!");
        }

        if (request.getNewEndDate() == null || !request.getNewEndDate().isAfter(oldContract.getEndDate())) {
            throw new BadRequestException("Ngày kết thúc mới bắt buộc phải nằm sau ngày kết thúc của hợp đồng cũ!");
        }

        // ==========================================================
        // BƯỚC QUAN TRỌNG 1: ĐÓNG BĂNG HỢP ĐỒNG CŨ (LƯU VÀO LỊCH SỬ)
        // ==========================================================
        oldContract.setStatus(ContractStatus.EXPIRED);
        contractRepository.save(oldContract);

        // ==========================================================
        // BƯỚC QUAN TRỌNG 2: KHỞI TẠO HỢP ĐỒNG MỚI DỰA TRÊN DỮ LIỆU CŨ
        // ==========================================================
        // Mặc định ngày bắt đầu của HĐ mới = Ngày kết thúc của HĐ cũ (hoặc tùy bạn định nghĩa thêm trong DTO)
        LocalDate newStartDate = oldContract.getEndDate();

        Contract newContract = Contract.builder()
                .room(oldContract.getRoom())
                .tenant(oldContract.getTenant())
                .creator(oldContract.getCreator())
                .template(oldContract.getTemplate())

                // Cập nhật thời hạn mới
                .startDate(newStartDate)
                .endDate(request.getNewEndDate())

                // Kế thừa dữ liệu tài chính & pháp lý
                .depositAmount(oldContract.getDepositAmount())
                .landlordSignature(oldContract.getLandlordSignature())
                .creator(oldContract.getCreator())
                //  Hợp đồng mới phải là DRAFT để đợi khách vào ký lại!
                .status(ContractStatus.DRAFT)
                .build();

        // ==========================================================
        // BƯỚC QUAN TRỌNG 3: SAO CHÉP DANH SÁCH KHÁCH Ở GHÉP
        // ==========================================================
        List<ContractMember> clonedMembers = oldContract.getMembers().stream().map(oldMember ->
                ContractMember.builder()
                        .contract(newContract) // Gắn vào hợp đồng mới
                        .fullName(oldMember.getFullName())
                        .phone(oldMember.getPhone())
                        .dob(oldMember.getDob())
                        .hometown(oldMember.getHometown())
                        .idCardNumber(oldMember.getIdCardNumber())
                        .joinedAt(oldMember.getJoinedAt()) // Giữ nguyên ngày vào ở ban đầu
                        .build()
        ).toList();
        newContract.setMembers(new ArrayList<>(clonedMembers));

        // ==========================================================
        // BƯỚC QUAN TRỌNG 4: RENDER LẠI BẢN CHỤP HTML (VÌ ĐÃ ĐỔI NGÀY)
        // ==========================================================
        String compiledHtml = contractHtmlCompiler.compileContractTerms(
                newContract.getTemplate(),
                newContract,
                newContract.getCreator(),
                newContract.getTenant(),
                newContract.getRoom()
        );
        newContract.setContractTerms(compiledHtml);

        // ==========================================================
        // BƯỚC QUAN TRỌNG 5: CHUYỂN DỊCH PHIẾU CỌC VÀ LƯU DATABASE
        // ==========================================================
        Contract savedNewContract = contractRepository.save(newContract);

        // Tìm phiếu cọc của hợp đồng cũ và "trỏ" nó sang hợp đồng mới để bảo toàn dữ liệu
        Optional<Deposit> linkedDeposit = depositRepository.findByContractId(oldContractId);
        if (linkedDeposit.isPresent()) {
            Deposit deposit = linkedDeposit.get();
            deposit.setContract(savedNewContract);
            depositRepository.save(deposit);
        }

        // Chuyển phòng về trạng thái CHỜ KÝ (RESERVED) vì hợp đồng mới đang là DRAFT
        Room room = oldContract.getRoom();
        room.setStatus(RoomStatus.RESERVED);
        roomRepository.save(room);

        // ==========================================================
        // BƯỚC QUAN TRỌNG 6: GHI LOG & BẮN THÔNG BÁO CHO KHÁCH
        // ==========================================================
        String logDesc = String.format("Chủ trọ gia hạn phòng %s (Chờ khách ký).", room.getRoomNumber());
        activityLog.createLog(oldContract.getCreator(), "EXTEND_CONTRACT", "contracts", savedNewContract.getId(), logDesc);

        String title = "Yêu cầu ký Hợp đồng gia hạn";
        String content = String.format("Chủ trọ đã tạo bản Hợp đồng gia hạn mới cho phòng %s (Từ ngày %s đến %s). Vui lòng vào ứng dụng để kiểm tra và xác nhận chữ ký điện tử nhé!",
                room.getRoomNumber(), newStartDate.toString(), request.getNewEndDate().toString());
        notificationService.createNotification(savedNewContract.getTenant(), title, content, NotificationType.CONTRACT_EXTEND);

        // Trả về DTO của cái hợp đồng MỚI
        return mapToDetailResponse(savedNewContract);
    }

    // ================= 13. TẢI LÊN FILE HỢP ĐỒNG (BẢN SCAN / BẢN MỀM) =================
    @Transactional
    public ContractDetailResponse uploadContractFile(UUID contractId, MultipartFile file, UUID currentUserId) {

        // 1. Kiểm tra đầu vào
        if (file == null || file.isEmpty()) {
            throw new BadRequestException("Vui lòng chọn file để tải lên!");
        }

        // 2. Tìm hợp đồng dưới DB
        Contract contract = contractRepository.findById(contractId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy hợp đồng!"));

        // 3. Chốt chặn bảo mật: Chỉ Chủ trọ mới được quyền tải file đính kèm lên
        if (!contract.getRoom().getArea().getLandlord().getId().equals(currentUserId)) {
            throw new AccessDeniedException("Truy cập bị từ chối! Chỉ chủ trọ của hợp đồng này " +
                    "mới có quyền tải lên file cho hợp đồng này.");
        }

        // 4. XÓA FILE CŨ (NẾU CÓ) ĐỂ TIẾT KIỆM DUNG LƯỢNG CLOUD
        String oldFileUrl = contract.getContractFileUrl();
        if (oldFileUrl != null && !oldFileUrl.trim().isEmpty()) {
            try {
                cloudinaryService.deleteFile(oldFileUrl);
            } catch (Exception e) {
                // Chỉ in log cảnh báo chứ không throw Exception làm chết luồng chính
                // Đề phòng trường hợp URL trong DB bị lỗi hoặc file đã bị xóa tay trên Cloudinary từ trước
                System.err.println("Cảnh báo: Không thể xóa file hợp đồng cũ trên Cloudinary: " + e.getMessage());
            }
        }

        // 5. Gọi CloudinaryService để đẩy file mới lên cloud
        String uploadedUrl = cloudinaryService.uploadFile(file, "contract_files");

        // 6. Cập nhật URL vào Entity và lưu DB
        contract.setContractFileUrl(uploadedUrl);
        contractRepository.save(contract);

        // 7. Ghi log hoạt động
        String logDesc = String.format("Cập nhật file đính kèm mới cho hợp đồng phòng %s", contract.getRoom().getRoomNumber());
        activityLog.createLog(contract.getRoom().getArea().getLandlord(), "UPLOAD_CONTRACT_FILE", "contracts", contract.getId(), logDesc);

        // 8. Trả về chi tiết hợp đồng đã được cập nhật
        return mapToDetailResponse(contract);
    }

    // ================= MAPPER =================
    private ContractDetailResponse mapToDetailResponse(Contract contract) {

        // 1. Map danh sách khách ở ghép (ContractMembers)
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
                // --- THÔNG TIN HỢP ĐỒNG CƠ BẢN ---
                .id(contract.getId())
                .startDate(contract.getStartDate())
                .endDate(contract.getEndDate())
                .depositAmount(contract.getDepositAmount())
                .status(contract.getStatus())
                .contractFileUrl(contract.getContractFileUrl())
                .contractTerms(contract.getContractTerms())
                //Thông tin khu trọ
                .areaName(contract.getRoom().getArea().getName())
                .areaAddress(contract.getRoom().getArea().getAddress())

                // --- THÔNG TIN TEMPLATE
                .templateId(contract.getTemplate() != null ? contract.getTemplate().getId() : null)

                // --- THÔNG TIN PHÒNG ---
                .roomId(contract.getRoom().getId())
                .roomNumber(contract.getRoom().getRoomNumber())
                .rentPrice(contract.getRoom().getRentPrice())

                // --- THÔNG TIN NGƯỜI TẠO (CHỦ TRỌ) ---
                .landlordName(contract.getCreator().getFullName())
                .landlordIdCardNumber(contract.getCreator().getIdCardNumber())
                .landlordHometown(contract.getCreator().getHometown())
                .landlordSignatureUrl(contract.getLandlordSignature())

                // --- THÔNG TIN KHÁCH THUÊ ĐỨNG TÊN ---
                .tenantId(contract.getTenant().getId())
                .tenantName(contract.getTenant().getFullName())
                .tenantPhone(contract.getTenant().getPhone())
                .tenantIdCardNumber(contract.getTenant().getIdCardNumber())
                .tenantHometown(contract.getTenant().getHometown())

                // --- DANH SÁCH THÀNH VIÊN ---
                .members(memberResponses)
                .build();
    }


    // Hàm phụ trợ
    private String generateRandomPassword() {
        Random random = new Random();
        return String.valueOf(100000 + random.nextInt(900000));
    }
}