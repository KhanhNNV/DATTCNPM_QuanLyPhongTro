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
import ut.edu.be_quanlytro.Service.RoomService;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/rooms")
@RequiredArgsConstructor
public class RoomController {

    private final RoomService roomService;

    @PostMapping
    @PreAuthorize("hasRole('LANDLORD')")
    public ResponseEntity<RoomResponse> createRoom(
            @RequestBody RoomRequest request,
            @AuthenticationPrincipal Jwt jwt) {

        UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));

        RoomResponse response = roomService.createRoom(request, currentUserId);

        return new ResponseEntity<>(response, HttpStatus.CREATED);
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasRole('LANDLORD')")
    public ResponseEntity<RoomResponse> getRoomById(
            @PathVariable UUID id,
            @AuthenticationPrincipal Jwt jwt) {

        UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));

        return ResponseEntity.ok(roomService.getRoomResponseById(id, currentUserId));
    }

    @GetMapping("/area/{areaId}")
    @PreAuthorize("hasRole('LANDLORD')")
    public ResponseEntity<List<RoomResponse>> getRoomsByArea(
            @PathVariable UUID areaId,
            @RequestParam(required = false) RoomStatus status,
            @AuthenticationPrincipal Jwt jwt) {

        UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));

        if (status != null) {
            return ResponseEntity.ok(roomService.getRoomsByAreaAndStatus(areaId, status, currentUserId));
        }

        return ResponseEntity.ok(roomService.getRoomsByArea(areaId, currentUserId));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('LANDLORD')")
    public ResponseEntity<RoomResponse> updateRoom(
            @PathVariable UUID id,
            @RequestBody RoomRequest request,
            @AuthenticationPrincipal Jwt jwt) {

        UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));

        return ResponseEntity.ok(roomService.updateRoom(id, request, currentUserId));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('LANDLORD')")
    public ResponseEntity<String> deleteRoom(
            @PathVariable UUID id,
            @AuthenticationPrincipal Jwt jwt) {

        UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));
        roomService.deleteRoom(id, currentUserId);

        return ResponseEntity.ok("Xóa phòng thành công");
    }
}