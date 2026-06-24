package ut.edu.be_quanlytro.Service.Scheduler;

import lombok.RequiredArgsConstructor;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import ut.edu.be_quanlytro.Service.ContractService;
import ut.edu.be_quanlytro.Service.DepositService;
import ut.edu.be_quanlytro.Service.InvoiceService;

@Component
@RequiredArgsConstructor
public class NightlyJobScheduler {

    private final DepositService depositService;
    private final ContractService contractService;
    private final InvoiceService invoiceService;

    /**
     * Đồng hồ báo thức duy nhất của hệ thống: Chạy vào lúc 00:00:00 mỗi đêm.
     * Quản lý tập trung toàn bộ các tiến trình quét tự động.
     */
    @Scheduled(cron = "0 0 0 * * ?")
    public void executeAllNightlyJobs() {

        System.out.println("BẮT ĐẦU CHẠY CÁC TIẾN TRÌNH NỬA ĐÊM...");


        try {
            // TIẾN TRÌNH 1: Dọn dẹp phiếu cọc quá hạn
            System.out.println("[1/2] Đang quét phiếu đặt cọc...");
            depositService.autoCancelExpiredDeposits();

            // TIẾN TRÌNH 2: Xử lý hợp đồng hết hạn
            System.out.println("[2/2] Đang quét hợp đồng...");
            contractService.autoCheckAndExpireContracts();

            // TIẾN TRÌNH 3 (Tương lai): Chốt điện nước & Tạo hóa đơn tự động
           System.out.println("[3/3] Đang xuất hóa đơn tháng mới...");
            invoiceService.autoGenerateMonthlyInvoices();

        } catch (Exception e) {
            // Bọc Try-Catch để lỡ 1 tiến trình bị lỗi (VD: Đứt kết nối DB) thì không làm sập cả hệ thống
            System.err.println("CÓ LỖI XẢY RA: " + e.getMessage());
        }


        System.out.println("ĐÃ HOÀN TẤT TOÀN BỘ TÁC VỤ ĐÊM!");

    }

    /**
     * 🧪 Dùng để test (Chạy liên tục mỗi 10 giây).
     * Khi nào code xong tính năng mới cần test thì mở comment dòng dưới ra.
     */
//     @Scheduled(fixedRate = 10000)
//     public void testRun() { executeAllNightlyJobs(); }
}