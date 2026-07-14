package ut.edu.be_quanlytro.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import ut.edu.be_quanlytro.Dto.Request.*;
import ut.edu.be_quanlytro.Dto.Response.*;
import ut.edu.be_quanlytro.Entity.*;
import ut.edu.be_quanlytro.Entity.Enum.*;
import ut.edu.be_quanlytro.Exception.BadRequestException;
import ut.edu.be_quanlytro.Exception.ResourceNotFoundException;
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
    private final AreaServiceRepository areaServiceRepository;
    private final MeterReadingRepository meterReadingRepository;

    private final UserService userService;
    private final ActivityLogService activityLog;
    private final DepositRepository depositRepository;
    private final OcrService  ocrService;
    private final CloudinaryService cloudinaryService;
    private final NotificationService notificationService;
    private final CloudinaryCleanupService  cloudinaryCleanupService;
    private final ContractTemplateRepository templateRepository;

    private final ContractHtmlCompiler contractHtmlCompiler;


    @Transactional
    public ContractCreateResponse createContract(ContractCreateRequest request, MultipartFile frontImage, MultipartFile backImage, UUID currentUserId) {

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

        if (room.getStatus() != RoomStatus.AVAILABLE && room.getStatus() != RoomStatus.DEPOSITED) {
            throw new BadRequestException("Phòng hiện không ở trạng thái sẵn sàng để lập hợp đồng (Đang ở, bảo trì hoặc đang chờ khách khác ký)!");
        }

        Deposit pendingDeposit = null;

        if (request.getDepositId() != null) {
            pendingDeposit = depositRepository.findById(request.getDepositId())
                    .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy phiếu đặt cọc với ID đã cung cấp!"));

            if (!pendingDeposit.getRoom().getId().equals(room.getId())) {
                throw new BadRequestException("Phiếu đặt cọc này không thuộc về phòng bạn đang chọn!");
            }

            if (pendingDeposit.getStatus() != DepositStatus.PENDING) {
                throw new BadRequestException("Phiếu đặt cọc này đã được xử lý (đã lên hợp đồng) hoặc đã bị hủy!");
            }

            if (!pendingDeposit.getPhone().equals(request.getTenantPhone())) {
                throw new BadRequestException("Số điện thoại khách thuê (" + request.getTenantPhone() +
                        ") không khớp với số điện thoại trên phiếu cọc (" + pendingDeposit.getPhone() + ")!");
            }
        }

        OcrCccdResponse ocrData = ocrService.extractCccdData(frontImage, backImage);

        LocalDate parsedDob = null;
        try {
            java.time.format.DateTimeFormatter formatter = java.time.format.DateTimeFormatter.ofPattern("dd/MM/yyyy");
            parsedDob = LocalDate.parse(ocrData.getDob(), formatter);
        } catch (Exception e) {
            System.err.println("Cảnh báo: Không thể parse ngày sinh từ OCR (" + ocrData.getDob() + ")");
        }

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



        ContractTemplate template = templateRepository.findByLandlordIdAndIsActiveTrue(currentUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Bạn chưa thiết lập Mẫu hợp đồng mặc định! Vui lòng vào mục Quản lý mẫu hợp đồng để kích hoạt một mẫu."));

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

        Contract savedContract = contractRepository.save(contract);

        if (pendingDeposit != null) {
            pendingDeposit.setStatus(DepositStatus.COMPLETED);
            pendingDeposit.setContract(savedContract);
            depositRepository.save(pendingDeposit);
        }

        room.setStatus(RoomStatus.RESERVED);
        roomRepository.save(room);

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
    @Transactional
    public ContractCreateResponse createContractManual(ContractCreateManualRequest request, UUID currentUserId) {

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

        if (room.getStatus() != RoomStatus.AVAILABLE && room.getStatus() != RoomStatus.DEPOSITED) {
            throw new BadRequestException("Phòng hiện không ở trạng thái sẵn sàng để lập hợp đồng!");
        }

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

        String rawPassword = generateRandomPassword();
        User tenant = userRepository.findByPhone(request.getTenantPhone()).orElse(null);

        if (tenant == null) {
            UserCreateRequest userReq = new UserCreateRequest();
            userReq.setPhone(request.getTenantPhone());
            userReq.setPassword(rawPassword);
            userReq.setFullName(request.getTenantName());
            userReq.setRole(RoleType.TENANT);
            userReq.setDob(request.getTenantDob());
            userReq.setHometown(request.getTenantHometown());
            userReq.setIdCardNumber(request.getTenantIdCardNumber());

            UserResponse userResponse = userService.createUser(userReq, currentUserId);

            tenant = userRepository.findById(userResponse.getId())
                    .orElseThrow(() -> new ResourceNotFoundException("Lỗi truy xuất tài khoản khách sau khi tạo"));
        } else {
            rawPassword = "Khách đã có tài khoản (Dùng mật khẩu cũ)";
        }



        ContractTemplate template = templateRepository.findByLandlordIdAndIsActiveTrue(currentUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Bạn chưa thiết lập Mẫu hợp đồng mặc định! Vui lòng vào mục Quản lý mẫu hợp đồng để kích hoạt một mẫu."));

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

        Contract savedContract = contractRepository.save(contract);

        if (pendingDeposit != null) {
            pendingDeposit.setStatus(DepositStatus.COMPLETED);
            pendingDeposit.setContract(savedContract);
            depositRepository.save(pendingDeposit);
        }

        room.setStatus(RoomStatus.RESERVED);
        roomRepository.save(room);

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
    @Transactional(readOnly = true)
    public ContractDetailResponse getContractByIdForLandlord(UUID contractId, UUID currentUserId) {
        Contract contract = contractRepository.findById(contractId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy hợp đồng với ID cung cấp!"));

        boolean isLandlord = contract.getRoom().getArea().getLandlord().getId().equals(currentUserId);

        if (!isLandlord) {
            throw new AccessDeniedException("Bạn không có quyền quản lý, không thể xem thông tin của hợp đồng này!");
        }

        return mapToDetailResponse(contract);
    }

    @Transactional(readOnly = true)
    public ContractDetailResponse getMyCurrentContract(UUID tenantId) {

        List<ContractStatus> validStatuses = List.of(ContractStatus.DRAFT, ContractStatus.SIGNED);

        Contract currentContract = contractRepository.findFirstByTenantIdAndStatusInOrderByCreatedAtDesc(tenantId, validStatuses)
                .orElseThrow(() -> new ResourceNotFoundException("Bạn hiện tại chưa có hợp đồng nào đang chờ ký hoặc đang hoạt động trong hệ thống!"));

        return mapToDetailResponse(currentContract);
    }

    @Transactional(readOnly = true)
    public List<ContractDetailResponse> getContractsByArea(UUID areaId, UUID landlordId) {
        List<Contract> contracts = contractRepository.findByRoomAreaIdAndRoomAreaLandlordIdOrderByCreatedAtDesc(areaId, landlordId);

        return contracts.stream()
                .map(this::mapToDetailResponse)
                .toList();
    }
    @Transactional
    public ContractDetailResponse addContractMember(ContractMemberAddRequest request, UUID currentUserId) {

        Contract contract = contractRepository.findById(request.getContractId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy hợp đồng với ID đã cung cấp!"));

        boolean isLandlord = contract.getRoom().getArea().getLandlord().getId().equals(currentUserId);
        if (!isLandlord) {
            throw new AccessDeniedException("Bạn không có quyền thêm thành viên vào hợp đồng của khu trọ khác!");
        }

        if (contract.getStatus() != ContractStatus.DRAFT && contract.getStatus() != ContractStatus.SIGNED) {
            throw new BadRequestException("Chỉ có thể thêm thành viên khi hợp đồng đang ở trạng thái Nháp hoặc Đang hoạt động!");
        }

        boolean isExist = contract.getMembers().stream()
                .anyMatch(member -> member.getIdCardNumber().equals(request.getIdCardNumber())
                        || member.getPhone().equals(request.getPhone()));
        if (isExist) {
            throw new BadRequestException("Thành viên với Số điện thoại hoặc CCCD này đã tồn tại trong hợp đồng!");
        }

        ContractMember newMember = ContractMember.builder()
                .contract(contract)
                .fullName(request.getFullName())
                .phone(request.getPhone())
                .dob(request.getDob())
                .hometown(request.getHometown())
                .idCardNumber(request.getIdCardNumber())
                .joinedAt(LocalDate.now())
                .build();

        contract.getMembers().add(newMember);

        Contract savedContract = contractRepository.save(contract);

        String description = String.format("Thêm khách ở ghép: %s vào phòng %s",
                request.getFullName(), contract.getRoom().getRoomNumber());
        activityLog.createLog(contract.getRoom().getArea().getLandlord(), "ADD_MEMBER", "contracts", savedContract.getId(), description);

        return mapToDetailResponse(savedContract);
    }
    @Transactional
    public ContractTerminationResponse terminateContract(ContractTerminationRequest request, UUID currentUserId, UUID contractID) {

        Contract contract = contractRepository.findById(contractID)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy hợp đồng!"));

        if (!contract.getRoom().getArea().getLandlord().getId().equals(currentUserId)) {
            throw new AccessDeniedException("Bạn không có quyền thanh lý hợp đồng này!");
        }

        if (contract.getStatus() != ContractStatus.SIGNED) {
            throw new BadRequestException("Chỉ có thể thanh lý hợp đồng đang ở trạng thái SIGNED");
        }

        Room room = contract.getRoom();
        Area area = room.getArea();

        BigDecimal electricityCost = BigDecimal.ZERO;
        BigDecimal waterCost = BigDecimal.ZERO;

        List<AreaService> areaServices = areaServiceRepository.findByAreaIdAndIsActiveTrue(area.getId());

        for (AreaService service : areaServices) {
            if (service.getCalcType() == ServiceCalculationType.BY_INDEX) {
                String serviceName = service.getName().toLowerCase();
                Integer newIndexFromFE = null;

                if (serviceName.contains("điện")) {
                    newIndexFromFE = request.getElectricityUsage();
                } else if (serviceName.contains("nước")) {
                    newIndexFromFE = request.getWaterUsage();
                }

                if (newIndexFromFE != null) {
                    int oldIndex = 0;
                    Optional<MeterReading> lastReading = meterReadingRepository
                            .findFirstByRoomIdAndServiceIdOrderByCreatedAtDesc(room.getId(), service.getId());

                    if (lastReading.isPresent()) {
                        oldIndex = lastReading.get().getNewIndex();
                    }

                    if (newIndexFromFE < oldIndex) {
                        throw new BadRequestException(String.format(
                                "Lỗi: Chỉ số %s mới (%d) không được nhỏ hơn chỉ số cũ (%d)!",
                                service.getName(), newIndexFromFE, oldIndex));
                    }

                    int actualUsage = newIndexFromFE - oldIndex;
                    BigDecimal cost = service.getPrice().multiply(new BigDecimal(actualUsage));

                    if (serviceName.contains("điện")) {
                        electricityCost = cost;
                    } else {
                        waterCost = cost;
                    }

                    MeterReading finalReading = MeterReading.builder()
                            .room(room)
                            .service(service)
                            .oldIndex(oldIndex)
                            .newIndex(newIndexFromFE)
                            .isInvoiced(true)
                            .build();
                    meterReadingRepository.save(finalReading);
                }
            }
        }

        BigDecimal totalDeduction = electricityCost.add(waterCost);

        BigDecimal depositAmount = contract.getDepositAmount() != null ? contract.getDepositAmount() : BigDecimal.ZERO;
        BigDecimal offsetAmount = depositAmount.subtract(totalDeduction);

        String action;
        BigDecimal finalAmountToShow;

        if (offsetAmount.compareTo(BigDecimal.ZERO) > 0) {
            action = "HOÀN_TRẢ_KHÁCH";
            finalAmountToShow = offsetAmount;
        } else if (offsetAmount.compareTo(BigDecimal.ZERO) < 0) {
            action = "THU_THÊM_TỪ_KHÁCH";
            finalAmountToShow = offsetAmount.abs();
        } else {
            action = "HÒA_CÔNG_NỢ";
            finalAmountToShow = BigDecimal.ZERO;
        }

        contract.setStatus(ContractStatus.TERMINATED);
        room.setStatus(RoomStatus.AVAILABLE);

        contractRepository.save(contract);
        roomRepository.save(room);

        User tenant = contract.getTenant();

        List<ContractStatus> activeStatuses = List.of(ContractStatus.SIGNED, ContractStatus.DRAFT);
        long activeContractsCount = contractRepository.countByTenantIdAndStatusIn(tenant.getId(), activeStatuses);

        if (activeContractsCount == 0) {
            tenant.setPassword(generateRandomPassword() + UUID.randomUUID().toString());

            tenant.setPhone("[DELETED]_" + System.currentTimeMillis() + "_" + tenant.getPhone());

            userRepository.save(tenant);
            System.out.println("Tài khoản khách thuê đã được vô hiệu hóa và ẩn danh do không còn hợp đồng hiệu lực.");
        }

        String logDesc = String.format("Thanh lý hợp đồng phòng %s. %s: %s VNĐ",
                room.getRoomNumber(), action, finalAmountToShow);
        activityLog.createLog(area.getLandlord(), "TERMINATE_CONTRACT", "contracts", contract.getId(), logDesc);

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
    @Transactional
    public ContractDetailResponse updateContract(UUID contractId, ContractUpdateRequest request, MultipartFile file, UUID currentUserId) {

        Contract contract = contractRepository.findById(contractId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy hợp đồng!"));

        if (!contract.getRoom().getArea().getLandlord().getId().equals(currentUserId)) {
            throw new AccessDeniedException("Bạn không có quyền chỉnh sửa hợp đồng này!");
        }

        if (contract.getStatus() != ContractStatus.DRAFT) {
            throw new BadRequestException("Lỗi: Chỉ có thể chỉnh sửa điều khoản khi hợp đồng đang là Bản Nháp. Hợp đồng đã ký không được phép thay đổi!");
        }

        boolean isDataChanged = false;

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

        if (request.getMembers() != null) {
            String mainTenantPhone = tenant.getPhone();

            contract.getMembers().removeIf(m -> !m.getPhone().equals(mainTenantPhone));

            for (ContractMemberAddRequest memberReq : request.getMembers()) {
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

        if (file != null && !file.isEmpty()) {
            String oldFileUrl = contract.getContractFileUrl();

            if (oldFileUrl != null && !oldFileUrl.trim().isEmpty()) {
                cloudinaryCleanupService.deleteContractFilesAsync(oldFileUrl, null);
            }

            String newFileUrl = cloudinaryService.uploadFile(file, "contract_files");
            contract.setContractFileUrl(newFileUrl);
        }
        Contract updatedContract = contractRepository.save(contract);

        String logDesc = String.format("Cập nhật thông tin bản nháp hợp đồng phòng %s", contract.getRoom().getRoomNumber());
        activityLog.createLog(contract.getRoom().getArea().getLandlord(), "UPDATE_CONTRACT", "contracts", updatedContract.getId(), logDesc);

        return mapToDetailResponse(updatedContract);
    }

    @Transactional
    public void deleteContract(UUID contractId, UUID currentUserId) {

        Contract contract = contractRepository.findById(contractId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy hợp đồng!"));

        if (!contract.getRoom().getArea().getLandlord().getId().equals(currentUserId)) {
            throw new AccessDeniedException("Bạn không có quyền xóa hợp đồng của khu trọ khác!");
        }

        if (contract.getStatus() != ContractStatus.DRAFT && contract.getStatus() != ContractStatus.EXPIRED) {
            throw new BadRequestException("Chỉ được phép xóa hợp đồng Nháp hoặc Hợp đồng đã Quá hạn!");
        }

        UUID tenantId = contract.getTenant().getId();
        Room room = contract.getRoom();

        String fileUrlToDelete = contract.getContractFileUrl();
        String sigUrlToDelete = contract.getTenantSignature();

        cloudinaryCleanupService.deleteContractFilesAsync(fileUrlToDelete, sigUrlToDelete);

        Optional<Deposit> linkedDeposit = depositRepository.findByContractId(contractId);

        if (contract.getStatus() == ContractStatus.DRAFT) {
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

        } else if (contract.getStatus() == ContractStatus.EXPIRED) {
            if (linkedDeposit.isPresent()) {
                depositRepository.delete(linkedDeposit.get());
            }

            List<Invoice> oldInvoices = invoiceRepository.findByContractId(contractId);
            for (Invoice inv : oldInvoices) {
                invoiceDetailRepository.deleteAllByInvoiceId(inv.getId());
                paymentRepository.deleteAllByInvoiceId(inv.getId());
            }
            invoiceRepository.deleteAllByContractId(contractId);
        }

        String logDesc = String.format("Xóa triệt để hợp đồng [%s] của phòng %s.",
                contract.getStatus().name(), room.getRoomNumber());
        activityLog.createLog(contract.getRoom().getArea().getLandlord(), "DELETE_CONTRACT", "contracts", contract.getId(), logDesc);

        contractRepository.delete(contract);

        long remainingContracts = contractRepository.countByTenantId(tenantId);
        if (remainingContracts == 0) {
            System.out.println("Phát hiện tài khoản khách vãng lai không còn hợp đồng nào. Tiến hành dọn dẹp...");
            userService.deleteUser(tenantId);
        }
    }
    @Transactional
    public ContractDetailResponse signContract(UUID contractId, MultipartFile signatureImage, MultipartFile pdfFile, UUID currentUserId) {

        if (signatureImage == null || signatureImage.isEmpty()) {
            throw new BadRequestException("Vui lòng cung cấp hình ảnh chữ ký hợp lệ!");
        }

        Contract contract = contractRepository.findById(contractId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy hợp đồng!"));

        if (!contract.getTenant().getId().equals(currentUserId)) {
            throw new AccessDeniedException("Truy cập bị từ chối! Bạn không phải là người đứng tên trên hợp đồng này.");
        }

        if (contract.getStatus() != ContractStatus.DRAFT) {
            throw new BadRequestException("Hợp đồng này đã được ký hoặc không còn ở trạng thái chờ xác nhận!");
        }

        String signatureUrl = cloudinaryService.uploadFile(signatureImage, "tenant_signatures");

        contract.setTenantSignature(signatureUrl);
        contract.setStatus(ContractStatus.SIGNED);
        String currentTerms = contract.getContractTerms();
        if (currentTerms != null) {
            String signedTerms = currentTerms.replace(
                    "<span style='color:red; font-weight:bold;'>[Chờ khách thuê ký điện tử]</span>",
                    String.format("<img src='%s' width='150'/>", signatureUrl)
            );
            contract.setContractTerms(signedTerms);
        }

        if (pdfFile != null && !pdfFile.isEmpty()) {
            String oldFileUrl = contract.getContractFileUrl();

            if (oldFileUrl != null && !oldFileUrl.trim().isEmpty()) {
                cloudinaryCleanupService.deleteContractFilesAsync(oldFileUrl, null);
            }

            String newFileUrl = cloudinaryService.uploadFile(pdfFile, "contract_files");
            contract.setContractFileUrl(newFileUrl);
        }

        Room room = contract.getRoom();
        room.setStatus(RoomStatus.RENTED);

        contractRepository.save(contract);
        roomRepository.save(room);

        String logDesc = String.format("Khách thuê xác nhận ký hợp đồng điện tử. Phòng %s chính thức chuyển sang trạng thái Đang thuê.",
                room.getRoomNumber());
        activityLog.createLog(contract.getTenant(), "SIGN_CONTRACT", "contracts", contract.getId(), logDesc);

        User landlord = room.getArea().getLandlord();
        String tenantName = contract.getTenant().getFullName();
        String roomNumber = room.getRoomNumber();

        String title = "Hợp đồng đã được ký";
        String content = String.format("Khách thuê %s đã xác nhận chữ ký điện tử cho phòng %s. Hợp đồng đã chính thức có hiệu lực!", tenantName, roomNumber);
        notificationService.createNotification(landlord, title, content, NotificationType.CONTRACT_SIGNED);

        return mapToDetailResponse(contract);
    }

    @Transactional
    public void autoCheckAndExpireContracts() {

        LocalDate today = LocalDate.now();

        List<Contract> expiredContracts = contractRepository.findByStatusAndEndDateBefore(ContractStatus.SIGNED, today);

        if (expiredContracts.isEmpty()) {
            System.out.println("Hôm nay không có hợp đồng nào hết hạn.");
            return;
        }

        System.out.println("Bắt đầu xử lý " + expiredContracts.size() + " hợp đồng hết hạn...");

        for (Contract contract : expiredContracts) {

            contract.setStatus(ContractStatus.EXPIRED);
            contractRepository.save(contract);

            User landlord = contract.getRoom().getArea().getLandlord();
            String roomNum = contract.getRoom().getRoomNumber();

            String title = "Hợp đồng hết hạn";
            String content = String.format("Hợp đồng thuê phòng %s đã chính thức hết hạn vào ngày %s. Vui lòng liên hệ khách thuê để tiến hành Thanh lý hợp đồng hoặc Gia hạn.", roomNum, contract.getEndDate().toString());

            notificationService.createNotification(landlord, title, content, NotificationType.CONTRACT_EXPIRED);

            String logDesc = String.format("Hệ thống tự động khóa hợp đồng phòng %s do quá hạn. Đã gửi thông báo cho chủ trọ.", roomNum);
            activityLog.createLog(landlord, "AUTO_EXPIRE_CONTRACT", "contracts", contract.getId(), logDesc);
        }

        System.out.println("Hoàn tất quét hợp đồng và gửi thông báo!");
    }

    @Transactional
    public ContractDetailResponse extendContract(UUID oldContractId, ContractExtendRequest request, UUID currentUserId) {

        Contract oldContract = contractRepository.findById(oldContractId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy hợp đồng cũ!"));

        if (!oldContract.getRoom().getArea().getLandlord().getId().equals(currentUserId)) {
            throw new AccessDeniedException("Bạn không có quyền gia hạn hợp đồng của khu trọ khác!");
        }

        if (oldContract.getStatus() != ContractStatus.SIGNED && oldContract.getStatus() != ContractStatus.EXPIRED) {
            throw new BadRequestException("Chỉ có thể gia hạn khi hợp đồng cũ đang có hiệu lực (SIGNED) hoặc vừa hết hạn (EXPIRED)!");
        }

        if (request.getNewEndDate() == null || !request.getNewEndDate().isAfter(oldContract.getEndDate())) {
            throw new BadRequestException("Ngày kết thúc mới bắt buộc phải nằm sau ngày kết thúc của hợp đồng cũ!");
        }

        oldContract.setStatus(ContractStatus.EXPIRED);
        contractRepository.save(oldContract);

        LocalDate newStartDate = oldContract.getEndDate();

        Contract newContract = Contract.builder()
                .room(oldContract.getRoom())
                .tenant(oldContract.getTenant())
                .creator(oldContract.getCreator())
                .template(oldContract.getTemplate())

                .startDate(newStartDate)
                .endDate(request.getNewEndDate())

                .depositAmount(oldContract.getDepositAmount())
                .landlordSignature(oldContract.getLandlordSignature())
                .creator(oldContract.getCreator())
                .status(ContractStatus.DRAFT)
                .build();

        List<ContractMember> clonedMembers = oldContract.getMembers().stream().map(oldMember ->
                ContractMember.builder()
                        .contract(newContract)
                        .fullName(oldMember.getFullName())
                        .phone(oldMember.getPhone())
                        .dob(oldMember.getDob())
                        .hometown(oldMember.getHometown())
                        .idCardNumber(oldMember.getIdCardNumber())
                        .joinedAt(oldMember.getJoinedAt())
                        .build()
        ).toList();
        newContract.setMembers(new ArrayList<>(clonedMembers));

        String compiledHtml = contractHtmlCompiler.compileContractTerms(
                newContract.getTemplate(),
                newContract,
                newContract.getCreator(),
                newContract.getTenant(),
                newContract.getRoom()
        );
        newContract.setContractTerms(compiledHtml);

        Contract savedNewContract = contractRepository.save(newContract);

        Optional<Deposit> linkedDeposit = depositRepository.findByContractId(oldContractId);
        if (linkedDeposit.isPresent()) {
            Deposit deposit = linkedDeposit.get();
            deposit.setContract(savedNewContract);
            depositRepository.save(deposit);
        }

        Room room = oldContract.getRoom();
        room.setStatus(RoomStatus.RESERVED);
        roomRepository.save(room);

        String logDesc = String.format("Chủ trọ gia hạn phòng %s (Chờ khách ký).", room.getRoomNumber());
        activityLog.createLog(oldContract.getCreator(), "EXTEND_CONTRACT", "contracts", savedNewContract.getId(), logDesc);

        String title = "Yêu cầu ký Hợp đồng gia hạn";
        String content = String.format("Chủ trọ đã tạo bản Hợp đồng gia hạn mới cho phòng %s (Từ ngày %s đến %s). Vui lòng vào ứng dụng để kiểm tra và xác nhận chữ ký điện tử nhé!",
                room.getRoomNumber(), newStartDate.toString(), request.getNewEndDate().toString());
        notificationService.createNotification(savedNewContract.getTenant(), title, content, NotificationType.CONTRACT_EXTEND);

        return mapToDetailResponse(savedNewContract);
    }

    @Transactional
    public ContractDetailResponse uploadContractFile(UUID contractId, MultipartFile file, UUID currentUserId) {

        if (file == null || file.isEmpty()) {
            throw new BadRequestException("Vui lòng chọn file để tải lên!");
        }

        Contract contract = contractRepository.findById(contractId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy hợp đồng!"));

        if (!contract.getRoom().getArea().getLandlord().getId().equals(currentUserId)) {
            throw new AccessDeniedException("Truy cập bị từ chối! Chỉ chủ trọ của hợp đồng này " +
                    "mới có quyền tải lên file cho hợp đồng này.");
        }

        String oldFileUrl = contract.getContractFileUrl();
        if (oldFileUrl != null && !oldFileUrl.trim().isEmpty()) {
            cloudinaryCleanupService.deleteContractFilesAsync(oldFileUrl, null);
        }

        String uploadedUrl = cloudinaryService.uploadFile(file, "contract_files");

        contract.setContractFileUrl(uploadedUrl);
        contractRepository.save(contract);

        String logDesc = String.format("Cập nhật file đính kèm mới cho hợp đồng phòng %s", contract.getRoom().getRoomNumber());
        activityLog.createLog(contract.getRoom().getArea().getLandlord(), "UPLOAD_CONTRACT_FILE", "contracts", contract.getId(), logDesc);

        return mapToDetailResponse(contract);
    }

    private ContractDetailResponse mapToDetailResponse(Contract contract) {

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

        return ContractDetailResponse.builder()
                .id(contract.getId())
                .startDate(contract.getStartDate())
                .endDate(contract.getEndDate())
                .depositAmount(contract.getDepositAmount())
                .status(contract.getStatus())
                .contractFileUrl(contract.getContractFileUrl())
                .contractTerms(contract.getContractTerms())
                .areaId(contract.getRoom().getArea().getId())
                .areaName(contract.getRoom().getArea().getName())
                .areaAddress(contract.getRoom().getArea().getAddress())

                .templateId(contract.getTemplate() != null ? contract.getTemplate().getId() : null)

                .roomId(contract.getRoom().getId())
                .roomNumber(contract.getRoom().getRoomNumber())
                .rentPrice(contract.getRoom().getRentPrice())

                .landlordName(contract.getCreator().getFullName())
                .landlordIdCardNumber(contract.getCreator().getIdCardNumber())
                .landlordHometown(contract.getCreator().getHometown())
                .landlordSignatureUrl(contract.getLandlordSignature())

                .tenantId(contract.getTenant().getId())
                .tenantName(contract.getTenant().getFullName())
                .tenantPhone(contract.getTenant().getPhone())
                .tenantIdCardNumber(contract.getTenant().getIdCardNumber())
                .tenantHometown(contract.getTenant().getHometown())
                .tenantSignatureUrl(contract.getTenantSignature())

                .members(memberResponses)
                .build();
    }


    private String generateRandomPassword() {
        Random random = new Random();
        return String.valueOf(100000 + random.nextInt(900000));
    }
}