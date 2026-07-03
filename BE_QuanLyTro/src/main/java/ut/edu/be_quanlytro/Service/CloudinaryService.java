package ut.edu.be_quanlytro.Service;

import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import ut.edu.be_quanlytro.Exception.BadRequestException;

import java.io.IOException;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class CloudinaryService {

    private final Cloudinary cloudinary;

    // ================= 1. UPLOAD FILE =================
    public String uploadFile(MultipartFile multipartFile, String folderName) {
        try {
            Map uploadResult = cloudinary.uploader().upload(
                    multipartFile.getBytes(),
                    ObjectUtils.asMap(
                            "folder", folderName,
                            "resource_type", "auto" // Lệnh phép thuật giúp nhận diện đúng file PDF/Word
                    )
            );
            return uploadResult.get("secure_url").toString();
        } catch (IOException e) {
            throw new BadRequestException("Lỗi xử lý file khi upload lên Cloudinary: " + e.getMessage());
        }
    }

    // ================= 2. XÓA FILE TRÊN CLOUD (Đã fix lỗi không xóa được PDF) =================
    public void deleteFile(String url) {
        if (url == null || url.isEmpty()) {
            return;
        }
        try {
            String publicId = extractPublicId(url);
            if (publicId != null) {
                // Xác định kiểu file để Cloudinary xóa cho đúng (image, video, hay raw)
                String resourceType = "image"; // Mặc định là ảnh
                if (url.contains("/raw/upload/")) {
                    resourceType = "raw"; // Dành cho file PDF, DOCX, ZIP...
                } else if (url.contains("/video/upload/")) {
                    resourceType = "video"; // Dành cho Video
                }

                // Gọi lệnh destroy kèm theo resource_type
                cloudinary.uploader().destroy(publicId, ObjectUtils.asMap("resource_type", resourceType));
            }
        } catch (IOException e) {
            throw new BadRequestException("Lỗi xảy ra trong quá trình xóa file trên Cloudinary: " + e.getMessage());
        }
    }

    // ================= HÀM BỔ TRỢ: BÓC TÁCH PUBLIC_ID TỪ URL =================
    private String extractPublicId(String url) {
        if (!url.contains("/upload/")) {
            return null;
        }

        // 1. Cắt bỏ phần đầu, lấy từ sau chữ "/upload/" trở đi
        String partAfterUpload = url.substring(url.indexOf("/upload/") + 8);

        // 2. Nếu có phần version (bắt đầu bằng chữ 'v' và các chữ số) thì cắt bỏ tiếp
        if (partAfterUpload.startsWith("v")) {
            partAfterUpload = partAfterUpload.substring(partAfterUpload.indexOf("/") + 1);
        }

        // 3. Cắt bỏ phần đuôi mở rộng (.jpg, .png, .mp4, .pdf...)
        int dotIndex = partAfterUpload.lastIndexOf(".");
        if (dotIndex != -1) {
            return partAfterUpload.substring(0, dotIndex);
        }

        return partAfterUpload;
    }
}