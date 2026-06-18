package ut.edu.be_quanlytro.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ut.edu.be_quanlytro.Dto.Request.DepositCreateRequest;
import ut.edu.be_quanlytro.Dto.Request.DepositUpdateRequest;
import ut.edu.be_quanlytro.Dto.Response.DepositResponse;
import ut.edu.be_quanlytro.Entity.Area;
import ut.edu.be_quanlytro.Entity.Deposit;
import ut.edu.be_quanlytro.Entity.Enum.DepositStatus;
import ut.edu.be_quanlytro.Entity.Enum.NotificationType;
import ut.edu.be_quanlytro.Entity.Enum.RoomStatus;
import ut.edu.be_quanlytro.Entity.Room;
import ut.edu.be_quanlytro.Entity.User;
import ut.edu.be_quanlytro.Repository.AreaRepository;
import ut.edu.be_quanlytro.Repository.DepositRepository;
import ut.edu.be_quanlytro.Repository.RoomRepository;
import ut.edu.be_quanlytro.Repository.UserRepository;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class DepositService {

    private final DepositRepository depositRepository;
    private final RoomRepository roomRepository;
    private final UserRepository userRepository;
    private final ActivityLogService activityLog;
    private final AreaRepository areaRepository;
    private final NotificationService notificationService;

    // ================= CREATE =================
    @Transactional
    public DepositResponse createDeposit(DepositCreateRequest request, UUID currentUserId) {

        // 1. Kiểm tra phòng
        Room room = roomRepository.findById(request.getRoomId())
                .orElseThrow(() -> new RuntimeException("Không tìm thấy phòng"));

        // 2. 🔒 KIỂM TRA BẢO MẬT: Chỉ Chủ trọ của phòng này mới được tạo phiếu cọc
        if (!room.getArea().getLandlord().getId().equals(currentUserId)) {
            throw new RuntimeException("Bạn không có quyền tạo phiếu đặt cọc cho phòng thuộc khu trọ khác");
        }

        // 3. KIỂM TRA TRẠNG THÁI: Chỉ phòng trống mới được cọc
        if (room.getStatus() != RoomStatus.AVAILABLE) {
            throw new RuntimeException("Phòng này không trống, không thể nhận cọc!");
        }

        // 4. Tạo phiếu cọc
        Deposit deposit = Deposit.builder()
                .room(room)
                .phone(request.getPhone())
                .tenantFullName(request.getTenantFullName())
                .depositAmount(request.getDepositAmount())
                .depositDate(LocalDate.now()) // Tự động lấy ngày hiện tại làm ngày cọc
                .expectedMoveInDate(request.getExpectedMoveInDate())
                .note(request.getNote())
                .status(DepositStatus.PENDING) // Mặc định là đang chờ
                .build();

        Deposit savedDeposit = depositRepository.save(deposit);

        // 5. TỰ ĐỘNG KHÓA PHÒNG: Chuyển trạng thái phòng sang DEPOSITED
        room.setStatus(RoomStatus.DEPOSITED);
        roomRepository.save(room);

        // 6. GHI LOG
        User userProxy = userRepository.getReferenceById(currentUserId);
        String desc = String.format("Nhận cọc %s VNĐ từ khách %s cho phòng %s",
                savedDeposit.getDepositAmount(), savedDeposit.getTenantFullName(), room.getRoomNumber());
        activityLog.createLog(userProxy, "CREATE_DEPOSIT", "deposits", savedDeposit.getId(), desc);

        return mapToResponse(savedDeposit);
    }

    // ================= UPDATE =================
    @Transactional
    public DepositResponse updateDeposit(UUID id, DepositUpdateRequest request, UUID currentUserId) {

        Deposit deposit = depositRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy phiếu đặt cọc"));

        Room room = deposit.getRoom();

        // 1. 🔒 KIỂM TRA BẢO MẬT
        if (!room.getArea().getLandlord().getId().equals(currentUserId)) {
            throw new RuntimeException("Bạn không có quyền chỉnh sửa phiếu cọc này");
        }

        // Không cho phép sửa phiếu cọc khi đã chuyển thành hợp đồng
        if (deposit.getStatus() == DepositStatus.COMPLETED) {
            throw new RuntimeException("Phiếu cọc này đã hoàn tất (đã ký hợp đồng), không thể chỉnh sửa");
        }

        // 2. Cập nhật thông tin
        if (request.getPhone() != null) deposit.setPhone(request.getPhone());
        if (request.getTenantFullName() != null) deposit.setTenantFullName(request.getTenantFullName());
        if (request.getDepositAmount() != null) deposit.setDepositAmount(request.getDepositAmount());
        if (request.getExpectedMoveInDate() != null) deposit.setExpectedMoveInDate(request.getExpectedMoveInDate());
        if (request.getNote() != null) deposit.setNote(request.getNote());

        // 3. XỬ LÝ ĐỔI TRẠNG THÁI (Rất quan trọng)
        if (request.getStatus() != null && deposit.getStatus() != request.getStatus()) {
            deposit.setStatus(request.getStatus());

            // Nếu Chủ trọ hủy cọc (CANCELLED), phải tự động trả phòng về lại AVAILABLE
            if (request.getStatus() == DepositStatus.CANCELLED) {
                room.setStatus(RoomStatus.AVAILABLE);
                roomRepository.save(room);
            }
            // Nếu đổi ngược lại từ Hủy -> Đang chờ
            else if (request.getStatus() == DepositStatus.PENDING) {
                if (room.getStatus() != RoomStatus.AVAILABLE) {
                    throw new RuntimeException("Phòng này hiện không trống để có thể khôi phục phiếu cọc");
                }
                room.setStatus(RoomStatus.DEPOSITED);
                roomRepository.save(room);
            }
        }

        Deposit updatedDeposit = depositRepository.save(deposit);

        // 4. GHI LOG
        User userProxy = userRepository.getReferenceById(currentUserId);
        activityLog.createLog(userProxy, "UPDATE_DEPOSIT", "deposits", updatedDeposit.getId(),
                "Cập nhật thông tin phiếu đặt cọc của phòng " + room.getRoomNumber());

        return mapToResponse(updatedDeposit);
    }
    // ================= READ (XEM CHI TIẾT 1 PHIẾU CỌC) =================
    @Transactional(readOnly = true)
    public DepositResponse getDepositById(UUID id, UUID currentUserId) {

        Deposit deposit = depositRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy phiếu đặt cọc"));

        // 🔒 KIỂM TRA BẢO MẬT: Chỉ Chủ trọ của khu trọ đó mới được xem
        if (!deposit.getRoom().getArea().getLandlord().getId().equals(currentUserId)) {
            throw new RuntimeException("Truy cập bị từ chối! Bạn không có quyền xem phiếu cọc của khu trọ khác.");
        }

        return mapToResponse(deposit);
    }

    // ================= READ (LẤY DANH SÁCH THEO KHU TRỌ) =================
    @Transactional(readOnly = true)
    public List<DepositResponse> getDepositsByAreaId(UUID areaId, UUID currentUserId) {

        // 1. Lấy thông tin Khu trọ để kiểm tra quyền sở hữu
        Area area = areaRepository.findById(areaId)
                .orElseThrow(() -> new RuntimeException("Khu trọ không tồn tại"));

        // 2. 🔒 KIỂM TRA BẢO MẬT: Chặn hành vi truyền ID khu trọ của người khác
        if (!area.getLandlord().getId().equals(currentUserId)) {
            throw new RuntimeException("Truy cập bị từ chối! Bạn không có quyền xem danh sách cọc của khu trọ khác.");
        }

        // 3. Lấy dữ liệu thông qua Custom Query đã viết trong DepositRepository và map sang DTO
        return depositRepository.findByAreaId(areaId)
                .stream()
                .map(this::mapToResponse)
                .toList();
    }

    // ================= AUTOMATION (TỰ ĐỘNG HỦY CỌC QUÁ HẠN) =================
    @Transactional
    public void autoCancelExpiredDeposits() {
        LocalDate today = LocalDate.now();

        // 1. Tìm các phiếu cọc PENDING đã quá ngày hẹn dọn vào
        List<Deposit> expiredDeposits = depositRepository
                .findAllByStatusAndExpectedMoveInDateBefore(DepositStatus.PENDING, today);

        if (expiredDeposits.isEmpty()) {
            return;
        }

        System.out.println("Phát hiện " + expiredDeposits.size() + " phiếu đặt cọc quá hạn cần hủy");

        for (Deposit deposit : expiredDeposits) {
            // 2. Chuyển trạng thái phiếu cọc sang CANCELLED
            deposit.setStatus(DepositStatus.CANCELLED);
            deposit.setNote(deposit.getNote() + " | [Hệ thống tự động hủy do quá hạn ngày hẹn dọn vào].");

            // 3. Giải phóng phòng: Chuyển trạng thái phòng về lại AVAILABLE nếu phòng đang bị khóa cọc
            Room room = deposit.getRoom();
            if (room.getStatus() == RoomStatus.DEPOSITED) {
                room.setStatus(RoomStatus.AVAILABLE);
                roomRepository.save(room);
            }

            depositRepository.save(deposit);

            // 4. BẮN THÔNG BÁO CHO CHỦ TRỌ
            User landlord = room.getArea().getLandlord();
            String roomNum = room.getRoomNumber();
            String tenantName = deposit.getTenantFullName();

            String title = "Hủy phiếu cọc quá hạn";
            String content = String.format("Hệ thống đã tự động hủy phiếu cọc của khách %s tại phòng %s do quá hạn ngày hẹn dọn vào (%s). Căn phòng đã được tự động mở khóa về trạng thái Trống.",
                    tenantName, roomNum, deposit.getExpectedMoveInDate().toString());

            notificationService.createNotification(landlord, title, content, NotificationType.DEPOSIT_CANCELLED);

            // Đồng thời ghi Log hệ thống để lưu vết
            activityLog.createLog(landlord, "AUTO_CANCEL_DEPOSIT", "deposits", deposit.getId(), content);
            // =========================================================================

            System.out.println(" Đã hủy phiếu cọc ID: " + deposit.getId() + " của phòng: " + room.getRoomNumber());
        }

        System.out.println("Hoàn tất tiến trình quét dọn phiếu cọc quá hạn");
    }
    // ================= MAPPER =================
    private DepositResponse mapToResponse(Deposit deposit) {
        return DepositResponse.builder()
                .id(deposit.getId())
                .roomId(deposit.getRoom().getId())
                .roomNumber(deposit.getRoom().getRoomNumber())
                .phone(deposit.getPhone())
                .tenantFullName(deposit.getTenantFullName())
                .depositAmount(deposit.getDepositAmount())
                .depositDate(deposit.getDepositDate())
                .expectedMoveInDate(deposit.getExpectedMoveInDate())
                .note(deposit.getNote())
                .status(deposit.getStatus())
                .build();
    }
}