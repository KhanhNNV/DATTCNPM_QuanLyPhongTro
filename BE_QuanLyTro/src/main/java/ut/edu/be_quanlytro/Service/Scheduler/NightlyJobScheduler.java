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

    @Scheduled(cron = "0 0 0 * * ?")
    public void executeAllNightlyJobs() {

        System.out.println("BẮT ĐẦU CHẠY CÁC TIẾN TRÌNH NỬA ĐÊM...");

        try {
            System.out.println("[1/2] Đang quét phiếu đặt cọc...");
            depositService.autoCancelExpiredDeposits();

            System.out.println("[2/2] Đang quét hợp đồng...");
            contractService.autoCheckAndExpireContracts();

            System.out.println("[3/3] Đang xuất hóa đơn tháng mới...");
            invoiceService.autoGenerateMonthlyInvoices();

            System.out.println("[4/5] Đang quét gửi thông báo nhắc nợ...");
            invoiceService.autoRemindMonthlyDebts();

            System.out.println("[5/5] Đang quét cập nhật trạng thái quá hạn...");
            invoiceService.autoUpdateOverdueInvoices();

        } catch (Exception e) {
            System.err.println("CÓ LỖI XẢY RA: " + e.getMessage());
        }

        System.out.println("ĐÃ HOÀN TẤT TOÀN BỘ TÁC VỤ ĐÊM!");
    }

//    @Scheduled(fixedRate = 10000)
//    public void testRun() { executeAllNightlyJobs(); }
}