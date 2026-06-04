package ut.edu.be_quanlytro.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ut.edu.be_quanlytro.Dto.Request.MeterReadingCreateRequest;
import ut.edu.be_quanlytro.Entity.AreaService;
import ut.edu.be_quanlytro.Entity.MeterReading;
import ut.edu.be_quanlytro.Entity.Room;
import ut.edu.be_quanlytro.Entity.User;
import ut.edu.be_quanlytro.Repository.AreaServiceRepository;
import ut.edu.be_quanlytro.Repository.MeterReadingRepository;
import ut.edu.be_quanlytro.Repository.RoomRepository;
import ut.edu.be_quanlytro.Repository.UserRepository;

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
                .orElseThrow(() -> new RuntimeException("Không tìm thấy phòng!"));
        AreaService service = areaServiceRepository.findById(request.getServiceId())
                .orElseThrow(() -> new RuntimeException("Không tìm thấy dịch vụ!"));
        LocalDate exactReadingDate = request.getReadingDate();
        Integer oldIndex = 0;
        Optional<MeterReading> lastReading = meterReadingRepository.
                findTopByRoomIdAndServiceIdAndReadingMonthBeforeOrderByReadingMonthDesc
                        (room.getId(),service.getId(),exactReadingDate);
        if(lastReading.isPresent()){
            oldIndex = lastReading.get().getNewIndex();
        }
        if (request.getNewIndex()<oldIndex){
            throw new RuntimeException(String.format("Lỗi: Chỉ số mới (%d) không được nhỏ hơn chỉ số cũ (%d)!", request.getNewIndex(), oldIndex));
        }
        if(meterReadingRepository.existsByRoomIdAndServiceIdAndReadingMonth(room.getId(),service.getId(),exactReadingDate)){
            throw new RuntimeException("Phòng này đã được chốt số trong ngày hôm nay rồi!");
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
}
