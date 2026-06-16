package ut.edu.be_quanlytro.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ut.edu.be_quanlytro.Dto.Request.InvoiceCreateRequest;
import ut.edu.be_quanlytro.Dto.Response.InvoiceDetailResponse;
import ut.edu.be_quanlytro.Dto.Response.InvoiceItemResponse;
import ut.edu.be_quanlytro.Dto.Response.InvoiceResponse;
import ut.edu.be_quanlytro.Dto.Response.PaymentQrResponse;
import ut.edu.be_quanlytro.Entity.*;
import ut.edu.be_quanlytro.Entity.Enum.ContractStatus;
import ut.edu.be_quanlytro.Entity.Enum.InvoiceStatus;
import ut.edu.be_quanlytro.Repository.*;
import java.util.UUID;

import java.math.BigDecimal;
import java.util.List;

@Service
@RequiredArgsConstructor
public class InvoiceService {
    private final InvoiceRepository invoiceRepository;
    private final InvoiceDetailRepository invoiceDetailRepository;
    private final ContractRepository contractRepository;
    private final MeterReadingRepository meterReadingRepository;
    private final AreaServiceRepository areaServiceRepository;

    @Transactional
    public InvoiceResponse createInvoice(InvoiceCreateRequest request) {
        if (invoiceRepository.existsByRoomIdAndInvoicePeriod(request.getRoomId(), request.getInvoicePeriod())) {
            throw new RuntimeException("Phòng này đã được tạo hóa đơn cho kỳ " + request.getInvoicePeriod());
        }
        Contract contract = contractRepository.findByRoomId(request.getRoomId()).stream()
                .filter(c -> c.getStatus() == ContractStatus.SIGNED)
                .findFirst()
                .orElseThrow(() -> new RuntimeException("Phòng này hiện không có hợp đồng nào đang thuê hợp lệ!"));

        Room room = contract.getRoom();
        Area area = room.getArea();
        BigDecimal totalAmount = contract.getRoom().getRentPrice(); // lay gia phong goc

        Invoice invoice = Invoice.builder()
                .contract(contract)
                .room(room)
                .invoicePeriod(request.getInvoicePeriod())
                .dueDate(request.getInvoicePeriod().plusDays(area.getDueDate() != null ? area.getDueDate() : 5))
                .roomPrice(contract.getRoom().getRentPrice())
                .status(InvoiceStatus.UNPAID)
                .build();

        invoice = invoiceRepository.save(invoice);

        List<AreaService> areaServices = areaServiceRepository.findByAreaIdAndIsActiveTrue(area.getId());
        for (AreaService service : areaServices) {
            InvoiceDetail detail = InvoiceDetail.builder()
                    .invoice(invoice)
                    .serviceName(service.getName())
                    .price(service.getPrice())
                    .build();
            switch (service.getCalcType()) {
                case BY_INDEX:
                    MeterReading reading = meterReadingRepository.
                            findFirstByRoomIdAndServiceIdAndIsInvoicedFalse(room.getId(), service.getId())
                            .orElseThrow(() -> new RuntimeException("Chưa chốt số " + service.getName() + " cho phòng này!"));
                    int usage = reading.getNewIndex() - reading.getOldIndex();
                    detail.setOldIndex(reading.getOldIndex());
                    detail.setNewIndex(reading.getNewIndex());
                    detail.setQuantity(usage);
                    detail.setTotalAmount(service.getPrice().multiply(BigDecimal.valueOf(usage)));
                    detail.setMeterReading(reading);

                    reading.setIsInvoiced(true);
                    meterReadingRepository.save(reading);
                    break;
                case PER_PERSON:
                    int memberCount = contract.getMembers().size();
                    detail.setQuantity(memberCount);
                    detail.setTotalAmount(service.getPrice().multiply(BigDecimal.valueOf(memberCount)));
                    break;

                case PER_ROOM:
                    detail.setQuantity(1);
                    detail.setTotalAmount(service.getPrice());
                    break;
            }
            invoiceDetailRepository.save(detail);
            totalAmount = totalAmount.add(detail.getTotalAmount());
        }
        invoice.setTotalAmount(totalAmount);
        invoiceRepository.save(invoice);
        return InvoiceResponse.builder()
                .id(invoice.getId())
                .roomNumber(room.getRoomNumber())
                .invoicePeriod(invoice.getInvoicePeriod())
                .dueDate(invoice.getDueDate())
                .roomPrice(invoice.getRoomPrice())
                .totalAmount(invoice.getTotalAmount())
                .status(invoice.getStatus().name())
                .build();
    }


    @Transactional(readOnly = true)
    public InvoiceDetailResponse getInvoiceDetail(UUID invoiceId) {
        // 1. Tìm hóa đơn gốc
        Invoice invoice = invoiceRepository.findById(invoiceId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy hóa đơn yêu cầu!"));

        // 2. Tìm danh sách chi tiết dịch vụ đi kèm hóa đơn đó
        List<InvoiceDetail> details = invoiceDetailRepository.findByInvoiceId(invoiceId);

        // 3. Map từ Entity sang DTO dòng chi tiết
        List<InvoiceItemResponse> itemResponses = details.stream().map(d ->
                InvoiceItemResponse.builder()
                        .serviceName(d.getServiceName())
                        .oldIndex(d.getOldIndex())
                        .newIndex(d.getNewIndex())
                        .quantity(d.getQuantity())
                        .price(d.getPrice())
                        .totalAmount(d.getTotalAmount())
                        .build()
        ).toList();


        return InvoiceDetailResponse.builder()
                .id(invoice.getId())
                .roomNumber(invoice.getRoom().getRoomNumber())
                .invoicePeriod(invoice.getInvoicePeriod())
                .dueDate(invoice.getDueDate())
                .roomPrice(invoice.getRoomPrice())
                .totalAmount(invoice.getTotalAmount())
                .status(invoice.getStatus().name())
                .items(itemResponses)
                .build();
    }

    @Transactional(readOnly = true)
    public PaymentQrResponse generateVietQR(UUID invoiceId) {
        // 1. Tìm hóa đơn
        Invoice invoice = invoiceRepository.findById(invoiceId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy hóa đơn!"));

        // 2. Lấy thông tin ngân hàng của chủ trọ (Giả lập cứng để test)
        String bankId = "MB"; // Ngân hàng Quân Đội
        String accountNo = "0901234567";
        String accountName = "TRAN VAN CHU";

        // 3. Chuẩn bị dữ liệu động
        BigDecimal amount = invoice.getTotalAmount();

        // Tạo nội dung chuyển khoản (Không dấu, ghi rõ Phòng và Tháng)
        // Ví dụ: "P101 THANH TOAN T6"
        String content = String.format("P%s THANH TOAN T%d",
                invoice.getRoom().getRoomNumber(),
                invoice.getInvoicePeriod().getMonthValue());

        // 4. Lắp ráp thành đường link VietQR chuẩn (Quick Link)
        // Nhớ replace khoảng trắng thành %20 để đường link không bị gãy
        String qrUrl = String.format("https://img.vietqr.io/image/%s-%s-compact2.png?amount=%.0f&addInfo=%s&accountName=%s",
                bankId,
                accountNo,
                amount,
                content.replace(" ", "%20"),
                accountName.replace(" ", "%20"));

        // 5. Trả về cho Frontend
        return PaymentQrResponse.builder()
                .bankId(bankId)
                .accountNo(accountNo)
                .accountName(accountName)
                .amount(amount)
                .content(content)
                .qrImageUrl(qrUrl)
                .build();
    }
}


