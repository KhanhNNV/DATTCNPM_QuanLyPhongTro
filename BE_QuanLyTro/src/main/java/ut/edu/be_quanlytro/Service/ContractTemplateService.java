package ut.edu.be_quanlytro.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ut.edu.be_quanlytro.Dto.Request.ContractTemplateRequest;
import ut.edu.be_quanlytro.Dto.Response.ContractTemplateResponse;
import ut.edu.be_quanlytro.Entity.ContractTemplate;
import ut.edu.be_quanlytro.Entity.User;
import ut.edu.be_quanlytro.Exception.BadRequestException;
import ut.edu.be_quanlytro.Exception.ResourceNotFoundException;
import ut.edu.be_quanlytro.Repository.ContractRepository;
import ut.edu.be_quanlytro.Repository.ContractTemplateRepository;
import ut.edu.be_quanlytro.Repository.UserRepository;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class ContractTemplateService {

    private final ContractTemplateRepository templateRepository;
    private final UserRepository userRepository;
    private final ActivityLogService activityLog;
    private final ContractRepository contractRepository;

    @Transactional
    public ContractTemplateResponse createTemplate(ContractTemplateRequest request, UUID landlordId) {
        User landlord = userRepository.findById(landlordId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy thông tin Chủ trọ"));

        boolean isFirstTemplate = templateRepository.findByLandlordIdOrderByCreatedAtDesc(landlordId).isEmpty();

        ContractTemplate template = ContractTemplate.builder()
                .landlord(landlord)
                .name(request.getName())
                .rentalContent(request.getRentalContent())
                .landlordDuty(request.getLandlordDuty())
                .tenantDuty(request.getTenantDuty())
                .executionTerms(request.getExecutionTerms())
                .isActive(isFirstTemplate)
                .build();

        ContractTemplate savedTemplate = templateRepository.save(template);
        activityLog.createLog(landlord, "CREATE_TEMPLATE", "contract_templates", savedTemplate.getId(), "Tạo mẫu hợp đồng: " + savedTemplate.getName());

        return mapToResponse(savedTemplate);
    }

    @Transactional(readOnly = true)
    public List<ContractTemplateResponse> getAllTemplatesByLandlord(UUID landlordId) {
        return templateRepository.findByLandlordIdOrderByCreatedAtDesc(landlordId)
                .stream()
                .map(this::mapToResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public ContractTemplateResponse getTemplateById(UUID id, UUID landlordId) {
        ContractTemplate template = templateRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy mẫu hợp đồng "));

        return mapToResponse(template);
    }

    @Transactional
    public ContractTemplateResponse updateTemplate(UUID id, ContractTemplateRequest request, UUID landlordId) {
        ContractTemplate template = templateRepository.findByIdAndLandlordId(id, landlordId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy mẫu hợp đồng!"));

        if (request.getName() != null) template.setName(request.getName());
        if (request.getRentalContent() != null) template.setRentalContent(request.getRentalContent());
        if (request.getLandlordDuty() != null) template.setLandlordDuty(request.getLandlordDuty());
        if (request.getTenantDuty() != null) template.setTenantDuty(request.getTenantDuty());
        if (request.getExecutionTerms() != null) template.setExecutionTerms(request.getExecutionTerms());

        ContractTemplate updatedTemplate = templateRepository.save(template);
        return mapToResponse(updatedTemplate);
    }

    @Transactional
    public ContractTemplateResponse setActiveTemplate(UUID id, UUID landlordId) {
        List<ContractTemplate> allTemplates = templateRepository.findByLandlordIdOrderByCreatedAtDesc(landlordId);
        ContractTemplate selectedTemplate = null;

        for (ContractTemplate t : allTemplates) {
            if (t.getId().equals(id)) {
                t.setIsActive(true);
                selectedTemplate = t;
            } else {
                t.setIsActive(false);
            }
        }

        if (selectedTemplate == null) {
            throw new ResourceNotFoundException("Không tìm thấy mẫu hợp đồng!");
        }

        templateRepository.saveAll(allTemplates);
        return mapToResponse(selectedTemplate);
    }

    @Transactional
    public void deleteTemplate(UUID id, UUID landlordId) {
        ContractTemplate template = templateRepository.findByIdAndLandlordId(id, landlordId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy mẫu hợp đồng!"));

        if (template.getIsActive()) {
            throw new BadRequestException("Không thể xóa mẫu đang được thiết lập làm mặc định. Vui lòng chọn mẫu khác làm mặc định trước khi xóa!");
        }

        boolean isUsedInContracts = contractRepository.existsByTemplateId(id);
        if (isUsedInContracts) {
            throw new BadRequestException("Không thể xóa mẫu này vì đã có hợp đồng thực tế đang sử dụng. Bạn chỉ có thể ngừng sử dụng nó bằng cách chọn mẫu khác làm mặc định!");
        }

        templateRepository.delete(template);
        activityLog.createLog(template.getLandlord(), "DELETE_TEMPLATE", "contract_templates", template.getId(), "Xóa mẫu hợp đồng: " + template.getName());
    }

    private ContractTemplateResponse mapToResponse(ContractTemplate template) {
        return ContractTemplateResponse.builder()
                .id(template.getId())
                .name(template.getName())
                .rentalContent(template.getRentalContent())
                .landlordDuty(template.getLandlordDuty())
                .tenantDuty(template.getTenantDuty())
                .executionTerms(template.getExecutionTerms())
                .isActive(template.getIsActive())
                .createdAt(template.getCreatedAt())
                .updatedAt(template.getUpdatedAt())
                .build();
    }
}