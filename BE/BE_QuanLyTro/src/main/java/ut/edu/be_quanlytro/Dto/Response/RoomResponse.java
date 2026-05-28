package ut.edu.be_quanlytro.Dto.Response;
import lombok.*;
import ut.edu.be_quanlytro.Entity.Enum.RoomStatus;
import java.math.BigDecimal;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RoomResponse {

    private String areaName;
    private Integer floor;
    private String roomNumber;
    private Float areaSize;
    private BigDecimal rentPrice;
    private BigDecimal depositAmount;
    private Integer maxOccupants;
    private RoomStatus status;
}
