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
    @PreAuthorize("hasAuthority('SCOPE_LANDLORD')") // Chỉ Chủ trọ
    public ResponseEntity<Room> createRoom(
            @RequestBody RoomRequest request,
            @AuthenticationPrincipal Jwt jwt) {
        UUID currentUserId = UUID.fromString(jwt.getSubject());
        Room createdRoom = roomService.createRoom(request, currentUserId);
        return new ResponseEntity<>(createdRoom, HttpStatus.CREATED);
    }

    // ================= READ =================

    @GetMapping("/{id}")
    @PreAuthorize("hasAuthority('SCOPE_LANDLORD')")
    public ResponseEntity<RoomResponse> getRoomById(@PathVariable UUID id) {
        return ResponseEntity.ok(roomService.getRoomResponseById(id));
    }

    /**
     * Lấy danh sách phòng trong 1 khu trọ (Có hỗ trợ lọc theo trạng thái)
     * - Frontend gọi: GET /api/rooms/area/{areaId}
     * - Hoặc gọi: GET /api/rooms/area/{areaId}?status=AVAILABLE
     */
    @GetMapping("/area/{areaId}")
    @PreAuthorize("hasAnyAuthority('SCOPE_LANDLORD', 'SCOPE_TENANT')")
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
    @PreAuthorize("hasAuthority('SCOPE_LANDLORD')") // Chỉ Chủ trọ
    public ResponseEntity<Room> updateRoom(
            @PathVariable UUID id,
            @RequestBody RoomRequest request,
            @AuthenticationPrincipal Jwt jwt) {
        UUID currentUserId = UUID.fromString(jwt.getSubject());
        return ResponseEntity.ok(roomService.updateRoom(id, request, currentUserId));
    }

    // ================= DELETE =================
    @DeleteMapping("/{id}")
    @PreAuthorize("hasAuthority('SCOPE_LANDLORD')") // Chỉ Chủ trọ
    public ResponseEntity<String> deleteRoom(
            @PathVariable UUID id,
            @AuthenticationPrincipal Jwt jwt) {
        UUID currentUserId = UUID.fromString(jwt.getSubject());
        roomService.deleteRoom(id, currentUserId);
        return ResponseEntity.ok("Xóa phòng thành công");
    }
}