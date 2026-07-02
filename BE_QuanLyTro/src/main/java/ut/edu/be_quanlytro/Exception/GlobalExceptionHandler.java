package ut.edu.be_quanlytro.Exception;

import jakarta.validation.ConstraintViolationException;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;
import java.util.stream.Collectors;

@RestControllerAdvice
public class GlobalExceptionHandler {

    /* ===================== 1. LỖI VALIDATION dữ liệu đầu vào (@Valid ở RequestBody) ===================== */
    // Ví dụ: Khách thuê để trống số điện thoại, mật khẩu quá ngắn... khi đăng ký
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleMethodArgumentNotValid(MethodArgumentNotValidException ex) {
        Map<String, String> errors = new HashMap<>();
        ex.getBindingResult().getFieldErrors()
                .forEach(error -> errors.put(error.getField(), error.getDefaultMessage()));

        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(new ErrorResponse(
                        400,
                        "Dữ liệu gửi lên không hợp lệ",
                        errors,
                        LocalDateTime.now()
                ));
    }

    /* ===================== 2. LỖI VALIDATION tham số trên URL (@Validated Param) ===================== */
    // Ví dụ: Lý do từ chối hóa đơn truyền vào param bị trống hoặc sai điều kiện ràng buộc
    @ExceptionHandler(ConstraintViolationException.class)
    public ResponseEntity<ErrorResponse> handleConstraintViolation(ConstraintViolationException ex) {
        Map<String, String> errors = ex.getConstraintViolations().stream()
                .collect(Collectors.toMap(
                        v -> v.getPropertyPath().toString(),
                        v -> v.getMessage(),
                        (msg1, msg2) -> msg1
                ));

        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(new ErrorResponse(
                        400,
                        "Tham số URL không hợp lệ",
                        errors,
                        LocalDateTime.now()
                ));
    }

