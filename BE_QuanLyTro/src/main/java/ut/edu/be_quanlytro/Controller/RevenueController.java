package ut.edu.be_quanlytro.Controller;

import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;
import ut.edu.be_quanlytro.Dto.Response.RevenueReportResponse;
import ut.edu.be_quanlytro.Service.RevenueService;

import java.time.LocalDate;
import java.util.UUID;

@RestController
@RequestMapping("/api/revenue")
@RequiredArgsConstructor
public class RevenueController {

    private final RevenueService revenueService;

    @GetMapping("/report")
    @PreAuthorize("hasRole('LANDLORD')") // Chỉ chủ trọ mới được xem tiền nong doanh thu
    public ResponseEntity<RevenueReportResponse> getRevenueReport(
            @RequestParam("month") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate month,
            @RequestParam(value = "areaId", required = false) UUID areaId, // Không bắt buộc, truyền lên thì lọc theo Khu
            @AuthenticationPrincipal Jwt jwt) {

        UUID landlordId = UUID.fromString(jwt.getClaimAsString("userId"));
        RevenueReportResponse response = revenueService.getMonthlyRevenueReport(month, areaId, landlordId);

        return ResponseEntity.ok(response);
    }
}