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
}