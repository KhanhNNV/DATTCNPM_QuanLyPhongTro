package ut.edu.be_quanlytro.Dto.Request;

import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.util.List;

@Getter
@Setter
public class OnboardingRequest {

    // --- 1. THÔNG TIN KHU TRỌ ---
    private String name;
    private String address;
    private Integer invoiceDay;
    private Integer dueDate;

    // --- 2. THÔNG TIN DỊCH VỤ CƠ BẢN ---
    private List<AreaServiceRequest> services;

    // --- 3. THÔNG TIN PHÒNG HÀNG LOẠT ---
    private List<Integer> roomsPerFloor;
    private Float defaultAreaSize;
    private BigDecimal defaultRentPrice;
    private BigDecimal defaultDepositAmount;
    private Integer defaultMaxOccupants;
    private String bankId;
    private String accountNo;
    private String accountName;
}