    /* ===================== 3. LỖI DỮ LIỆU JSON SAI FORMAT ===================== */
    // Ví dụ: Bạn làm Android viết thiếu dấu ngoặc nhọn {}, dấu phẩy hoặc truyền sai kiểu dữ liệu
    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<ErrorResponse> handleInvalidJson(HttpMessageNotReadableException ex) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(new ErrorResponse(
                        400,
                        "Định dạng dữ liệu không hợp lệ",
                        "JSON gửi lên bị lỗi cú pháp hoặc sai kiểu dữ liệu",
                        LocalDateTime.now()
                ));
    }

    /* ===================== 4. LỖI THIẾU THAM SỐ BẮT BUỘC ===================== */
    // Ví dụ: API yêu cầu truyền request param tên là "reason" nhưng Android quên không truyền
    @ExceptionHandler(MissingServletRequestParameterException.class)
    public ResponseEntity<ErrorResponse> handleMissingParam(MissingServletRequestParameterException ex) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(new ErrorResponse(
                        400,
                        "Thiếu dữ liệu bắt buộc",
                        "Thiếu tham số param: " + ex.getParameterName(),
                        LocalDateTime.now()
                ));
    }

    /* ===================== 5. LỖI SAI KIỂU DỮ LIỆU PARAM ===================== */
    // Ví dụ: URL nhận vào UUID hoặc số int, nhưng Android lại truyền lên một chuỗi chữ "abc"
    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ResponseEntity<ErrorResponse> handleTypeMismatch(MethodArgumentTypeMismatchException ex) {
        String message = String.format(
                "Giá trị '%s' không hợp lệ cho tham số '%s'. Yêu cầu kiểu: %s",
                ex.getValue(),
                ex.getName(),
                ex.getRequiredType() != null ? ex.getRequiredType().getSimpleName() : "không xác định"
        );

        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(new ErrorResponse(
                        400,
                        "Sai kiểu dữ liệu tham số",
                        message,
                        LocalDateTime.now()
                ));
    }

    /* ===================== 6. LỖI CHƯA ĐĂNG NHẬP (401 UNAUTHORIZED) ===================== */
    @ExceptionHandler(AuthenticationException.class)
    public ResponseEntity<ErrorResponse> handleAuthentication(AuthenticationException ex) {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(new ErrorResponse(
                        401,
                        "Chưa xác thực tài khoản",
                        "Vui lòng đăng nhập để thực hiện tính năng này",
                        LocalDateTime.now()
                ));
    }

    /* ===================== 7. LỖI SAI QUYỀN TRUY CẬP (403 FORBIDDEN) ===================== */
    // Ví dụ: Khách thuê cố tình gọi API duyệt hóa đơn vốn chỉ dành cho ROLE_LANDLORD
    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<ErrorResponse> handleAccessDenied(AccessDeniedException ex) {
        return ResponseEntity.status(HttpStatus.FORBIDDEN)
                .body(new ErrorResponse(
                        403,
                        "Quyền truy cập bị từ chối",
                        "Tài khoản của bạn không có quyền thực hiện chức năng này!",
                        LocalDateTime.now()
                ));
    }

    /* ===================== 8. LỖI KHÔNG TÌM THẤY DỮ LIỆU (404 NOT FOUND) ===================== */
    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleNotFound(ResourceNotFoundException ex) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(new ErrorResponse(
                        404,
                        "Không tìm thấy dữ liệu",
                        ex.getMessage(),
                        LocalDateTime.now()
                ));
    }

    /* ===================== 9. LỖI XUNG ĐỘT DỮ LIỆU / TRÙNG LẶP DB (409 CONFLICT) ===================== */
    // Ví dụ: Thêm mới một phòng trọ trùng số phòng đã có, hoặc đăng ký trùng Số điện thoại
    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<ErrorResponse> handleDuplicate(DataIntegrityViolationException ex) {
        String message = "Dữ liệu đã tồn tại hoặc vi phạm ràng buộc cơ sở dữ liệu";
        if (ex.getMessage() != null && ex.getMessage().contains("Duplicate entry")) {
            message = "Dữ liệu này đã tồn tại trong hệ thống, không thể tạo trùng!";
        }

        return ResponseEntity.status(HttpStatus.CONFLICT)
                .body(new ErrorResponse(
                        409,
                        "Xung đột dữ liệu",
                        message,
                        LocalDateTime.now()
                ));
    }

    /* ===================== 10. LỖI NGHIỆP VỤ DO DỰ ÁN TỰ ĐỊNH NGHĨA (400) ===================== */
    // Bắt cái BadRequestException tự tạo lúc nãy của anh em mình
    @ExceptionHandler(BadRequestException.class)
    public ResponseEntity<ErrorResponse> handleBadRequest(BadRequestException ex) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(new ErrorResponse(
                        400,
                        "Yêu cầu không hợp lệ",
                        ex.getMessage(),
                        LocalDateTime.now()
                ));
    }

    /* ===================== 11. CÁC LỖI RUNTIME CHUNG KHÁC (400) ===================== */
    @ExceptionHandler(RuntimeException.class)
    public ResponseEntity<ErrorResponse> handleRuntime(RuntimeException ex) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(new ErrorResponse(
                        400,
                        "Lỗi xử lý hệ thống",
                        ex.getMessage(),
                        LocalDateTime.now()
                ));
    }

    /* ===================== 12. LỖI TỐI CAO - LỖI SERVER HỆ THỐNG (500) ===================== */
    // Dành cho các lỗi bất ngờ như NullPointerException, lỗi tràn bộ nhớ... chưa kịp lường trước
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleException(Exception ex) {
        ex.printStackTrace(); // In log ra console BE để dev dễ check dấu vết bug
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(new ErrorResponse(
                        500,
                        "Lỗi Server hệ thống",
                        "Đã xảy ra lỗi không xác định trên Server. Vui lòng thử lại sau.",
                        LocalDateTime.now()
                ));
    }
}