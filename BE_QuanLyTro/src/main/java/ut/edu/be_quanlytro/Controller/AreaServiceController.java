package ut.edu.be_quanlytro.Controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;
import ut.edu.be_quanlytro.Dto.Request.AreaServiceRequest;
import ut.edu.be_quanlytro.Dto.Response.AreaServiceResponse;
import ut.edu.be_quanlytro.Service.AreaServiceManagement;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/area-services")
@RequiredArgsConstructor
public class AreaServiceController {

    private final AreaServiceManagement areaServiceManagement;

    @PostMapping("/area/{areaId}")
    @PreAuthorize("hasAuthority('SCOPE_LANDLORD')") // Chỉ Chủ trọ
    public ResponseEntity<AreaServiceResponse> createService(
            @PathVariable UUID areaId,
            @RequestBody AreaServiceRequest request,
            @AuthenticationPrincipal Jwt jwt) {
        UUID landlordId = UUID.fromString(jwt.getSubject());
        AreaServiceResponse response = areaServiceManagement.createService(areaId, request, landlordId);
        return new ResponseEntity<>(response, HttpStatus.CREATED);
    }

    @GetMapping("/area/{areaId}")
    @PreAuthorize("hasAnyAuthority('SCOPE_LANDLORD', 'SCOPE_TENANT')") // Cả Khách thuê cũng có quyền xem giá dịch vụ
    public ResponseEntity<List<AreaServiceResponse>> getServicesByAreaId(@PathVariable UUID areaId) {
        return ResponseEntity.ok(areaServiceManagement.getServicesByAreaId(areaId));
    }

    @PutMapping("/{serviceId}")
    @PreAuthorize("hasAuthority('SCOPE_LANDLORD')") // Chỉ Chủ trọ
    public ResponseEntity<AreaServiceResponse> updateService(
            @PathVariable UUID serviceId,
            @RequestBody AreaServiceRequest request,
            @AuthenticationPrincipal Jwt jwt) {
        UUID landlordId = UUID.fromString(jwt.getSubject());
        return ResponseEntity.ok(areaServiceManagement.updateService(serviceId, request, landlordId));
    }
}