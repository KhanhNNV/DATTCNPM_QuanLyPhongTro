package ut.edu.be_quanlytro.Controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import ut.edu.be_quanlytro.Dto.Request.*;
import ut.edu.be_quanlytro.Dto.Response.ContractCreateResponse;
import ut.edu.be_quanlytro.Dto.Response.ContractDetailResponse;
import ut.edu.be_quanlytro.Dto.Response.ContractTerminationResponse;
import ut.edu.be_quanlytro.Service.ContractService;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/contracts")
@RequiredArgsConstructor
public class ContractController {

    private final ContractService contractService;
    private final ObjectMapper objectMapper = new ObjectMapper()
            .registerModule(new com.fasterxml.jackson.datatype.jsr310.JavaTimeModule());

    @PostMapping(value = "/create", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("hasRole('LANDLORD')")
    public ResponseEntity<ContractCreateResponse> createContract(
            @RequestParam("data") String dataJson,
            @RequestParam("frontImage") MultipartFile frontImage,
            @RequestParam("backImage") MultipartFile backImage,
            @AuthenticationPrincipal Jwt jwt) {

        try {
            ContractCreateRequest request = objectMapper.readValue(dataJson, ContractCreateRequest.class);

            UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));

            ContractCreateResponse response = contractService.createContract(request, frontImage, backImage, currentUserId);

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            throw new RuntimeException("Quá trình lập hợp đồng thất bại: " + e.getMessage());
        }
    }

    @PostMapping("/create/manual")
    @PreAuthorize("hasRole('LANDLORD')")
    public ResponseEntity<ContractCreateResponse> createContractManual(
            @RequestBody ContractCreateManualRequest request,
            @AuthenticationPrincipal Jwt jwt) {

        UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));
        ContractCreateResponse response = contractService.createContractManual(request, currentUserId);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{contractId}")
    @PreAuthorize("hasRole('LANDLORD')")
    public ResponseEntity<ContractDetailResponse> getContractDetail(
            @PathVariable UUID contractId,
            @AuthenticationPrincipal Jwt jwt) {

        UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));
        ContractDetailResponse response = contractService.getContractByIdForLandlord(contractId, currentUserId);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/current")
    @PreAuthorize("hasRole('TENANT')")
    public ResponseEntity<ContractDetailResponse> getMyCurrentContract(
            @AuthenticationPrincipal Jwt jwt) {

        UUID tenantId = UUID.fromString(jwt.getClaimAsString("userId"));
        ContractDetailResponse response = contractService.getMyCurrentContract(tenantId);
        return ResponseEntity.ok(response);
    }

    @GetMapping
    @PreAuthorize("hasRole('LANDLORD')")
    public ResponseEntity<List<ContractDetailResponse>> getMyContracts(
            @RequestParam UUID areaId,
            @AuthenticationPrincipal Jwt jwt) {

        UUID landlordId = UUID.fromString(jwt.getClaimAsString("userId"));

        List<ContractDetailResponse> responses = contractService.getContractsByArea(areaId, landlordId);

        return ResponseEntity.ok(responses);
    }

    @PostMapping("/add/member")
    @PreAuthorize("hasRole('LANDLORD')")
    public ResponseEntity<ContractDetailResponse> addContractMember(
            @RequestBody ContractMemberAddRequest request,
            @AuthenticationPrincipal Jwt jwt) {

        UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));
        ContractDetailResponse response = contractService.addContractMember(request, currentUserId);

        return ResponseEntity.ok(response);
    }

    @PutMapping("/terminate/{contractId}")
    @PreAuthorize("hasRole('LANDLORD')")
    public ResponseEntity<ContractTerminationResponse> terminateContract(
            @PathVariable("contractId") UUID contractId,
            @RequestBody ContractTerminationRequest request,
            @AuthenticationPrincipal Jwt jwt) {

        UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));

        ContractTerminationResponse response = contractService.terminateContract(request, currentUserId, contractId);

        return ResponseEntity.ok(response);
    }

    @PutMapping(value = "/update/{contractId}", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("hasRole('LANDLORD')")
    public ResponseEntity<ContractDetailResponse> updateContract(
            @PathVariable UUID contractId,
            @RequestParam(value = "data", required = false) String dataJson,
            @RequestParam(value = "file", required = false) MultipartFile file,
            @AuthenticationPrincipal Jwt jwt) {

        try {
            UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));

            ContractUpdateRequest request = new ContractUpdateRequest();
            if (dataJson != null && !dataJson.trim().isEmpty()) {
                request = objectMapper.readValue(dataJson, ContractUpdateRequest.class);
            }

            ContractDetailResponse response = contractService.updateContract(contractId, request, file, currentUserId);
            return ResponseEntity.ok(response);

        } catch (Exception e) {
            throw new RuntimeException("Lỗi xử lý dữ liệu cập nhật: " + e.getMessage());
        }
    }

    @DeleteMapping("/{contractId}")
    @PreAuthorize("hasRole('LANDLORD')")
    public ResponseEntity<String> deleteContract(
            @PathVariable UUID contractId,
            @AuthenticationPrincipal Jwt jwt) {

        UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));

        contractService.deleteContract(contractId, currentUserId);

        return ResponseEntity.ok("Xóa hợp đồng thành công! Căn phòng đã được giải phóng và dữ liệu đã được dọn dẹp.");
    }

    @PutMapping(value = "/sign/{contractId}", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("hasRole('TENANT')")
    public ResponseEntity<ContractDetailResponse> signContract(
            @PathVariable UUID contractId,
            @RequestParam("signature") MultipartFile signatureImage,
            @RequestParam(value = "file", required = false) MultipartFile pdfFile,
            @AuthenticationPrincipal Jwt jwt) {

        UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));

        ContractDetailResponse response = contractService.signContract(contractId, signatureImage, pdfFile, currentUserId);

        return ResponseEntity.ok(response);
    }

    @PutMapping("/extend/{contractId}")
    @PreAuthorize("hasRole('LANDLORD')")
    public ResponseEntity<ContractDetailResponse> extendContract(
            @PathVariable UUID contractId,
            @RequestBody ContractExtendRequest request,
            @AuthenticationPrincipal Jwt jwt) {

        UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));
        ContractDetailResponse response = contractService.extendContract(contractId, request, currentUserId);

        return ResponseEntity.ok(response);
    }

    @PostMapping(value = "/upload/file/{id}", consumes = "multipart/form-data")
    @PreAuthorize("hasAnyRole('LANDLORD','TENANT')")
    public ResponseEntity<ContractDetailResponse> uploadContractFile(
            @PathVariable UUID id,
            @RequestParam("file") MultipartFile file,
            @AuthenticationPrincipal Jwt jwt) {

        UUID currentUserId = UUID.fromString(jwt.getClaimAsString("userId"));

        return ResponseEntity.ok(contractService.uploadContractFile(id, file, currentUserId));
    }
}