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
import ut.edu.be_quanlytro.Entity.User;
import ut.edu.be_quanlytro.Exception.BadRequestException;
import ut.edu.be_quanlytro.Exception.ResourceNotFoundException;
import ut.edu.be_quanlytro.Repository.ContractRepository;
import ut.edu.be_quanlytro.Repository.IssueRepository;
import ut.edu.be_quanlytro.Repository.RoomRepository;
import ut.edu.be_quanlytro.Repository.UserRepository;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class IssueService {

    private final IssueRepository issueRepository;
    private final RoomRepository roomRepository;
    private final UserRepository userRepository;
    private final ContractRepository contractRepository;
    private final CloudinaryService cloudinaryService;
    private final NotificationService notificationService;

    @Transactional
    public IssueResponse reportIssue(UUID roomId, String description, MultipartFile image, UUID tenantId) {
        // 1. Kiểm tra phòng
        Room room = roomRepository.findById(roomId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy phòng!"));

        // 2. Chốt chặn bảo mật: Người báo cáo phải là Khách đang thuê phòng này
        Contract activeContract = contractRepository.findByRoomId(roomId).stream()
                .filter(c -> c.getStatus() == ContractStatus.SIGNED && c.getTenant().getId().equals(tenantId))
                .findFirst()
                .orElseThrow(() -> new AccessDeniedException("Bạn không phải khách thuê của phòng này nên không thể báo cáo sự cố!"));

        User tenant = userRepository.findById(tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy thông tin khách thuê!"));

        if (description == null || description.trim().isEmpty()) {
            throw new BadRequestException("Vui lòng nhập mô tả sự cố (ví dụ: hỏng bóng đèn, tắc bồn cầu...)!");
        }

        // 3. Xử lý upload ảnh (nếu có)
        String imageUrl = null;
        if (image != null && !image.isEmpty()) {
            imageUrl = cloudinaryService.uploadFile(image, "issues"); // Đẩy vào folder "issues" trên Cloudinary
        }

        // 4. Lưu sự cố xuống Database
        Issue issue = Issue.builder()
                .room(room)
                .tenant(tenant)
                .description(description)
                .imageUrl(imageUrl)
                .status(IssueStatus.PENDING) // Mặc định là Chờ xử lý
                .build();

        issue = issueRepository.save(issue);

        // 5. Bắn thông báo ngay cho Chủ trọ biết
        String title = "Có báo cáo sự cố mới!";
        String content = String.format("Phòng %s vừa báo cáo sự cố: %s. Vui lòng kiểm tra và xử lý!",
                room.getRoomNumber(), description);

        notificationService.createNotification(
                room.getArea().getLandlord(), // Gửi tới chủ trọ
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