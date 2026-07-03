package ut.edu.be_quanlytro.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import ut.edu.be_quanlytro.Dto.Response.IssueResponse;
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