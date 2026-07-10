package ut.edu.be_quanlytro.Service;

import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

@Service
public class CloudinaryCleanupService {

    private final CloudinaryService cloudinaryService;

    public CloudinaryCleanupService(CloudinaryService cloudinaryService) {
        this.cloudinaryService = cloudinaryService;
    }

    // Annotation này biến hàm thành một Background Thread (Thợ phụ)
    @Async
    public void deleteContractFilesAsync(String contractFileUrl, String signatureUrl) {
        System.out.println("Đang tiến hành dọn dẹp Cloudinary...");
        try {
            if (contractFileUrl != null && !contractFileUrl.isEmpty()) {
                cloudinaryService.deleteFile(contractFileUrl);
            }
            if (signatureUrl != null && !signatureUrl.isEmpty()) {
                cloudinaryService.deleteFile(signatureUrl);
            }
            System.out.println("Đã dọn dẹp file Cloudinary thành công!");
        } catch (Exception e) {
            // Chỉ in log, không làm ảnh hưởng đến luồng chính
            System.err.println("Lỗi xóa file Cloud: " + e.getMessage());
        }
    }
}