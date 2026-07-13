package ut.edu.be_quanlytro.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import ut.edu.be_quanlytro.Dto.Response.IssueResponse;
import ut.edu.be_quanlytro.Dto.Response.PageResponse;
import ut.edu.be_quanlytro.Entity.Contract;
import ut.edu.be_quanlytro.Entity.Enum.ContractStatus;
import ut.edu.be_quanlytro.Entity.Enum.IssueStatus;
import ut.edu.be_quanlytro.Entity.Enum.NotificationType;
import ut.edu.be_quanlytro.Entity.Issue;
import ut.edu.be_quanlytro.Entity.Room;
import ut.edu.be_quanlytro.Exception.BadRequestException;
import ut.edu.be_quanlytro.Exception.ResourceNotFoundException;
import ut.edu.be_quanlytro.Repository.ContractRepository;
import ut.edu.be_quanlytro.Repository.IssueRepository;
import ut.edu.be_quanlytro.Repository.RoomRepository;

import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional // 🚀 Đặt ở đây để bảo kê toàn bộ class, chống lỗi LazyLoad triệt để
public class IssueService {

    private final IssueRepository issueRepository;
    private final RoomRepository roomRepository;
    private final ContractRepository contractRepository;
    private final CloudinaryService cloudinaryService;
    private final NotificationService notificationService;

    public IssueResponse reportIssue(UUID roomId, String description, MultipartFile image, UUID tenantId) {

        // 1. Tận dụng hàm tìm hợp đồng đang hiệu lực của Khách thuê
        Contract activeContract = contractRepository.findByTenantIdAndStatus(tenantId, ContractStatus.SIGNED)
                .orElseThrow(() -> new AccessDeniedException("Bạn không có hợp đồng thuê nào đang hoạt động!"));

        // 2. Chốt chặn bảo mật: Phòng gửi lên có khớp với phòng trong hợp đồng không?
        if (!activeContract.getRoom().getId().equals(roomId)) {
            throw new AccessDeniedException("Bạn không phải khách thuê của phòng này nên không thể báo cáo sự cố!");
        }

        // 3. DIỆT LỖI TẠI ĐÂY: Truy vấn lấy thẳng Entity Room thật từ DB lên, nói KHÔNG với proxy
        Room room = roomRepository.findById(roomId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy phòng!"));

        if (description == null || description.trim().isEmpty()) {
            throw new BadRequestException("Vui lòng nhập mô tả sự cố (ví dụ: hỏng bóng đèn, tắc bồn cầu...)!");
        }

        // 4. Xử lý upload ảnh (nếu có)
        String imageUrl = null;
        if (image != null && !image.isEmpty()) {
            imageUrl = cloudinaryService.uploadFile(image, "issues");
        }

        // 5. Lưu sự cố xuống Database
        Issue issue = Issue.builder()
                .room(room)
                .tenant(activeContract.getTenant())
                .description(description)
                .imageUrl(imageUrl)
                .status(IssueStatus.PENDING)
                .build();

        issue = issueRepository.save(issue);

        // 6. Bắn thông báo ngay cho Chủ trọ biết
        String title = "Có báo cáo sự cố mới!";
        String content = String.format("Phòng %s vừa báo cáo sự cố: %s. Vui lòng kiểm tra và xử lý!",
                room.getRoomNumber(), description);

        notificationService.createNotification(
                room.getArea().getLandlord(), // Khúc này Room đã lấy thật từ DB nên getArea() sẽ trơn tru
                title,
                content,
                NotificationType.ISSUE_CREATED
        );

        return convertToResponse(issue);
    }
    public IssueResponse updateIssueStatus(UUID issueId, IssueStatus newStatus, String solutionNote, UUID landlordId) {
        Issue issue = issueRepository.findById(issueId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy báo cáo sự cố này!"));

        // Chốt chặn bảo mật: Chỉ Chủ trọ của khu trọ đó mới được quyền cập nhật
        if (!issue.getRoom().getArea().getLandlord().getId().equals(landlordId)) {
            throw new AccessDeniedException("Bạn không có quyền cập nhật sự cố của khu trọ khác!");
        }

        // Cập nhật trạng thái và ghi chú
        issue.setStatus(newStatus);
        if (solutionNote != null && !solutionNote.trim().isEmpty()) {
            issue.setSolutionNote(solutionNote);
        }

        issue = issueRepository.save(issue);

        // Bắn thông báo về cho Khách thuê biết tiến độ
        String statusText = newStatus == IssueStatus.ACCEPTED ? "Đã tiếp nhận" : "Đã hoàn thành";
        String title = "Cập nhật tiến độ sự cố phòng " + issue.getRoom().getRoomNumber();
        String content = String.format("Sự cố của bạn hiện đang ở trạng thái: %s. Ghi chú từ chủ trọ: %s",
                statusText,
                issue.getSolutionNote() != null ? issue.getSolutionNote() : "Không có");

        notificationService.createNotification(
                issue.getTenant(), // Bắn thẳng về điện thoại khách thuê
                title,
                content,
                NotificationType.ISSUE_UPDATED
        );

        return convertToResponse(issue);
    }

    @Transactional(readOnly = true)
    public PageResponse<IssueResponse> getMyIssues(UUID tenantId, int page, int size) {
        Pageable pageable = PageRequest.of(page, size);
        Page<Issue> issuePage = issueRepository.findByTenantIdOrderByCreatedAtDesc(tenantId, pageable);

        return PageResponse.<IssueResponse>builder()
                .content(issuePage.getContent().stream().map(this::convertToResponse).toList())
                .pageNumber(issuePage.getNumber())
                .pageSize(issuePage.getSize())
                .totalElements(issuePage.getTotalElements())
                .totalPages(issuePage.getTotalPages())
                .isLast(issuePage.isLast())
                .build();
    }

    /**
     * API: Chủ trọ xem toàn bộ danh sách báo cáo sự cố của khu trọ
     */
    @Transactional(readOnly = true)
    public PageResponse<IssueResponse> getIssuesForLandlord(UUID landlordId, int page, int size) {
        Pageable pageable = PageRequest.of(page, size);
        Page<Issue> issuePage = issueRepository.findByRoomAreaLandlordIdOrderByCreatedAtDesc(landlordId, pageable);

        return PageResponse.<IssueResponse>builder()
                .content(issuePage.getContent().stream().map(this::convertToResponse).toList())
                .pageNumber(issuePage.getNumber())
                .pageSize(issuePage.getSize())
                .totalElements(issuePage.getTotalElements())
                .totalPages(issuePage.getTotalPages())
                .isLast(issuePage.isLast())
                .build();
    }

    private IssueResponse convertToResponse(Issue issue) {
        return IssueResponse.builder()
                .id(issue.getId())
                .roomNumber(issue.getRoom().getRoomNumber())
                .tenantName(issue.getTenant().getFullName())
                .description(issue.getDescription())
                .imageUrl(issue.getImageUrl())
                .status(issue.getStatus().name())
                .solutionNote(issue.getSolutionNote())
                .createdAt(issue.getCreatedAt())
                .build();
    }
}