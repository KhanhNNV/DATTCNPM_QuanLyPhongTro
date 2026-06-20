package ut.edu.be_quanlytro.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ut.edu.be_quanlytro.Dto.Request.ContractTemplateRequest;
import ut.edu.be_quanlytro.Dto.Response.ContractTemplateResponse;
import ut.edu.be_quanlytro.Entity.ContractTemplate;
import ut.edu.be_quanlytro.Entity.User;
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

    // ================= 1. TẠO MẪU MỚI (CHỦ TRỌ TỰ TẠO) =================
    @Transactional
    public ContractTemplateResponse createTemplate(ContractTemplateRequest request, UUID landlordId) {
        User landlord = userRepository.findById(landlordId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy thông tin Chủ trọ"));

        ContractTemplate template = ContractTemplate.builder()
                .landlord(landlord)
                .name(request.getName())
                .content(request.getContent())
                .isActive(true)
                .build();

        ContractTemplate savedTemplate = templateRepository.save(template);
        activityLog.createLog(landlord, "CREATE_TEMPLATE", "contract_templates", savedTemplate.getId(), "Tạo mẫu hợp đồng mới: " + savedTemplate.getName());

        return mapToResponse(savedTemplate);
    }

    // ================= 2. LẤY DANH SÁCH MẪU =================
    @Transactional(readOnly = true)
    public List<ContractTemplateResponse> getAllAvailableTemplates(UUID landlordId) {

        // Repository đã lo toàn bộ logic lọc (NULL hoặc ID Chủ trọ)
        List<ContractTemplate> templates = templateRepository.findAvailableTemplatesForLandlord(landlordId);

        if (templates.isEmpty()) {
            System.out.println("Cảnh báo: Không tìm thấy mẫu hệ thống hay mẫu cá nhân nào!");
        }

        return templates.stream()
                .map(this::mapToResponse)
                .toList();
    }

    // ================= 3. XEM CHI TIẾT 1 MẪU =================
    @Transactional(readOnly = true)
    public ContractTemplateResponse getTemplateById(UUID id, UUID landlordId) {
        ContractTemplate template = templateRepository.findActiveById(id);
        if (template == null) throw new RuntimeException("Không tìm thấy mẫu hợp đồng!");

        // Kiểm tra quyền: Chỉ cho xem nếu là mẫu hệ thống (landlord = null) hoặc mẫu của chính mình
        if (template.getLandlord() != null && !template.getLandlord().getId().equals(landlordId)) {
            throw new RuntimeException("Bạn không có quyền xem mẫu hợp đồng của người khác!");
        }

        return mapToResponse(template);
    }

    // ================= 4. CẬP NHẬT MẪU =================
    @Transactional
    public ContractTemplateResponse updateTemplate(UUID id, ContractTemplateRequest request, UUID landlordId) {
        ContractTemplate template = templateRepository.findActiveById(id);
        if (template == null) throw new RuntimeException("Không tìm thấy mẫu hợp đồng!");

        // Chốt chặn 1: Không cho phép sửa mẫu hệ thống
        if (template.getLandlord() == null) {
            throw new RuntimeException("Hành động bị từ chối: Không được phép chỉnh sửa mẫu hợp đồng mặc định của hệ thống!");
        }

        // Chốt chặn 2: Không cho phép sửa mẫu của người khác
        if (!template.getLandlord().getId().equals(landlordId)) {
            throw new RuntimeException("Bạn không có quyền chỉnh sửa mẫu hợp đồng này!");
        }

        template.setName(request.getName());
        template.setContent(request.getContent());

        ContractTemplate updatedTemplate = templateRepository.save(template);
        activityLog.createLog(template.getLandlord(), "UPDATE_TEMPLATE", "contract_templates", updatedTemplate.getId(), "Cập nhật mẫu hợp đồng: " + updatedTemplate.getName());

        return mapToResponse(updatedTemplate);
    }

    // ================= 5. XÓA MẪU (SOFT DELETE) =================
    @Transactional
    public void deleteTemplate(UUID id, UUID landlordId) {
        ContractTemplate template = templateRepository.findActiveById(id);
        if (template == null) throw new RuntimeException("Không tìm thấy mẫu hợp đồng!");

        if (template.getLandlord() == null) {
            throw new RuntimeException("Không được phép xóa mẫu hợp đồng mặc định của hệ thống!");
        }

        if (!template.getLandlord().getId().equals(landlordId)) {
            throw new RuntimeException("Bạn không có quyền xóa mẫu hợp đồng này!");
        }

        // Ẩn mẫu đi (Soft Delete) để không làm hỏng dữ liệu thống kê cũ
        template.setIsActive(false);
        templateRepository.save(template);

        activityLog.createLog(template.getLandlord(), "DELETE_TEMPLATE", "contract_templates", template.getId(), "Xóa mẫu hợp đồng: " + template.getName());
    }

    // ================= MAPPER =================
    private ContractTemplateResponse mapToResponse(ContractTemplate template) {
        return ContractTemplateResponse.builder()
                .id(template.getId())
                .name(template.getName())
                .content(template.getContent())
                .isSystemTemplate(template.getLandlord() == null) // Đánh dấu true nếu là mẫu hệ thống
                .createdAt(template.getCreatedAt())
                .updatedAt(template.getUpdatedAt())
                .build();
    }
}