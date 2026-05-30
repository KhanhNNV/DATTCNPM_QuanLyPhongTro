package ut.edu.be_quanlytro.Controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;
import ut.edu.be_quanlytro.Dto.Request.AreaRequest;
import ut.edu.be_quanlytro.Dto.Request.OnboardingRequest;
import ut.edu.be_quanlytro.Dto.Response.AreaResponse;
import ut.edu.be_quanlytro.Entity.Area;
import ut.edu.be_quanlytro.Service.AreaManagementService;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/areas")
@RequiredArgsConstructor
public class AreaController {

    private final AreaManagementService areaManagementService;

    // ================= ONBOARDING =================
    @PostMapping("/onboarding")
    @PreAuthorize("hasAuthority('SCOPE_LANDLORD')") // Chỉ Chủ trọ
    public ResponseEntity<Area> onboardNewLandlord(
            @RequestBody OnboardingRequest request,
            @AuthenticationPrincipal Jwt jwt) {
        UUID landlordId = UUID.fromString(jwt.getSubject());
        Area createdArea = areaManagementService.onboardNewLandlord(request, landlordId);
        return new ResponseEntity<>(createdArea, HttpStatus.CREATED);
    }

    // ================= CRUD =================
    @GetMapping
    @PreAuthorize("hasAuthority('SCOPE_LANDLORD')") // Chỉ chủ trọ mới xem danh sách khu trọ của chính họ
    public ResponseEntity<List<AreaResponse>> getAreasByLandlord(@AuthenticationPrincipal Jwt jwt) {
        UUID landlordId = UUID.fromString(jwt.getSubject());
        return ResponseEntity.ok(areaManagementService.getAreasByLandlord(landlordId));
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAnyAuthority('SCOPE_LANDLORD', 'SCOPE_TENANT')") // Khách xem chi tiết khu trọ
    public ResponseEntity<AreaResponse> getAreaById(@PathVariable UUID id) {
        return ResponseEntity.ok(areaManagementService.getAreaById(id));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAuthority('SCOPE_LANDLORD')") // Chỉ Chủ trọ
    public ResponseEntity<AreaResponse> updateArea(
            @PathVariable UUID id,
            @RequestBody AreaRequest request,
            @AuthenticationPrincipal Jwt jwt) {
        UUID landlordId = UUID.fromString(jwt.getSubject());
        return ResponseEntity.ok(areaManagementService.updateArea(id, request, landlordId));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAuthority('SCOPE_LANDLORD')") // Chỉ Chủ trọ
    public ResponseEntity<String> deleteArea(
            @PathVariable UUID id,
            @AuthenticationPrincipal Jwt jwt) {
        UUID landlordId = UUID.fromString(jwt.getSubject());
        areaManagementService.deleteArea(id, landlordId);
        return ResponseEntity.ok("Xóa khu trọ thành công");
    }
}