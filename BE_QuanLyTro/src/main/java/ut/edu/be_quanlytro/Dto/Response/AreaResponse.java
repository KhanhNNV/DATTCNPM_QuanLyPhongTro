package ut.edu.be_quanlytro.Dto.Response;

import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;
import java.util.UUID;

@Getter @Builder
public class AreaResponse {
    private String name;
    private String address;
    private Integer invoiceDay;
    private Integer dueDate;
    private LocalDateTime createdAt;
}