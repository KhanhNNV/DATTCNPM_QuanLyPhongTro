package ut.edu.be_quanlytro.Dto.Response;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDate;
import java.util.UUID;

@Data
@Builder
public class MeterReadingResponse {
    private UUID id;
    private UUID serviceId;
    private String roomNumber;
    private String serviceName;
    private Integer oldIndex;
    private Integer newIndex;
    private LocalDate readingDate;
    private Boolean isInvoiced;
}