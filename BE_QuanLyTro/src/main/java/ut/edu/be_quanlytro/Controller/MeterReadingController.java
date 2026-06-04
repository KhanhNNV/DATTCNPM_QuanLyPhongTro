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

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/meter-readings")
@RequiredArgsConstructor
public class MeterReadingController {

    private final MeterReadingService meterReadingService;
    
    @PostMapping
    @PreAuthorize("hasRole('LANDLORD')")
    public ResponseEntity<?> createMeterReading(
            @Valid @RequestBody MeterReadingCreateRequest request,
            @AuthenticationPrincipal Jwt jwt) {
        try {
            UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));
            MeterReading savedReading = meterReadingService.createMeterReading(request,currentUserId);

            MeterReadingResponse response = MeterReadingResponse.builder()
                    .id(savedReading.getId())
                    .roomNumber(savedReading.getRoom().getRoomNumber())
                    .serviceName(savedReading.getService().getName())
                    .oldIndex(savedReading.getOldIndex())
                    .newIndex(savedReading.getNewIndex())
                    .readingDate(savedReading.getReadingMonth())
                    .isInvoiced(savedReading.getIsInvoiced())
                    .build();
            return new ResponseEntity<>(response, HttpStatus.CREATED);
        }
        catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }



     //API: Chốt số điện/nước ĐỒNG LOẠT (Gộp chung 1 phát)

    @PostMapping("/bulk")
    @PreAuthorize("hasRole('LANDLORD')")
    public ResponseEntity<?> createBulkMeterReadings(
            @Valid @RequestBody List<MeterReadingCreateRequest> requests,
            @AuthenticationPrincipal Jwt jwt) {
        try {
            UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));

            // Gọi Service để xử lý cả 1 mảng dữ liệu (Điện + Nước)
            List<MeterReading> savedReadings = meterReadingService.createBulkMeterReading(requests, currentUserId);

            // Ép toàn bộ Entity trong mảng sang DTO Response để trả về an toàn
            List<MeterReadingResponse> responses = savedReadings.stream().map(reading ->
                    MeterReadingResponse.builder()
                            .id(reading.getId())
                            .roomNumber(reading.getRoom().getRoomNumber())
                            .serviceName(reading.getService().getName())
                            .oldIndex(reading.getOldIndex())
                            .newIndex(reading.getNewIndex())
                            .readingDate(reading.getReadingMonth())
                            .isInvoiced(reading.getIsInvoiced())
                            .build()
            ).toList();

            return new ResponseEntity<>(responses, HttpStatus.CREATED);

        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
}