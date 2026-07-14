package ut.edu.be_quanlytro.Controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;
import ut.edu.be_quanlytro.Dto.Request.DepositCreateRequest;
import ut.edu.be_quanlytro.Dto.Request.DepositUpdateRequest;
import ut.edu.be_quanlytro.Dto.Response.DepositResponse;
import ut.edu.be_quanlytro.Entity.Enum.DepositStatus;
import ut.edu.be_quanlytro.Service.DepositService;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/deposits")
@RequiredArgsConstructor
public class DepositController {

    private final DepositService depositService;

    @PostMapping
    @PreAuthorize("hasRole('LANDLORD')")
    public ResponseEntity<DepositResponse> createDeposit(
            @RequestBody DepositCreateRequest request,
            @AuthenticationPrincipal Jwt jwt) {

        UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));
        return ResponseEntity.ok(depositService.createDeposit(request, currentUserId));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('LANDLORD')")
    public ResponseEntity<DepositResponse> updateDeposit(
            @PathVariable UUID id,
            @RequestBody DepositUpdateRequest request,
            @AuthenticationPrincipal Jwt jwt) {

        UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));
        return ResponseEntity.ok(depositService.updateDeposit(id, request, currentUserId));
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasRole('LANDLORD')")
    public ResponseEntity<DepositResponse> getDepositById(
            @PathVariable UUID id,
            @AuthenticationPrincipal Jwt jwt) {

        UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));
        return ResponseEntity.ok(depositService.getDepositById(id, currentUserId));
    }

    @GetMapping("/area/{areaId}")
    @PreAuthorize("hasRole('LANDLORD')")
    public ResponseEntity<List<DepositResponse>> getDepositsByArea(
            @PathVariable UUID areaId,
            @RequestParam(required = false) DepositStatus status,
            @AuthenticationPrincipal Jwt jwt) {

        UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));

        if (status != null) {
            return ResponseEntity.ok(depositService.getDepositsByAreaAndStatus(areaId, status, currentUserId));
        }

        return ResponseEntity.ok(depositService.getDepositsByAreaId(areaId, currentUserId));
    }
}