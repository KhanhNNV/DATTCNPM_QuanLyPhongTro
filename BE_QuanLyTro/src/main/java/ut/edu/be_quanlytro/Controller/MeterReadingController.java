package ut.edu.be_quanlytro.Controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;
import ut.edu.be_quanlytro.Dto.Request.MeterReadingBulkUpdateRequest;
import ut.edu.be_quanlytro.Dto.Request.MeterReadingCreateRequest;
import ut.edu.be_quanlytro.Dto.Request.MeterReadingUpdateRequest;
import ut.edu.be_quanlytro.Dto.Response.MeterReadingResponse;
import ut.edu.be_quanlytro.Entity.MeterReading;
import ut.edu.be_quanlytro.Service.MeterReadingService;

import jakarta.validation.Valid;

import java.time.LocalDate;
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
    /**
     * API Sửa chỉ số điện/nước khi nhập sai
     */
    @PutMapping("/{id}")
    @PreAuthorize("hasRole('LANDLORD')")
    public ResponseEntity<?> updateMeterReading(
            @PathVariable UUID id,
            @Valid @RequestBody MeterReadingUpdateRequest request) { // <-- SỬA Ở ĐÂY
        try {
            // Truyền request.getNewIndex() vào Service
            MeterReading updatedReading = meterReadingService.updateMeterReading(id, request.getNewIndex());

            MeterReadingResponse response = MeterReadingResponse.builder()
                    .id(updatedReading.getId())
                    .roomNumber(updatedReading.getRoom().getRoomNumber())
                    .serviceName(updatedReading.getService().getName())
                    .oldIndex(updatedReading.getOldIndex())
                    .newIndex(updatedReading.getNewIndex())
                    .readingDate(updatedReading.getReadingMonth())
                    .isInvoiced(updatedReading.getIsInvoiced())
                    .build();

            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * API Cập nhật ĐỒNG LOẠT nhiều chỉ số (Điện, Nước...)
     */
    @PutMapping("/bulk")
    @PreAuthorize("hasRole('LANDLORD')")
    public ResponseEntity<?> updateBulkMeterReadings(
            @Valid @RequestBody List<MeterReadingBulkUpdateRequest> requests) {
        try {
            List<MeterReading> updatedReadings = meterReadingService.updateBulkMeterReadings(requests);

            List<MeterReadingResponse> responses = updatedReadings.stream().map(reading ->
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

            return ResponseEntity.ok(responses);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    @GetMapping
    @PreAuthorize("hasRole('LANDLORD')")
    public ResponseEntity<?> getMeterReadings(
            @RequestParam UUID roomId,
            @RequestParam LocalDate month) {
        try {
            List<MeterReadingResponse> responses = meterReadingService.getReadingsByRoomAndMonth(roomId, month);
            return ResponseEntity.ok(responses);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

}