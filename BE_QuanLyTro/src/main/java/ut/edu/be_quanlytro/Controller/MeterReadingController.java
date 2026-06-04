package ut.edu.be_quanlytro.Controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;
import ut.edu.be_quanlytro.Dto.Request.MeterReadingCreateRequest;
import ut.edu.be_quanlytro.Dto.Response.MeterReadingResponse;
import ut.edu.be_quanlytro.Entity.MeterReading;
import ut.edu.be_quanlytro.Service.MeterReadingService;

import jakarta.validation.Valid;
import java.util.UUID;

@RestController
@RequestMapping("/api/meter-readings")
@RequiredArgsConstructor
public class MeterReadingController {

    private final MeterReadingService meterReadingService;

    /**
     * API Chốt số điện/nước hàng tháng
     * Quyền truy cập: Chỉ dành cho Chủ trọ (LANDLORD)
     */
    @PostMapping
    @PreAuthorize("hasRole('LANDLORD')")
    public ResponseEntity<?> createMeterReading(
            @Valid @RequestBody MeterReadingCreateRequest request,
            @AuthenticationPrincipal Jwt jwt) {
        try {
            UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));

            // 1. Service vẫn trả về Entity
            MeterReading savedReading = meterReadingService.createMeterReading(request, currentUserId);

            // 2. CHẶN ĐỨNG LỖI JACKSON TẠI ĐÂY BẰNG CÁCH GÓI VÀO DTO
            MeterReadingResponse response = MeterReadingResponse.builder()
                    .id(savedReading.getId())
                    .roomNumber(savedReading.getRoom().getRoomNumber()) // Lấy tên phòng
                    .serviceName(savedReading.getService().getName())   // Lấy tên dịch vụ
                    .oldIndex(savedReading.getOldIndex())
                    .newIndex(savedReading.getNewIndex())
                    .readingDate(savedReading.getReadingMonth())
                    .isInvoiced(savedReading.getIsInvoiced())
                    .build();

            // 3. Trả về DTO thay vì Entity
            return new ResponseEntity<>(response, HttpStatus.CREATED);

        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
}