package ut.edu.be_quanlytro.Service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.JsonNode;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.multipart.MultipartFile;
import ut.edu.be_quanlytro.Dto.Response.OcrCccdResponse;
import ut.edu.be_quanlytro.Exception.BadRequestException;

@Service
@RequiredArgsConstructor
public class OcrService {

    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Value("${fpt.ai.vision.api-key}")
    private String FPT_API_KEY;

    private final String FPT_OCR_URL = "https://api.fpt.ai/vision/idr/vnm";

    public OcrCccdResponse extractCccdData(MultipartFile frontImage, MultipartFile backImage) {

        if (frontImage == null || frontImage.isEmpty()) {
            throw new BadRequestException("Vui lòng cung cấp ảnh mặt trước CCCD!");
        }

        String idNumber = "";
        String fullName = "";
        String dob = "";
        String hometown = "";

        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.MULTIPART_FORM_DATA);
            headers.set("api-key", FPT_API_KEY);

            MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
            ByteArrayResource contentsAsResource = new ByteArrayResource(frontImage.getBytes()) {
                @Override
                public String getFilename() {
                    return frontImage.getOriginalFilename() != null ? frontImage.getOriginalFilename() : "front.jpg";
                }
            };
            body.add("image", contentsAsResource);

            HttpEntity<MultiValueMap<String, Object>> requestEntity = new HttpEntity<>(body, headers);

            System.out.println("Đang gửi ảnh lên FPT AI để nhận diện...");
            ResponseEntity<String> response = restTemplate.exchange(FPT_OCR_URL, HttpMethod.POST, requestEntity, String.class);

            JsonNode root = objectMapper.readTree(response.getBody());

            if (root.path("errorCode").asInt() != 0) {
                throw new BadRequestException("Lỗi từ FPT AI: " + root.path("errorMessage").asText());
            }

            JsonNode dataNode = root.path("data").get(0);
            if (dataNode == null || dataNode.isEmpty()) {
                throw new BadRequestException("FPT AI không tìm thấy thông tin CCCD trong ảnh này!");
            }

            idNumber = dataNode.path("id").asText();
            fullName = dataNode.path("name").asText();
            dob = dataNode.path("dob").asText();
            hometown = dataNode.path("home").asText();

            System.out.println("Nhận diện thành công khách hàng: " + fullName);

        } catch (BadRequestException e) {
            throw e;
        } catch (Exception e) {
            throw new BadRequestException("Lỗi trong quá trình quét CCCD: " + e.getMessage());
        }

        return OcrCccdResponse.builder()
                .idNumber(idNumber)
                .fullName(fullName)
                .dob(dob)
                .hometown(hometown)
                .build();
    }
}