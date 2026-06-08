package ut.edu.be_quanlytro.Service;

import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class CloudinaryService {

    private final Cloudinary cloudinary;

    // ================= UPLOAD FILE =================
    public String uploadFile(MultipartFile multipartFile, String folderName) {
        try {
            Map uploadResult = cloudinary.uploader().upload(
                    multipartFile.getBytes(),
                    ObjectUtils.asMap("folder", folderName)
            );
            return uploadResult.get("secure_url").toString();
        } catch (IOException e) {
            throw new RuntimeException("Lỗi xảy ra trong quá trình upload file lên Cloudinary: " + e.getMessage());
        }
    }

    // ================= XÓA FILE TRÊN CLOUD =================
    public void deleteFile(String url) {
        if (url == null || url.isEmpty()) {
            return;
        }
        try {
            String publicId = extractPublicId(url);
            if (publicId != null) {
                // Gọi lệnh destroy của Cloudinary SDK để xóa file tận gốc
                cloudinary.uploader().destroy(publicId, ObjectUtils.emptyMap());
            }
        } catch (IOException e) {
            throw new RuntimeException("Lỗi xảy ra trong quá trình xóa file trên Cloudinary: " + e.getMessage());
        }
    }

    // ================= HÀM BỔ TRỢ: BÓC TÁCH PUBLIC_ID TỪ URL =================
    // Ví dụ URL: https://res.cloudinary.com/dqg0ynz6p/image/upload/v1780899770/signatures/gsf0x3cafa2yzzfqibeg.jpg
    // Kết quả bóc tách cần đạt: "signatures/gsf0x3cafa2yzzfqibeg"
    private String extractPublicId(String url) {
        if (!url.contains("/upload/")) {
            return null;
        }

        // 1. Cắt bỏ phần đầu, lấy từ sau chữ "/upload/" trở đi
        String partAfterUpload = url.substring(url.indexOf("/upload/") + 8);

        // 2. Nếu có phần version (bắt đầu bằng chữ 'v' và các chữ số, ví dụ: v1780899770/) thì cắt bỏ tiếp
        if (partAfterUpload.startsWith("v")) {
            partAfterUpload = partAfterUpload.substring(partAfterUpload.indexOf("/") + 1);
        }

        // 3. Cắt bỏ phần đuôi mở rộng (.jpg, .png, .mp4...)
        int dotIndex = partAfterUpload.lastIndexOf(".");
        if (dotIndex != -1) {
            return partAfterUpload.substring(0, dotIndex);
        }

        return partAfterUpload;
    }
}