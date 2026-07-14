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

    public String uploadFile(MultipartFile multipartFile, String folderName) {
        try {
            Map uploadResult = cloudinary.uploader().upload(
                    multipartFile.getBytes(),
                    ObjectUtils.asMap(
                            "folder", folderName,
                            "resource_type", "auto"
                    )
            );
            return uploadResult.get("secure_url").toString();
        } catch (IOException e) {
            throw new BadRequestException("Lỗi xử lý file khi upload lên Cloudinary: " + e.getMessage());
        }
    }

    public void deleteFile(String url) {
        if (url == null || url.isEmpty()) {
            return;
        }
        try {
            String publicId = extractPublicId(url);
            if (publicId != null) {
                String resourceType = "image";
                if (url.contains("/raw/upload/")) {
                    resourceType = "raw";
                } else if (url.contains("/video/upload/")) {
                    resourceType = "video";
                }

                cloudinary.uploader().destroy(publicId, ObjectUtils.asMap("resource_type", resourceType));
            }
        } catch (IOException e) {
            throw new BadRequestException("Lỗi xảy ra trong quá trình xóa file trên Cloudinary: " + e.getMessage());
        }
    }

    private String extractPublicId(String url) {
        if (!url.contains("/upload/")) {
            return null;
        }

        String partAfterUpload = url.substring(url.indexOf("/upload/") + 8);

        if (partAfterUpload.startsWith("v")) {
            partAfterUpload = partAfterUpload.substring(partAfterUpload.indexOf("/") + 1);
        }

        int dotIndex = partAfterUpload.lastIndexOf(".");
        if (dotIndex != -1) {
            return partAfterUpload.substring(0, dotIndex);
        }

        return partAfterUpload;
    }
}