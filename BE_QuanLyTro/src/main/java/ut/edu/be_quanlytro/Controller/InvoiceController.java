package ut.edu.be_quanlytro.Controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;
import ut.edu.be_quanlytro.Dto.Request.InvoiceCreateRequest;
import ut.edu.be_quanlytro.Dto.Response.InvoiceDetailResponse;
import ut.edu.be_quanlytro.Dto.Response.InvoiceResponse;
import ut.edu.be_quanlytro.Dto.Response.PaymentQrResponse;
import ut.edu.be_quanlytro.Service.InvoiceService;

import jakarta.validation.Valid;

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
            @AuthenticationPrincipal Jwt jwt) { // ĐÃ VÁ JWT
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
            @AuthenticationPrincipal Jwt jwt) { // ĐÃ VÁ JWT
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
}