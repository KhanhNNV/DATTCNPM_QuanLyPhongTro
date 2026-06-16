package ut.edu.be_quanlytro.Controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
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
    public ResponseEntity<?> createInvoice(@Valid @RequestBody InvoiceCreateRequest request) {
        try {
            InvoiceResponse response = invoiceService.createInvoice(request);
            return new ResponseEntity<>(response, HttpStatus.CREATED); // Trả về mã 201 Created
        } catch (RuntimeException e) {
            // Bắt mọi lỗi từ Service (như: chưa chốt điện, phòng chưa có hợp đồng...) và ném ra mã 400
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('LANDLORD', 'TENANT')")
    public ResponseEntity<?> getInvoiceDetail(@PathVariable UUID id) {
        try {
            InvoiceDetailResponse response = invoiceService.getInvoiceDetail(id);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * API Tạo mã VietQR để thanh toán hóa đơn
     * Chỉ KHÁCH THUÊ (TENANT) hoặc CHỦ TRỌ (LANDLORD) mới được xem
     */
    @GetMapping("/{id}/qr-code")
    @PreAuthorize("hasAnyRole('LANDLORD', 'TENANT')")
    public ResponseEntity<?> getPaymentQrCode(@PathVariable UUID id) {
        try {
            PaymentQrResponse response = invoiceService.generateVietQR(id);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
}