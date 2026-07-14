package ut.edu.be_quanlytro.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
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
import ut.edu.be_quanlytro.Exception.BadRequestException;
import ut.edu.be_quanlytro.Exception.ResourceNotFoundException;
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

    @Transactional
    public DepositResponse createDeposit(DepositCreateRequest request, UUID currentUserId) {

        Room room = roomRepository.findById(request.getRoomId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy phòng"));

        if (!room.getArea().getLandlord().getId().equals(currentUserId)) {
            throw new AccessDeniedException("Bạn không có quyền tạo phiếu đặt cọc cho phòng thuộc khu trọ khác");
        }

        if (room.getStatus() != RoomStatus.AVAILABLE) {
            throw new BadRequestException("Phòng này không trống, không thể nhận cọc!");
        }

        Deposit deposit = Deposit.builder()
                .room(room)
                .phone(request.getPhone())
                .tenantFullName(request.getTenantFullName())
                .depositAmount(request.getDepositAmount())
                .depositDate(LocalDate.now())
                .expectedMoveInDate(request.getExpectedMoveInDate())
                .note(request.getNote())
                .status(DepositStatus.PENDING)
                .build();

        Deposit savedDeposit = depositRepository.save(deposit);

        room.setStatus(RoomStatus.DEPOSITED);
        roomRepository.save(room);

        User userProxy = userRepository.getReferenceById(currentUserId);
        String desc = String.format("Nhận cọc %s VNĐ từ khách %s cho phòng %s",
                savedDeposit.getDepositAmount(), savedDeposit.getTenantFullName(), room.getRoomNumber());
        activityLog.createLog(userProxy, "CREATE_DEPOSIT", "deposits", savedDeposit.getId(), desc);

        return mapToResponse(savedDeposit);
    }

    @Transactional
    public DepositResponse updateDeposit(UUID id, DepositUpdateRequest request, UUID currentUserId) {

        Deposit deposit = depositRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy phiếu đặt cọc"));

        Room room = deposit.getRoom();

        if (!room.getArea().getLandlord().getId().equals(currentUserId)) {
            throw new AccessDeniedException("Bạn không có quyền chỉnh sửa phiếu cọc này");
        }

        if (deposit.getStatus() == DepositStatus.COMPLETED) {
            throw new BadRequestException("Phiếu cọc này đã hoàn tất (đã ký hợp đồng), không thể chỉnh sửa");
        }

        if (request.getPhone() != null) deposit.setPhone(request.getPhone());
        if (request.getTenantFullName() != null) deposit.setTenantFullName(request.getTenantFullName());
        if (request.getDepositAmount() != null) deposit.setDepositAmount(request.getDepositAmount());
        if (request.getExpectedMoveInDate() != null) deposit.setExpectedMoveInDate(request.getExpectedMoveInDate());
        if (request.getNote() != null) deposit.setNote(request.getNote());

        if (request.getStatus() != null && deposit.getStatus() != request.getStatus()) {
            deposit.setStatus(request.getStatus());

            if (request.getStatus() == DepositStatus.CANCELLED) {
                room.setStatus(RoomStatus.AVAILABLE);
                roomRepository.save(room);
            }
            else if (request.getStatus() == DepositStatus.PENDING) {
                if (room.getStatus() != RoomStatus.AVAILABLE) {
                    throw new BadRequestException("Phòng này hiện không trống để có thể khôi phục phiếu cọc");
                }
                room.setStatus(RoomStatus.DEPOSITED);
                roomRepository.save(room);
            }
        }

        Deposit updatedDeposit = depositRepository.save(deposit);

        User userProxy = userRepository.getReferenceById(currentUserId);
        activityLog.createLog(userProxy, "UPDATE_DEPOSIT", "deposits", updatedDeposit.getId(),
                "Cập nhật thông tin phiếu đặt cọc của phòng " + room.getRoomNumber());

        return mapToResponse(updatedDeposit);
    }

    @Transactional(readOnly = true)
    public DepositResponse getDepositById(UUID id, UUID currentUserId) {

        Deposit deposit = depositRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy phiếu đặt cọc"));

        if (!deposit.getRoom().getArea().getLandlord().getId().equals(currentUserId)) {
            throw new AccessDeniedException("Truy cập bị từ chối! Bạn không có quyền xem phiếu cọc của khu trọ khác.");
        }

        return mapToResponse(deposit);
    }

    @Transactional(readOnly = true)
    public List<DepositResponse> getDepositsByAreaId(UUID areaId, UUID currentUserId) {

        Area area = areaRepository.findById(areaId)
                .orElseThrow(() -> new ResourceNotFoundException("Khu trọ không tồn tại"));

        if (!area.getLandlord().getId().equals(currentUserId)) {
            throw new AccessDeniedException("Truy cập bị từ chối! Bạn không có quyền xem danh sách cọc của khu trọ khác.");
        }

        return depositRepository.findByAreaId(areaId)
                .stream()
                .map(this::mapToResponse)
                .toList();
    }

    @Transactional
    public void autoCancelExpiredDeposits() {
        LocalDate today = LocalDate.now();

        List<Deposit> expiredDeposits = depositRepository
                .findAllByStatusAndExpectedMoveInDateBefore(DepositStatus.PENDING, today);

        if (expiredDeposits.isEmpty()) {
            return;
        }

        System.out.println("Phát hiện " + expiredDeposits.size() + " phiếu đặt cọc quá hạn cần hủy");

        for (Deposit deposit : expiredDeposits) {
            deposit.setStatus(DepositStatus.CANCELLED);
            deposit.setNote(deposit.getNote() + " | [Hệ thống tự động hủy do quá hạn ngày hẹn dọn vào].");

            Room room = deposit.getRoom();
            if (room.getStatus() == RoomStatus.DEPOSITED) {
                room.setStatus(RoomStatus.AVAILABLE);
                roomRepository.save(room);
            }

            depositRepository.save(deposit);

            User landlord = room.getArea().getLandlord();
            String roomNum = room.getRoomNumber();
            String tenantName = deposit.getTenantFullName();

            String title = "Hủy phiếu cọc quá hạn";
            String content = String.format("Hệ thống đã tự động hủy phiếu cọc của khách %s tại phòng %s do quá hạn ngày hẹn dọn vào (%s). Căn phòng đã được tự động mở khóa về trạng thái Trống.",
                    tenantName, roomNum, deposit.getExpectedMoveInDate().toString());

            notificationService.createNotification(landlord, title, content, NotificationType.DEPOSIT_CANCELLED);

            activityLog.createLog(landlord, "AUTO_CANCEL_DEPOSIT", "deposits", deposit.getId(), content);

            System.out.println(" Đã hủy phiếu cọc ID: " + deposit.getId() + " của phòng: " + room.getRoomNumber());
        }

        System.out.println("Hoàn tất tiến trình quét dọn phiếu cọc quá hạn");
    }

    @Transactional(readOnly = true)
    public List<DepositResponse> getDepositsByAreaAndStatus(UUID areaId, DepositStatus status, UUID currentUserId) {

        Area area = areaRepository.findById(areaId)
                .orElseThrow(() -> new ResourceNotFoundException("Khu trọ không tồn tại"));

        if (!area.getLandlord().getId().equals(currentUserId)) {
            throw new AccessDeniedException("Truy cập bị từ chối! Bạn không có quyền xem danh sách phiếu cọc của khu trọ khác.");
        }

        return depositRepository.findByAreaIdAndStatus(areaId, status)
                .stream()
                .map(this::mapToResponse)
                .toList();
    }

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