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

    @Transactional
    public MeterReading updateMeterReading(UUID readingId, Integer newIndex) {
        MeterReading existingReading = meterReadingRepository.findById(readingId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy phiếu chốt số!"));

        // 1. Chặn nếu đã lên hóa đơn
        if (existingReading.getIsInvoiced()) {
            throw new RuntimeException("Phiếu này đã được lập hóa đơn, không thể sửa!");
        }

        // 2. Chặn nếu số mới sửa lại nhỏ hơn số cũ
        if (newIndex < existingReading.getOldIndex()) {
            throw new RuntimeException(String.format("Lỗi: Số mới (%d) không được nhỏ hơn số cũ (%d)!", newIndex, existingReading.getOldIndex()));
        }

        // 3. Cập nhật số mới và lưu lại
        existingReading.setNewIndex(newIndex);
        MeterReading savedReading = meterReadingRepository.save(existingReading);

        savedReading.getRoom().getRoomNumber();
        savedReading.getService().getName();

        return savedReading;
    }
    @Transactional
    public List<MeterReading> updateBulkMeterReadings(List<MeterReadingBulkUpdateRequest> requests) {
        List<MeterReading> updatedReadings = new ArrayList<>();

        for (MeterReadingBulkUpdateRequest request : requests) {
            // Tái sử dụng lại hàm update lẻ để nó tự check logic (isInvoiced, lớn hơn số cũ...)
            MeterReading updated = this.updateMeterReading(request.getId(), request.getNewIndex());
            updatedReadings.add(updated);
        }

        return updatedReadings;
    }
    // NHỚ THÊM DÒNG IMPORT NÀY LÊN ĐẦU FILE NHÉ:
// import ut.edu.be_quanlytro.Entity.Enum.ServiceCalculationType;

    @Transactional(readOnly = true)
    public List<MeterReadingResponse> getReadingsByRoomAndMonth(UUID roomId, LocalDate month) {
        // 1. Kiểm tra xem tháng này đã có dữ liệu chưa
        List<MeterReading> readings = meterReadingRepository.findByRoomIdAndReadingMonth(roomId, month);

        //  Đã có dữ liệu (Tháng cũ đã chốt số xong) -> Trả về bình thường
        if (!readings.isEmpty()) {
            return readings.stream().map(r -> MeterReadingResponse.builder()
                    .id(r.getId())
                    .roomNumber(r.getRoom().getRoomNumber())
                    .serviceName(r.getService().getName())
                    .oldIndex(r.getOldIndex())
                    .newIndex(r.getNewIndex())
                    .readingDate(r.getReadingMonth())
                    .isInvoiced(r.getIsInvoiced())
                    .build()
            ).toList();
        }

        //  Chưa có dữ liệu (Tháng mới) -> Dựng Form Ảo
        Room room = roomRepository.findById(roomId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy phòng!"));


        List<AreaService> indexServices = areaServiceRepository.findByAreaIdAndIsActiveTrue(room.getArea().getId())
                .stream()
                .filter(s -> s.getCalcType() == ServiceCalculationType.BY_INDEX)
                .toList();

        // Map danh sách dịch vụ này thành các Form Ảo để gửi về FE
        return indexServices.stream().map(service -> {
            // Tận dụng luôn hàm tìm chốt số gần nhất mà team ông đã viết
            Integer lastMonthNewIndex = meterReadingRepository
                    .findTopByRoomIdAndServiceIdAndReadingMonthBeforeOrderByReadingMonthDesc(roomId, service.getId(), month)
                    .map(MeterReading::getNewIndex)
                    .orElse(0); // Nếu trọ mới tinh chưa từng chốt, mặc định lấy số 0

            return MeterReadingResponse.builder()
                    .id(null) // BÁO HIỆU CHO FE BIẾT ĐÂY LÀ FORM ẢO (CẦN GỌI HÀM POST)
                    .serviceId(service.getId())
                    .roomNumber(room.getRoomNumber())
                    .serviceName(service.getName())
                    .oldIndex(lastMonthNewIndex) // Biến số MỚI của tháng trước thành số CŨ của tháng này
                    .newIndex(0) // Để sẵn số 0 cho chủ trọ nhập
                    .readingDate(month)
                    .isInvoiced(false)
                    .build();
        }).toList();
    }
}
