package ut.edu.be_quanlytro.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ut.edu.be_quanlytro.Dto.Request.MeterReadingBulkUpdateRequest;
import ut.edu.be_quanlytro.Dto.Request.MeterReadingCreateRequest;
import ut.edu.be_quanlytro.Dto.Response.MeterReadingResponse;
import ut.edu.be_quanlytro.Entity.AreaService;
import ut.edu.be_quanlytro.Entity.Enum.ServiceCalculationType;
import ut.edu.be_quanlytro.Entity.MeterReading;
import ut.edu.be_quanlytro.Entity.Room;
import ut.edu.be_quanlytro.Entity.User;
import ut.edu.be_quanlytro.Repository.AreaServiceRepository;
import ut.edu.be_quanlytro.Repository.MeterReadingRepository;
import ut.edu.be_quanlytro.Repository.RoomRepository;
import ut.edu.be_quanlytro.Repository.UserRepository;
import org.springframework.security.access.AccessDeniedException;
import ut.edu.be_quanlytro.Exception.BadRequestException;
import ut.edu.be_quanlytro.Exception.ResourceNotFoundException;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class MeterReadingService {

    private final MeterReadingRepository meterReadingRepository;
    private final RoomRepository roomRepository;
    private final AreaServiceRepository areaServiceRepository;
    private final UserRepository userRepository;
    @Transactional
    public MeterReading createMeterReading(MeterReadingCreateRequest request, UUID currentUserId){
        Room room = roomRepository.findById(request.getRoomId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy phòng!"));

        //  Kiểm tra xem phòng này có thuộc quyền sở hữu của Chủ trọ đang gọi API không
        if (!room.getArea().getLandlord().getId().equals(currentUserId)) {
            throw new AccessDeniedException("Bạn không có quyền chốt số cho phòng của khu trọ khác!");
        }

        AreaService service = areaServiceRepository.findById(request.getServiceId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy dịch vụ!"));

        LocalDate exactReadingDate = request.getReadingDate().withDayOfMonth(1);
        Integer oldIndex = 0;
        Optional<MeterReading> lastReading = meterReadingRepository.
                findTopByRoomIdAndServiceIdAndReadingMonthBeforeOrderByReadingMonthDesc
                        (room.getId(),service.getId(),exactReadingDate);
        if(lastReading.isPresent()){
            oldIndex = lastReading.get().getNewIndex();
        }
        if (request.getNewIndex()<oldIndex){
            throw new BadRequestException(String.format("Lỗi: Chỉ số mới (%d) không được nhỏ hơn chỉ số cũ (%d)!", request.getNewIndex(), oldIndex));
        }
        if(meterReadingRepository.existsByRoomIdAndServiceIdAndReadingMonth(room.getId(),service.getId(),exactReadingDate)){
            throw new BadRequestException("Phòng này đã được chốt số trong ngày hôm nay rồi!");
        }
        User landlord = userRepository.getReferenceById(currentUserId);
        MeterReading newReading = MeterReading.builder()
                .room(room)
                .service(service)
                .oldIndex(oldIndex)
                .newIndex(request.getNewIndex())
                .readingMonth(exactReadingDate)
                .createdBy(landlord)
                .isInvoiced(false)
                .build();
        return meterReadingRepository.save(newReading);
    }

    // gop tinh dien nuoc....
    @Transactional
    public List<MeterReading> createBulkMeterReading(List<MeterReadingCreateRequest> requests, UUID currentUserId) {
        List<MeterReading> savedReadings = new ArrayList<>();
       for (MeterReadingCreateRequest request : requests) {
           MeterReading saved = this.createMeterReading(request, currentUserId);
           savedReadings.add(saved);
       }
       return savedReadings;
    }

    @Transactional
    public MeterReading updateMeterReading(UUID readingId, Integer newIndex, UUID currentUserId) {
        MeterReading existingReading = meterReadingRepository.findById(readingId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy phiếu chốt số!"));

        if (!existingReading.getRoom().getArea().getLandlord().getId().equals(currentUserId)) {
            throw new AccessDeniedException("Bạn không có quyền sửa chốt số của khu trọ khác!");
        }

        if (existingReading.getIsInvoiced()) {
            throw new BadRequestException("Phiếu này đã được lập hóa đơn, không thể sửa!");
        }

        if (newIndex < existingReading.getOldIndex()) {
            throw new BadRequestException(String.format("Lỗi: Số mới (%d) không được nhỏ hơn số cũ (%d)!", newIndex, existingReading.getOldIndex()));
        }

        existingReading.setNewIndex(newIndex);
        MeterReading savedReading = meterReadingRepository.save(existingReading);

        savedReading.getRoom().getRoomNumber();
        savedReading.getService().getName();

        return savedReading;
    }
    @Transactional
    public List<MeterReading> updateBulkMeterReadings(List<MeterReadingBulkUpdateRequest> requests, UUID currentUserId) { // THÊM THAM SỐ ID
        List<MeterReading> updatedReadings = new ArrayList<>();

        for (MeterReadingBulkUpdateRequest request : requests) {
            MeterReading updated = this.updateMeterReading(request.getId(), request.getNewIndex(), currentUserId); // Truyền ID vào
            updatedReadings.add(updated);
        }

        return updatedReadings;
    }

    @Transactional(readOnly = true)
    public List<MeterReadingResponse> getReadingsByRoomAndMonth(UUID roomId, LocalDate month, UUID currentUserId) { // THÊM THAM SỐ ID
        Room room = roomRepository.findById(roomId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy phòng!"));


        if (!room.getArea().getLandlord().getId().equals(currentUserId)) {
            throw new AccessDeniedException("Bạn không có quyền xem dữ liệu của khu trọ khác!");
        }

        LocalDate normalizedMonth = month.withDayOfMonth(1);
        List<MeterReading> readings = meterReadingRepository.findByRoomIdAndReadingMonth(roomId, month);

        if (!readings.isEmpty()) {
            return readings.stream().map(r -> MeterReadingResponse.builder()
                    .id(r.getId())
                    .serviceId(r.getService().getId())
                    .roomNumber(r.getRoom().getRoomNumber())
                    .serviceName(r.getService().getName())
                    .oldIndex(r.getOldIndex())
                    .newIndex(r.getNewIndex())
                    .readingDate(r.getReadingMonth())
                    .isInvoiced(r.getIsInvoiced())
                    .build()
            ).toList();
        }

        List<AreaService> indexServices = areaServiceRepository.findByAreaIdAndIsActiveTrue(room.getArea().getId())
                .stream()
                .filter(s -> s.getCalcType() == ServiceCalculationType.BY_INDEX)
                .toList();

        return indexServices.stream().map(service -> {
            Integer lastMonthNewIndex = meterReadingRepository
                    .findTopByRoomIdAndServiceIdAndReadingMonthBeforeOrderByReadingMonthDesc(roomId, service.getId(), month)
                    .map(MeterReading::getNewIndex)
                    .orElse(0);

            return MeterReadingResponse.builder()
                    .id(null)
                    .serviceId(service.getId())
                    .roomNumber(room.getRoomNumber())
                    .serviceName(service.getName())
                    .oldIndex(lastMonthNewIndex)
                    .newIndex(0)
                    .readingDate(normalizedMonth)
                    .isInvoiced(false)
                    .build();
        }).toList();
    }
}
