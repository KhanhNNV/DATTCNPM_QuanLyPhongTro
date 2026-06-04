package ut.edu.be_quanlytro.Dto.Request;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Data;
import java.time.LocalDate;
import java.util.UUID;

@Data
public class MeterReadingCreateRequest {
    @NotNull
    private UUID roomId;
    @NotNull
    private UUID serviceId;
    @NotNull
    @Min(value = 0)
    private Integer newIndex;
    @NotNull
    private LocalDate readingDate;
}
