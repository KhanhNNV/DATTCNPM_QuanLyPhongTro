package ut.edu.be_quanlytro.Controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import ut.edu.be_quanlytro.Dto.Response.IssueResponse;
import ut.edu.be_quanlytro.Dto.Response.PageResponse;
import ut.edu.be_quanlytro.Entity.Enum.IssueStatus;
import ut.edu.be_quanlytro.Service.IssueService;

import java.util.UUID;

@RestController
@RequestMapping("/api/issues")
@RequiredArgsConstructor
public class IssueController {

    private final IssueService issueService;

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("hasRole('TENANT')") // Bắt buộc chỉ Khách thuê mới được báo cáo
    public ResponseEntity<IssueResponse> reportIssue(
            @RequestParam("roomId") UUID roomId,
            @RequestParam("description") String description,
            @RequestParam(value = "image", required = false) MultipartFile image, // Ảnh không bắt buộc (khách lười chụp vẫn gửi được)
            @AuthenticationPrincipal Jwt jwt) {

        UUID tenantId = UUID.fromString(jwt.getClaimAsString("userId"));
        IssueResponse response = issueService.reportIssue(roomId, description, image, tenantId);

        return new ResponseEntity<>(response, HttpStatus.CREATED);
    }

    @PutMapping("/{id}/status")
    @PreAuthorize("hasRole('LANDLORD')") // Bắt buộc là Chủ trọ mới được sửa
    public ResponseEntity<IssueResponse> updateIssueStatus(
            @PathVariable UUID id,
            @RequestParam("status") IssueStatus status,
            @RequestParam(value = "solutionNote", required = false) String solutionNote,
            @AuthenticationPrincipal Jwt jwt) {

        UUID landlordId = UUID.fromString(jwt.getClaimAsString("userId"));
        IssueResponse response = issueService.updateIssueStatus(id, status, solutionNote, landlordId);

        return ResponseEntity.ok(response);
    }

    @GetMapping("/tenant")
    @PreAuthorize("hasRole('TENANT')")
    public ResponseEntity<PageResponse<IssueResponse>> getMyIssues(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) IssueStatus status,
            @AuthenticationPrincipal Jwt jwt) {

        UUID tenantId = UUID.fromString(jwt.getClaimAsString("userId"));
        PageResponse<IssueResponse> response = issueService.getMyIssues(tenantId, status, page, size);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/landlord")
    @PreAuthorize("hasRole('LANDLORD')")
    public ResponseEntity<PageResponse<IssueResponse>> getIssuesForLandlord(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) IssueStatus status,
            @RequestParam(required = false) UUID roomId,
            @RequestParam(required = false) UUID areaId,
            @AuthenticationPrincipal Jwt jwt) {

        UUID landlordId = UUID.fromString(jwt.getClaimAsString("userId"));

        PageResponse<IssueResponse> response = issueService.getIssuesForLandlord(landlordId, areaId, roomId, status, page, size);

        return ResponseEntity.ok(response);
    }
    @PutMapping(value = "/tenant/{id}", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("hasRole('TENANT')")
    public ResponseEntity<IssueResponse> updateMyIssue(
            @PathVariable UUID id,
            @RequestParam(value = "description", required = false) String description,
            @RequestParam(value = "image", required = false) MultipartFile image,
            @AuthenticationPrincipal Jwt jwt) {

        UUID tenantId = UUID.fromString(jwt.getClaimAsString("userId"));
        IssueResponse response = issueService.updateMyIssue(id, description, image, tenantId);

        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/tenant/{id}")
    @PreAuthorize("hasRole('TENANT')")
    public ResponseEntity<String> deleteMyIssue(
            @PathVariable UUID id,
            @AuthenticationPrincipal Jwt jwt) {

        UUID tenantId = UUID.fromString(jwt.getClaimAsString("userId"));
        issueService.deleteMyIssue(id, tenantId);

        return ResponseEntity.ok("Đã thu hồi báo cáo sự cố thành công!");
    }
}