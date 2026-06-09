package ut.edu.be_quanlytro.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;


@Component
@RequiredArgsConstructor
public class DepositScheduler {

    private final DepositService depositService;

    /**
     * Tự động quét và xử lý phiếu cọc quá hạn vào lúc 00:00 mỗi đêm.
     * Cấu trúc cron: giây phút giờ ngày tháng thứ
     */
    @Scheduled(cron = "0 0 0 * * *")
    public void runAutoCancelDeposits() {
        depositService.autoCancelExpiredDeposits();
    }

    /**
     * 🧪 MẸO TEST: Nếu bạn muốn hệ thống quét liên tục 10 giây một lần để demo/test cho nhanh,
     * hãy comment hàm cron ở trên lại và mở khóa dòng dưới đây:
     */
//     @Scheduled(fixedRate = 10000)
//     public void testRun() { depositService.autoCancelExpiredDeposits(); }
}