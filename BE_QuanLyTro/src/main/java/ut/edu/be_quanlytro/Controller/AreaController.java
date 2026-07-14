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
import ut.edu.be_quanlytro.Service.AreaManagementService;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/areas")
@RequiredArgsConstructor
public class AreaController {

    private final AreaManagementService areaManagementService;

    @PostMapping("/onboarding")
    @PreAuthorize("hasRole('LANDLORD')")
    public ResponseEntity<AreaResponse> onboardNewLandlord(
            @RequestBody OnboardingRequest request,
            @AuthenticationPrincipal Jwt jwt) {

        UUID landlordId = UUID.fromString(jwt.getClaimAsString("userId"));

        AreaResponse response = areaManagementService.onboardNewLandlord(request, landlordId);

        return new ResponseEntity<>(response, HttpStatus.CREATED);
    }

    @GetMapping
    @PreAuthorize("hasRole('LANDLORD')")
    public ResponseEntity<List<AreaResponse>> getAreasByLandlord(@AuthenticationPrincipal Jwt jwt) {

        UUID landlordId = UUID.fromString(jwt.getClaimAsString("userId"));
        return ResponseEntity.ok(areaManagementService.getAreasByLandlord(landlordId));
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('LANDLORD','TENANT')")
    public ResponseEntity<AreaResponse> getAreaById(
            @PathVariable UUID id,
            @AuthenticationPrincipal Jwt jwt) {

        UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));

        return ResponseEntity.ok(areaManagementService.getAreaById(id, currentUserId));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('LANDLORD')")
    public ResponseEntity<AreaResponse> updateArea(
            @PathVariable UUID id,
            @RequestBody AreaRequest request,
            @AuthenticationPrincipal Jwt jwt) {

        UUID landlordId = UUID.fromString(jwt.getClaimAsString("userId"));
        return ResponseEntity.ok(areaManagementService.updateArea(id, request, landlordId));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('LANDLORD')")
    public ResponseEntity<String> deleteArea(
            @PathVariable UUID id,
            @AuthenticationPrincipal Jwt jwt) {

        UUID landlordId = UUID.fromString(jwt.getClaimAsString("userId"));
        areaManagementService.deleteArea(id, landlordId);

        return ResponseEntity.ok("Xóa khu trọ thành công");
    }
}