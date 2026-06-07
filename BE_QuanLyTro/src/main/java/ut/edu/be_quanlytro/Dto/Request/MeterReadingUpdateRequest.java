package ut.edu.be_quanlytro.Dto.Request;

import lombok.Data;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

@Data
public class MeterReadingUpdateRequest {
    @NotNull(message = "Chỉ số mới không được để trống")
    @Min(value = 0, message = "Chỉ số mới không thể là số âm")
    private Integer newIndex;
}