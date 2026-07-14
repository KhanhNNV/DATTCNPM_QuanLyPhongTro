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
    /**
     * API: Khách thuê CẬP NHẬT báo cáo sự cố (Chỉ khi đang PENDING)
     */
    public IssueResponse updateMyIssue(UUID issueId, String newDescription, MultipartFile newImage, UUID tenantId) {
        Issue issue = issueRepository.findById(issueId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy báo cáo sự cố!"));

        // 1. Chốt chặn 1: Đúng chính chủ mới được sửa
        if (!issue.getTenant().getId().equals(tenantId)) {
            throw new AccessDeniedException("Bạn không có quyền sửa báo cáo của người khác!");
        }

        // 2. Chốt chặn 2: Chỉ cho phép sửa khi chủ trọ chưa đụng tay vào
        if (issue.getStatus() != IssueStatus.PENDING) {
            throw new BadRequestException("Sự cố đã được tiếp nhận hoặc xử lý, bạn không thể thay đổi thông tin nữa!");
        }

        // 3. Cập nhật dữ liệu
        if (newDescription != null && !newDescription.trim().isEmpty()) {
            issue.setDescription(newDescription);
        }

        if (newImage != null && !newImage.isEmpty()) {
            // (Mẹo Pro: Nếu hệ thống lớn, chỗ này nên gọi hàm xóa ảnh cũ trên Cloudinary để đỡ tốn dung lượng)
            String newImageUrl = cloudinaryService.uploadFile(newImage, "issues");
            issue.setImageUrl(newImageUrl);
        }

        return convertToResponse(issueRepository.save(issue));
    }

    /**
     * API: Khách thuê XÓA/THU HỒI báo cáo sự cố (Chỉ khi đang PENDING)
     */
    public void deleteMyIssue(UUID issueId, UUID tenantId) {
        Issue issue = issueRepository.findById(issueId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy báo cáo sự cố!"));

        if (!issue.getTenant().getId().equals(tenantId)) {
            throw new AccessDeniedException("Bạn không có quyền xóa báo cáo của người khác!");
        }

        if (issue.getStatus() != IssueStatus.PENDING) {
            throw new BadRequestException("Sự cố đã được tiếp nhận, không thể thu hồi. Vui lòng liên hệ chủ trọ!");
        }

        // Thực hiện xóa khỏi DB
        issueRepository.delete(issue);
    }

    /**
     * API: Khách thuê xem lịch sử báo cáo sự cố (Có lọc)
     */
    @Transactional(readOnly = true)
    public PageResponse<IssueResponse> getMyIssues(UUID tenantId, IssueStatus status, int page, int size) {
        Pageable pageable = PageRequest.of(page, size);
        Page<Issue> issuePage;

        if (status != null) {
            issuePage = issueRepository.findByTenantIdAndStatusOrderByCreatedAtDesc(tenantId, status, pageable);
        } else {
            issuePage = issueRepository.findByTenantIdOrderByCreatedAtDesc(tenantId, pageable);
        }

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
     * API: Chủ trọ xem danh sách báo cáo sự cố (Có lọc theo Status, Area và Room)
     */
    @Transactional(readOnly = true)
    // 🎯 SỬA Ở ĐÂY: Thêm biến UUID areaId vào tham số
    public PageResponse<IssueResponse> getIssuesForLandlord(UUID landlordId, UUID areaId, UUID roomId, IssueStatus status, int page, int size) {
        Pageable pageable = PageRequest.of(page, size);
        Page<Issue> issuePage;

        // 🎯 SỬA Ở ĐÂY: Xử lý tổ hợp 6 trường hợp lọc dữ liệu
        if (roomId != null && status != null) {
            // 1. Lọc theo phòng + trạng thái (Phòng đã xác định rõ khu trọ rồi)
            issuePage = issueRepository.findByRoomAreaLandlordIdAndRoomIdAndStatusOrderByCreatedAtDesc(landlordId, roomId, status, pageable);
        } else if (roomId != null) {
            // 2. Chỉ lọc theo phòng
            issuePage = issueRepository.findByRoomAreaLandlordIdAndRoomIdOrderByCreatedAtDesc(landlordId, roomId, pageable);
        } else if (areaId != null && status != null) {
            // 3. Lọc theo Khu trọ + Trạng thái
            issuePage = issueRepository.findByRoomAreaLandlordIdAndRoomAreaIdAndStatusOrderByCreatedAtDesc(landlordId, areaId, status, pageable);
        } else if (areaId != null) {
            // 4. Chỉ lọc theo Khu trọ
            issuePage = issueRepository.findByRoomAreaLandlordIdAndRoomAreaIdOrderByCreatedAtDesc(landlordId, areaId, pageable);
        } else if (status != null) {
            // 5. Chỉ lọc theo trạng thái (Toàn bộ các khu)
            issuePage = issueRepository.findByRoomAreaLandlordIdAndStatusOrderByCreatedAtDesc(landlordId, status, pageable);
        } else {
            // 6. Không lọc gì, lấy tất cả (Toàn bộ các khu)
            issuePage = issueRepository.findByRoomAreaLandlordIdOrderByCreatedAtDesc(landlordId, pageable);
        }

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