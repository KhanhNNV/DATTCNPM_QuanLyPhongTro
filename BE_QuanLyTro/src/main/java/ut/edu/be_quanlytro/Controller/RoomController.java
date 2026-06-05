package ut.edu.be_quanlytro.Controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;
import ut.edu.be_quanlytro.Dto.Request.RoomRequest;
import ut.edu.be_quanlytro.Dto.Response.RoomResponse;
import ut.edu.be_quanlytro.Entity.Enum.RoomStatus;
import ut.edu.be_quanlytro.Entity.Room;
import ut.edu.be_quanlytro.Service.RoomService;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/rooms")
@RequiredArgsConstructor
public class RoomController {

    private final RoomService roomService;

    // ================= CREATE =================
    @PostMapping
    @PreAuthorize("hasRole('LANDLORD')") // Chỉ Chủ trọ được tạo phòng
    public ResponseEntity<RoomResponse> createRoom(
            @RequestBody RoomRequest request,
            @AuthenticationPrincipal Jwt jwt) {

        // Trích xuất ID chuẩn xác từ claim
        UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));

        // SỬA Ở ĐÂY: Đổi kiểu dữ liệu hứng từ Room sang RoomResponse
        RoomResponse response = roomService.createRoom(request, currentUserId);

        return new ResponseEntity<>(response, HttpStatus.CREATED);
    }

    // ================= READ =================

    @GetMapping("/{id}")
    @PreAuthorize("hasRole('LANDLORD')") // Khách và Chủ đều có quyền xem thông tin phòng
    public ResponseEntity<RoomResponse> getRoomById(
            @PathVariable UUID id,
            @AuthenticationPrincipal Jwt jwt) { // Bổ sung tham số đọc Token

        // Trích xuất ID chuẩn xác từ claim
        UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));

        // Truyền cả id phòng và id người dùng xuống Service
        return ResponseEntity.ok(roomService.getRoomResponseById(id, currentUserId));
    }

    /**
     * Lấy danh sách phòng trong 1 khu trọ (Có hỗ trợ lọc theo trạng thái)
     */
    @GetMapping("/area/{areaId}")
    @PreAuthorize("hasRole('LANDLORD')")
    public ResponseEntity<List<RoomResponse>> getRoomsByArea(
            @PathVariable UUID areaId,
            @RequestParam(required = false) RoomStatus status,
            @AuthenticationPrincipal Jwt jwt) {

        // 1. Trích xuất ID của người dùng đang gọi API từ Token
        UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));

        // 2. Nếu Frontend có truyền trạng thái (status), gọi hàm lọc và truyền đủ 3 tham số
        if (status != null) {
            return ResponseEntity.ok(roomService.getRoomsByAreaAndStatus(areaId, status, currentUserId));
        }

        // 3. Nếu không truyền trạng thái, lấy tất cả phòng và truyền đủ 2 tham số
        return ResponseEntity.ok(roomService.getRoomsByArea(areaId, currentUserId));
    }

    // ================= UPDATE =================
    @PutMapping("/{id}")
    @PreAuthorize("hasRole('LANDLORD')") // Chỉ Chủ trọ được phép chỉnh sửa phòng
    public ResponseEntity<RoomResponse> updateRoom( // <--- Đã sửa từ Room thành RoomResponse
                                                    @PathVariable UUID id,
                                                    @RequestBody RoomRequest request,
                                                    @AuthenticationPrincipal Jwt jwt) {

        // Trích xuất ID chuẩn xác từ claim
        UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));

        // Gọi xuống Service (lúc này Service đã trả về RoomResponse) và bọc vào ResponseEntity.ok
        return ResponseEntity.ok(roomService.updateRoom(id, request, currentUserId));
    }

    // ================= DELETE =================
    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('LANDLORD')") // Chỉ Chủ trọ được phép xóa phòng
    public ResponseEntity<String> deleteRoom(
            @PathVariable UUID id,
            @AuthenticationPrincipal Jwt jwt) {

        // Trích xuất ID chuẩn xác từ claim
        UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));
        roomService.deleteRoom(id, currentUserId);

        return ResponseEntity.ok("Xóa phòng thành công");
    }
}