package ut.edu.be_quanlytro.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ut.edu.be_quanlytro.Dto.Request.AreaRequest;
import ut.edu.be_quanlytro.Dto.Request.OnboardingRequest;
import ut.edu.be_quanlytro.Dto.Response.AreaResponse;
import ut.edu.be_quanlytro.Entity.Area;
import ut.edu.be_quanlytro.Entity.AreaService;
import ut.edu.be_quanlytro.Entity.Enum.RoomStatus;
import ut.edu.be_quanlytro.Entity.Room;
import ut.edu.be_quanlytro.Entity.User;
import ut.edu.be_quanlytro.Repository.AreaRepository;
import ut.edu.be_quanlytro.Repository.AreaServiceRepository;
import ut.edu.be_quanlytro.Repository.RoomRepository;
import ut.edu.be_quanlytro.Repository.UserRepository;
import ut.edu.be_quanlytro.Entity.Enum.RoleType;

import java.text.Normalizer;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.regex.Pattern;

@Service
@RequiredArgsConstructor
public class AreaManagementService {

    private final AreaRepository areaRepository;
    private final UserRepository userRepository;
    private final ActivityLogService activityLog;
    private final AreaServiceRepository areaServiceRepository;
    private final RoomRepository roomRepository;
    /**
     * Hàm hỗ trợ: Biến tên khu trọ thành mã viết tắt.
     * Ví dụ: "Khu trọ Sinh viên IT" -> "KTSVI"
     */
    private String generateAreaCodeFromName(String name) {
        if (name == null || name.trim().isEmpty()) return "ROOM";

        // 1. Loại bỏ dấu tiếng Việt
        String temp = Normalizer.normalize(name, Normalizer.Form.NFD);
        Pattern pattern = Pattern.compile("\\p{InCombiningDiacriticalMarks}+");
        String noAccent = pattern.matcher(temp).replaceAll("")
                .replaceAll("Đ", "D").replaceAll("đ", "d");

        // 2. Tách các từ theo khoảng trắng
        String[] words = noAccent.trim().split("\\s+");
        StringBuilder areaCode = new StringBuilder();

        // 3. Lấy chữ cái đầu tiên của mỗi từ (bỏ qua các ký tự đặc biệt)
        for (String word : words) {
            if (!word.isEmpty() && Character.isLetterOrDigit(word.charAt(0))) {
                areaCode.append(Character.toUpperCase(word.charAt(0)));
            }
        }

        // 4. Giới hạn độ dài mã (Lấy tối đa 4-5 ký tự để mã phòng không bị quá dài)
        String finalCode = areaCode.toString();
        return finalCode.length() > 5 ? finalCode.substring(0, 5) : finalCode;
    }


    //==============TẠO KHU TRỌ, PHÒNG, DỊCH VỤ===========
    @Transactional
    public AreaResponse onboardNewLandlord(OnboardingRequest request, UUID landlordId) {

        // 1. Kiểm tra chủ trọ
        User landlord = userRepository.findById(landlordId)
                .orElseThrow(() -> new RuntimeException("Chủ trọ không tồn tại"));

        if(landlord.getRole() != RoleType.LANDLORD) {
            throw new RuntimeException("Bạn không có quyền thực hiện chức năng này vì không phải là chủ trọ");
        }

        // ==========================================
        // BƯỚC 1: KHỞI TẠO VÀ LƯU KHU TRỌ
        // ==========================================
        Area newArea = Area.builder()
                .landlord(landlord)
                .name(request.getName())
                .address(request.getAddress())
                .invoiceDay(request.getInvoiceDay())
                .dueDate(request.getDueDate())
                .build();
        Area savedArea = areaRepository.save(newArea);

        // ==========================================
        // BƯỚC 2: KHỞI TẠO DỊCH VỤ (AREA SERVICES)
        // ==========================================
        if (request.getServices() != null && !request.getServices().isEmpty()) {
            List<AreaService> areaServices = request.getServices().stream().map(svc ->
                    AreaService.builder()
                            .area(savedArea)
                            .name(svc.getName())
                            .calcType(svc.getCalcType())
                            .price(svc.getPrice())
                            .isActive(true)
                            .build()
            ).toList();

            areaServiceRepository.saveAll(areaServices);
        }

        // ==========================================
        // BƯỚC 3: KHỞI TẠO DANH SÁCH PHÒNG
        // ==========================================
        List<Room> newRooms = new ArrayList<>();
        List<Integer> floors = request.getRoomsPerFloor();

        if (floors != null && !floors.isEmpty()) {
            int globalRoomCounter = 1; // Biến đếm liên tục cho toàn bộ khu

            // Gọi hàm helper để lấy mã viết tắt từ Tên khu trọ
            String shortAreaCode = generateAreaCodeFromName(savedArea.getName());

            for (int i = 0; i < floors.size(); i++) {
                int floorNumber = i + 1;
                int numberOfRooms = floors.get(i);

                for (int j = 1; j <= numberOfRooms; j++) {
                    // 1. Format số thứ tự: 001, 002...
                    String roomSequence = String.format("%03d", globalRoomCounter);

                    // 2. Ghép Mã viết tắt với Số thứ tự. Kết quả: "KTSVI-001"
                    String displayRoomNumber = shortAreaCode + "-" + roomSequence;

                    Room room = Room.builder()
                            .area(savedArea)
                            .floor(floorNumber)
                            .roomNumber(displayRoomNumber) // Lưu chuỗi như KTSVI-001
                            .areaSize(request.getDefaultAreaSize())
                            .rentPrice(request.getDefaultRentPrice())
                            .depositAmount(request.getDefaultDepositAmount())
                            .maxOccupants(request.getDefaultMaxOccupants())
                            .status(RoomStatus.AVAILABLE)
                            .build();

                    newRooms.add(room);
                    globalRoomCounter++;
                }
            }
            roomRepository.saveAll(newRooms);
        }

        // ==========================================
        // BƯỚC 4: GHI LOG HOẠT ĐỘNG
        // ==========================================
        String description = String.format("Hoàn tất thiết lập ban đầu: Tạo khu %s, %d dịch vụ và %d phòng",
                savedArea.getName(),
                request.getServices() != null ? request.getServices().size() : 0,
                newRooms.size());

        activityLog.createLog(landlord, "ONBOARDING_COMPLETED", "areas, rooms, area_services", savedArea.getId(), description);

        // ==========================================
        // BƯỚC 5: MAP ENTITY SANG DTO VÀ TRẢ VỀ
        // ==========================================
        return mapToResponse(savedArea);
    }

