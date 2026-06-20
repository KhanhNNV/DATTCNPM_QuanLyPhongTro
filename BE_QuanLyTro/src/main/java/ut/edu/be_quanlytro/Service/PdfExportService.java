package ut.edu.be_quanlytro.Service;

import com.openhtmltopdf.pdfboxout.PdfRendererBuilder;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;

@Service
public class PdfExportService {

    public byte[] generatePdfFromHtml(String htmlContent) {
        if (htmlContent == null || htmlContent.isEmpty()) {
            throw new RuntimeException("Nội dung hợp đồng trống, không thể xuất PDF!");
        }

        try (ByteArrayOutputStream os = new ByteArrayOutputStream()) {
            // 1. Dùng Jsoup ép HTML lộn xộn thành XHTML chuẩn xác 100%
            Document document = Jsoup.parse(htmlContent, "UTF-8");
            document.outputSettings().syntax(Document.OutputSettings.Syntax.xml);
            String xhtml = document.html();

            // 2. Dựng PDF
            PdfRendererBuilder builder = new PdfRendererBuilder();
            builder.useFastMode();
            builder.withHtmlContent(xhtml, null); // Truyền HTML vào

            // Tạm thời dùng font mặc định. (Tiếng Việt có thể bị lỗi font, sẽ xử lý sau).

            builder.toStream(os);
            builder.run();

            return os.toByteArray(); // Trả ra mảng byte (file PDF)
        } catch (Exception e) {
            throw new RuntimeException("Lỗi trong quá trình xuất file PDF: " + e.getMessage());
        }
    }
}