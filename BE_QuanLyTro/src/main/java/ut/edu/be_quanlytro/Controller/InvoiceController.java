package ut.edu.be_quanlytro.Controller;

import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
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
import ut.edu.be_quanlytro.Dto.Response.PageResponse;
import ut.edu.be_quanlytro.Dto.Response.PaymentQrResponse;
import ut.edu.be_quanlytro.Entity.Enum.InvoiceStatus;
import ut.edu.be_quanlytro.Service.InvoiceService;
import ut.edu.be_quanlytro.Exception.BadRequestException;

import jakarta.validation.Valid;

import java.util.List;
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
            UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));
            InvoiceResponse response = invoiceService.createInvoice(request, currentUserId);
            return new ResponseEntity<>(response, HttpStatus.CREATED);
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('LANDLORD', 'TENANT')")
    public ResponseEntity<InvoiceDetailResponse> getInvoiceDetail(
            @PathVariable UUID id,
            @AuthenticationPrincipal Jwt jwt) {

        UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));
        InvoiceDetailResponse response = invoiceService.getInvoiceDetail(id, currentUserId);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{id}/qr-code")
    @PreAuthorize("hasAnyRole('LANDLORD', 'TENANT')")
    public ResponseEntity<PaymentQrResponse> getPaymentQrCode(
            @PathVariable UUID id,
            @AuthenticationPrincipal Jwt jwt) {

        UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));
        PaymentQrResponse response = invoiceService.generateVietQR(id, currentUserId);
        return ResponseEntity.ok(response);
    }
    @PutMapping("/{id}/confirm-payment")
    @PreAuthorize("hasRole('LANDLORD')")
    public ResponseEntity<InvoiceResponse> confirmPayment(
            @PathVariable UUID id,
            @AuthenticationPrincipal Jwt jwt) {

        UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));
        InvoiceResponse response = invoiceService.confirmPayment(id, currentUserId);
        return ResponseEntity.ok(response);
    }
    @PostMapping(value = "/{id}/upload-proof", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("hasRole('TENANT')")
    public ResponseEntity<?> uploadPaymentProof(
            @PathVariable UUID id,
            @RequestParam("file") MultipartFile file) {

        if (file.isEmpty()) {
            throw new BadRequestException("File ảnh không được để trống!");
        }

        invoiceService.uploadPaymentProof(id, file);
        return ResponseEntity.ok(Map.of("message", "Gửi minh chứng lên Cloud thành công! Đang chờ chủ trọ phê duyệt."));
    }

      //API Chủ trọ từ chối minh chứng thanh toán

    @PutMapping("/{id}/reject-payment")
    @PreAuthorize("hasRole('LANDLORD')")
    public ResponseEntity<InvoiceResponse> rejectPaymentProof(
            @PathVariable UUID id,
            @RequestParam("reason") String reason,
            @AuthenticationPrincipal Jwt jwt) {

        UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));

        if (reason == null || reason.trim().isEmpty()) {
            throw new BadRequestException("Lý do từ chối không được để trống!");
        }

        InvoiceResponse response = invoiceService.rejectPaymentProof(id, reason, currentUserId);
        return ResponseEntity.ok(response);
    }
    //API: Lấy danh sách toàn bộ hóa đơn của Chủ Trọ
    @GetMapping("/landlord")
    @PreAuthorize("hasRole('LANDLORD')")
    public ResponseEntity<PageResponse<InvoiceResponse>> getAllInvoicesForLandlord(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) InvoiceStatus status,
            @RequestParam(required = false) UUID areaId,
            @AuthenticationPrincipal Jwt jwt) {

        UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));

        PageResponse<InvoiceResponse> responses = invoiceService.getAllInvoicesForLandlord(currentUserId, areaId, status, page, size);
        return ResponseEntity.ok(responses);
    }

     // API: Lấy danh sách hóa đơn cho Khách Thuê (Có phân trang & lọc)


    @GetMapping("/tenant")
    @PreAuthorize("hasRole('TENANT')")
    public ResponseEntity<PageResponse<InvoiceResponse>> getMyInvoices(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) InvoiceStatus status,
            @AuthenticationPrincipal Jwt jwt) {

        UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));

        PageResponse<InvoiceResponse> responses = invoiceService.getMyInvoices(currentUserId, status, page, size);
        return ResponseEntity.ok(responses);
    }

}