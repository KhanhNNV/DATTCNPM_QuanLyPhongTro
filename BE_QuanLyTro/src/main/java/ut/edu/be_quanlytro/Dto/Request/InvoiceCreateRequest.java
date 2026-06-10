package ut.edu.be_quanlytro.Dto.Request;

import lombok.Data;
import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;
import java.util.UUID;

@Data
public class InvoiceCreateRequest {

    @NotNull(message = "ID Phòng không được để trống")
    private UUID roomId;

    @NotNull(message = "Kỳ xuất hóa đơn không được để trống")

    private LocalDate invoicePeriod;
}