    // ================= READ =================
    public List<AreaResponse> getAreasByLandlord(UUID landlordId) {
        return areaRepository.findByLandlordId(landlordId).stream()
                .map(this::mapToResponse)
                .toList();
    }

    public AreaResponse getAreaById(UUID id, UUID currentUserId) {
        // 1. Lấy thông tin Khu trọ từ Database
        Area area = getAreaEntityById(id);

        // 2. Tìm thông tin người dùng đang gọi API
        User currentUser = userRepository.findById(currentUserId)
                .orElseThrow(() -> new RuntimeException("Người dùng không tồn tại trong hệ thống"));

        // 3. KIỂM TRA BẢO MẬT: Nếu là Chủ trọ thì chỉ được xem khu của mình
        if (currentUser.getRole() == RoleType.LANDLORD) {
            // So sánh ID của chủ khu trọ với ID của người đang đăng nhập
            if (!area.getLandlord().getId().equals(currentUserId)) {
                throw new RuntimeException("Truy cập bị từ chối! Bạn không có quyền xem khu trọ của người khác.");
            }
        }

        // (Tùy chọn cho tương lai: Nếu Role là TENANT, bạn cũng có thể thêm logic
        // kiểm tra xem Khách đó có đang thuê phòng thuộc khu này hay không).

        // 4. Nếu qua được vòng kiểm tra, map sang DTO và trả về
        return mapToResponse(area);
    }

    public Area getAreaEntityById(UUID id) {
        return areaRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy khu trọ"));
    }

    // ================= UPDATE =================
    @Transactional
    public AreaResponse updateArea(UUID id, AreaRequest request, UUID landlordId) {
        Area area = getAreaEntityById(id);

        // 🔒 KIỂM TRA BẢO MẬT: Xác nhận quyền sở hữu
        if (!area.getLandlord().getId().equals(landlordId)) {
            throw new RuntimeException("Truy cập bị từ chối! Bạn không có quyền chỉnh sửa khu trọ của người khác.");
        }

        // Cập nhật các trường thông tin nếu có truyền lên
        if (request.getName() != null) area.setName(request.getName());
        if (request.getAddress() != null) area.setAddress(request.getAddress());
        if (request.getInvoiceDay() != null) area.setInvoiceDay(request.getInvoiceDay());
        if (request.getDueDate() != null) area.setDueDate(request.getDueDate());

        Area updatedArea = areaRepository.save(area);

        // Ghi Log hoạt động
        User landlord = userRepository.getReferenceById(landlordId);
        activityLog.createLog(landlord, "UPDATE_AREA", "areas", updatedArea.getId(), "Cập nhật thông tin khu trọ: " + updatedArea.getName());

        return mapToResponse(updatedArea);
    }

    // ================= DELETE =================
    @Transactional
    public void deleteArea(UUID id, UUID landlordId) {
        Area area = getAreaEntityById(id);

        // 🔒 KIỂM TRA BẢO MẬT: Xác nhận quyền sở hữu
        if (!area.getLandlord().getId().equals(landlordId)) {
            throw new RuntimeException("Truy cập bị từ chối! Bạn không có quyền xóa khu trọ của người khác.");
        }

        // ==========================================
        // BƯỚC 1: DỌN DẸP DỮ LIỆU CON TRƯỚC KHI XÓA CHA
        // ==========================================

        // 1.1 Xóa tất cả các Phòng (Rooms) thuộc về Khu trọ này
        List<Room> rooms = roomRepository.findByAreaId(id);
        if (!rooms.isEmpty()) {
            roomRepository.deleteAll(rooms);
        }

        // 1.2 Xóa tất cả các Dịch vụ (AreaServices) thuộc về Khu trọ này
        List<AreaService> services = areaServiceRepository.findByAreaId(id);
        if (!services.isEmpty()) {
            areaServiceRepository.deleteAll(services);
        }

        // ==========================================
        // BƯỚC 2: XÓA DỮ LIỆU CHA (Khu trọ)
        // ==========================================
        areaRepository.delete(area);

        // Ghi Log hoạt động
        User landlord = userRepository.getReferenceById(landlordId);
        activityLog.createLog(landlord, "DELETE_AREA", "areas", id, "Xóa khu trọ: " + area.getName());
    }

    // MAPPER
    private AreaResponse mapToResponse(Area area) {
        return AreaResponse.builder()
                .id(area.getId())
                .name(area.getName())
                .address(area.getAddress())
                .invoiceDay(area.getInvoiceDay())
                .dueDate(area.getDueDate())
                .createdAt(area.getCreatedAt())
                .build();
    }
}