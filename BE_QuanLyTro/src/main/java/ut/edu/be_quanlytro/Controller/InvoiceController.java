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
import ut.edu.be_quanlytro.Dto.Request.InvoiceCreateRequest;
import ut.edu.be_quanlytro.Dto.Response.InvoiceDetailResponse;
import ut.edu.be_quanlytro.Dto.Response.InvoiceResponse;
import ut.edu.be_quanlytro.Dto.Response.PaymentQrResponse;
import ut.edu.be_quanlytro.Service.InvoiceService;

import jakarta.validation.Valid;

import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/invoices")
@RequiredArgsConstructor
public class InvoiceController {

    private final InvoiceService invoiceService;

    @PostMapping
    @PreAuthorize("hasRole('LANDLORD')")
    public ResponseEntity<?> createInvoice(
            @Valid @RequestBody InvoiceCreateRequest request,
            @AuthenticationPrincipal Jwt jwt) {
        try {
            UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));
            // Truyền currentUserId xuống tầng Service
            InvoiceResponse response = invoiceService.createInvoice(request, currentUserId);
            return new ResponseEntity<>(response, HttpStatus.CREATED);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('LANDLORD', 'TENANT')")
    public ResponseEntity<?> getInvoiceDetail(
            @PathVariable UUID id,
            @AuthenticationPrincipal Jwt jwt) {
        try {
            UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));
            InvoiceDetailResponse response = invoiceService.getInvoiceDetail(id, currentUserId);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @GetMapping("/{id}/qr-code")
    @PreAuthorize("hasAnyRole('LANDLORD', 'TENANT')")
    public ResponseEntity<?> getPaymentQrCode(
            @PathVariable UUID id,
            @AuthenticationPrincipal Jwt jwt) {
        try {
            UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));
            // Truyền currentUserId xuống tầng Service
            PaymentQrResponse response = invoiceService.generateVietQR(id, currentUserId);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    @PutMapping("/{id}/confirm-payment")
    @PreAuthorize("hasRole('LANDLORD')")
    public ResponseEntity<?> confirmPayment(
            @PathVariable UUID id,
            @AuthenticationPrincipal Jwt jwt) {
        try {
            UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));
            InvoiceResponse response = invoiceService.confirmPayment(id, currentUserId);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    @PostMapping(value = "/{id}/upload-proof", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<?> uploadPaymentProof(
            @PathVariable UUID id,
            @RequestParam("file") MultipartFile file) {
        try {
            if (file.isEmpty()) {
                return ResponseEntity.badRequest().body(Map.of("message", "File ảnh không được để trống!"));
            }

            // Gọi service xử lý (Hàm này bên trong đã đổi sang gọi CloudinaryService rồi)
            invoiceService.uploadPaymentProof(id, file);

            return ResponseEntity.ok(Map.of("message", "Gửi minh chứng lên Cloud thành công! Đang chờ chủ trọ phê duyệt."));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("message", "Lỗi khi upload: " + e.getMessage()));
        }
    }
}