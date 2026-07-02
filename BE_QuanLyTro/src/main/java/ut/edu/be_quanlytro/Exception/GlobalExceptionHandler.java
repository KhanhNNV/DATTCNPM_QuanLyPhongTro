package ut.edu.be_quanlytro.Exception;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.time.LocalDateTime;

@RestControllerAdvice
public class GlobalExceptionHandler {

    /* ===================== 404 - KHÔNG TÌM THẤY ===================== */
    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleNotFound(ResourceNotFoundException ex) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(new ErrorResponse(404, "Không tìm thấy dữ liệu", ex.getMessage(), LocalDateTime.now()));
    }

    /* ===================== 400 - LỖI NGHIỆP VỤ (BUSINESS LOGIC) ===================== */
    @ExceptionHandler(BadRequestException.class)
    public ResponseEntity<ErrorResponse> handleBadRequest(BadRequestException ex) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(new ErrorResponse(400, "Yêu cầu không hợp lệ", ex.getMessage(), LocalDateTime.now()));
    }

    /* ===================== 400 - CÁC LỖI RUNTIME CHUNG ===================== */
    @ExceptionHandler(RuntimeException.class)
    public ResponseEntity<ErrorResponse> handleRuntime(RuntimeException ex) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(new ErrorResponse(400, "Lỗi xử lý hệ thống", ex.getMessage(), LocalDateTime.now()));
    }

    /* ===================== 500 - LỖI SERVER CHƯA BẮT ĐƯỢC ===================== */
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleException(Exception ex) {
        ex.printStackTrace(); // In ra console để dev debug
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(new ErrorResponse(500, "Lỗi Server", "Đã xảy ra lỗi không xác định!", LocalDateTime.now()));
    }
}