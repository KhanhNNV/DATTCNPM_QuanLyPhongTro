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
    public ResponseEntity<Room> createRoom(
            @RequestBody RoomRequest request,
            @AuthenticationPrincipal Jwt jwt) {

        // Trích xuất ID chuẩn xác từ claim
        UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));
        Room createdRoom = roomService.createRoom(request, currentUserId);

        return new ResponseEntity<>(createdRoom, HttpStatus.CREATED);
    }

    // ================= READ =================

    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('LANDLORD', 'TENANT')") // Khách và Chủ đều có quyền xem thông tin phòng
    public ResponseEntity<RoomResponse> getRoomById(@PathVariable UUID id) {
        return ResponseEntity.ok(roomService.getRoomResponseById(id));
    }

    /**
     * Lấy danh sách phòng trong 1 khu trọ (Có hỗ trợ lọc theo trạng thái)
     * - Frontend gọi: GET /api/rooms/area/{areaId}
     * - Hoặc gọi: GET /api/rooms/area/{areaId}?status=AVAILABLE
     */
    @GetMapping("/area/{areaId}")
    @PreAuthorize("hasAnyRole('LANDLORD', 'TENANT')") // Khách và Chủ đều xem được danh sách
    public ResponseEntity<List<RoomResponse>> getRoomsByArea(
            @PathVariable UUID areaId,
            @RequestParam(required = false) RoomStatus status) {

        // Nếu Frontend truyền status lên, gọi hàm lọc theo khu vực VÀ status
        if (status != null) {
            return ResponseEntity.ok(roomService.getRoomsByAreaAndStatus(areaId, status));
        }
        // Nếu không truyền status, trả về tất cả phòng trong khu đó
        return ResponseEntity.ok(roomService.getRoomsByArea(areaId));
    }

    // ================= UPDATE =================
    @PutMapping("/{id}")
    @PreAuthorize("hasRole('LANDLORD')") // Chỉ Chủ trọ được phép chỉnh sửa phòng
    public ResponseEntity<Room> updateRoom(
            @PathVariable UUID id,
            @RequestBody RoomRequest request,
            @AuthenticationPrincipal Jwt jwt) {

        // Trích xuất ID chuẩn xác từ claim
        UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));

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