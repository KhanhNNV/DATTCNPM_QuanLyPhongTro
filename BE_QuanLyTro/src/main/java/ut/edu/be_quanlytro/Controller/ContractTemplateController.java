package ut.edu.be_quanlytro.Controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;
import ut.edu.be_quanlytro.Dto.Request.ContractTemplateRequest;
import ut.edu.be_quanlytro.Dto.Response.ContractTemplateResponse;
import ut.edu.be_quanlytro.Service.ContractTemplateService;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/contract/templates")
@RequiredArgsConstructor
public class ContractTemplateController {

    private final ContractTemplateService templateService;

    // Lấy ID người dùng từ Token
    private UUID getCurrentUserId(Jwt jwt) {
        return UUID.fromString(jwt.getClaimAsString("userId"));
    }

    @PostMapping
    @PreAuthorize("hasRole('LANDLORD')")
    public ResponseEntity<ContractTemplateResponse> createTemplate(@RequestBody ContractTemplateRequest request, @AuthenticationPrincipal Jwt jwt) {
        return ResponseEntity.ok(templateService.createTemplate(request, getCurrentUserId(jwt)));
    }

    @GetMapping
    @PreAuthorize("hasRole('LANDLORD')")
    public ResponseEntity<List<ContractTemplateResponse>> getAllTemplates(@AuthenticationPrincipal Jwt jwt) {
        return ResponseEntity.ok(templateService.getAllTemplatesByLandlord(getCurrentUserId(jwt)));
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('LANDLORD','TENANT')")
    public ResponseEntity<ContractTemplateResponse> getTemplateById(@PathVariable UUID id, @AuthenticationPrincipal Jwt jwt) {
        return ResponseEntity.ok(templateService.getTemplateById(id, getCurrentUserId(jwt)));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('LANDLORD')")
    public ResponseEntity<ContractTemplateResponse> updateTemplate(
            @PathVariable UUID id,
            @RequestBody ContractTemplateRequest request,
            @AuthenticationPrincipal Jwt jwt) {
        return ResponseEntity.ok(templateService.updateTemplate(id, request, getCurrentUserId(jwt)));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('LANDLORD')")
    public ResponseEntity<String> deleteTemplate(@PathVariable UUID id, @AuthenticationPrincipal Jwt jwt) {
        templateService.deleteTemplate(id, getCurrentUserId(jwt));
        return ResponseEntity.ok("Xóa mẫu hợp đồng thành công!");
    }
    // ================= CHỌN MẪU MẶC ĐỊNH =================
    @PutMapping("/active/{id}")
    @PreAuthorize("hasRole('LANDLORD')")
    public ResponseEntity<ContractTemplateResponse> setActiveTemplate(
            @PathVariable UUID id,
            @AuthenticationPrincipal Jwt jwt) {

        // 1. Lấy ID của Chủ trọ từ Token
        UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));

        // 2. Gọi xuống Service để xử lý logic bật/tắt
        ContractTemplateResponse response = templateService.setActiveTemplate(id, currentUserId);

        // 3. Trả kết quả về cho Frontend
        return ResponseEntity.ok(response);
    }
}