package ut.edu.be_quanlytro.Controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import ut.edu.be_quanlytro.Dto.Response.OcrCccdResponse;
import ut.edu.be_quanlytro.Service.OcrService;

@RestController
@RequestMapping("/api/ocr")
@RequiredArgsConstructor
public class OcrController {

    private final OcrService ocrService;

    @PostMapping(value = "/cccd", consumes = {"multipart/form-data"})
    @PreAuthorize("hasRole('LANDLORD')")
    public ResponseEntity<OcrCccdResponse> uploadAndScanCccd(
            @RequestPart("frontImage") MultipartFile frontImage,
            @RequestPart("backImage") MultipartFile backImage) {

        OcrCccdResponse result = ocrService.extractCccdData(frontImage, backImage);
        return ResponseEntity.ok(result);
    }
}