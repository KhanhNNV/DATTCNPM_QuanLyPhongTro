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

import java.time.LocalDate;
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
    final AreaRepository areaRepository;

    /**
     * LÚC 1: CHỦ TRỌ BẤM TẠO BẰNG TAY (API MANUAL)
     */
    @Transactional
    public InvoiceResponse createInvoice(InvoiceCreateRequest request, UUID currentUserId) {
        LocalDate normalizedPeriod = request.getInvoicePeriod().withDayOfMonth(1);

        if (invoiceRepository.existsByRoomIdAndInvoicePeriod(request.getRoomId(), normalizedPeriod)) {
            throw new RuntimeException("Phòng này đã được tạo hóa đơn cho kỳ " + normalizedPeriod);
        }

        Contract contract = contractRepository.findByRoomId(request.getRoomId()).stream()
                .filter(c -> c.getStatus() == ContractStatus.SIGNED)
                .findFirst()
                .orElseThrow(() -> new RuntimeException("Phòng này hiện không có hợp đồng nào đang thuê hợp lệ!"));

        // Vẫn giữ kiểm tra bảo mật IDOR cho API thủ công
        if (!contract.getRoom().getArea().getLandlord().getId().equals(currentUserId)) {
            throw new RuntimeException("Bạn không có quyền tạo hóa đơn cho khu trọ khác!");
        }

        Invoice invoice = generateInvoiceCore(contract, normalizedPeriod);
        return convertToResponse(invoice);
    }


    @Transactional
    public void autoGenerateMonthlyInvoices(){
        LocalDate today = LocalDate.now();
        int currentDay = today.getDayOfMonth();

        List<Area> areas = areaRepository.findByInvoiceDay(currentDay);
        for (Area area : areas) {
            List<Contract> activeContracts = contractRepository.findByRoomAreaIdAndStatus(area.getId(),ContractStatus.SIGNED);
            for (Contract contract : activeContracts) {
                try{
                    LocalDate normalizedPeriod = today.withDayOfMonth(1);
                    if(invoiceRepository.existsByRoomIdAndInvoicePeriod(contract.getRoom().getId(), normalizedPeriod)){
                    continue;
                    }
                    generateInvoiceCore(contract, normalizedPeriod);
                }catch (Exception e){
                    System.err.println("Lỗi tạo hóa đơn tự động phòng " + contract.getRoom().getRoomNumber() + ": " + e.getMessage());
                }
            }
        }
    }
    private Invoice generateInvoiceCore(Contract contract, LocalDate normalizedPeriod) {
        Room room = contract.getRoom();
        Area area = room.getArea();

        LocalDate today = LocalDate.now();
        int daysToPay = area.getDueDate() != null ? area.getDueDate() : 5;

        Invoice invoice = Invoice.builder()
                .contract(contract)
                .room(room)
                .invoicePeriod(normalizedPeriod)
                .dueDate(today.plusDays(daysToPay))
                .roomPrice(room.getRentPrice())
                .status(InvoiceStatus.UNPAID)
                .build();

        invoice = invoiceRepository.save(invoice);
        BigDecimal totalAmount = room.getRentPrice();

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
        // 2. TỰ ĐỘNG SINH MÃ VIETQR NGAY LÚC NÀY
        User landlord = area.getLandlord();

        if (landlord.getBankId() != null && landlord.getAccountNo() != null && landlord.getAccountName() != null) {
            String content = String.format("P%s THANH TOAN T%d",
                    room.getRoomNumber(),
                    normalizedPeriod.getMonthValue());

            String qrUrl = String.format("https://img.vietqr.io/image/%s-%s-compact2.png?amount=%.0f&addInfo=%s&accountName=%s",
                    landlord.getBankId(),
                    landlord.getAccountNo(),
                    totalAmount,
                    content.replace(" ", "%20"),
                    landlord.getAccountName().replace(" ", "%20"));

            // Gắn link QR vào entity
            invoice.setVietqrUrl(qrUrl);
        }

        return invoiceRepository.save(invoice);
    }

    private InvoiceResponse convertToResponse(Invoice invoice) {
        return InvoiceResponse.builder()
                .id(invoice.getId())
                .roomNumber(invoice.getRoom().getRoomNumber())
                .invoicePeriod(invoice.getInvoicePeriod())
                .dueDate(invoice.getDueDate())
                .roomPrice(invoice.getRoomPrice())
                .totalAmount(invoice.getTotalAmount())
                .status(invoice.getStatus().name())
                .build();
    }


    @Transactional(readOnly = true)
    public InvoiceDetailResponse getInvoiceDetail(UUID invoiceId, UUID currentUserId) {
        Invoice invoice = invoiceRepository.findById(invoiceId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy hóa đơn yêu cầu!"));

        boolean isLandlord = invoice.getRoom().getArea().getLandlord().getId().equals(currentUserId);
        boolean isTenant = invoice.getContract().getTenant().getId().equals(currentUserId);

        if (!isLandlord && !isTenant) {
            throw new RuntimeException("Bạn không có quyền xem hóa đơn của phòng này!");
        }

        List<InvoiceDetail> details = invoiceDetailRepository.findByInvoiceId(invoiceId);

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

    @Transactional
    public PaymentQrResponse generateVietQR(UUID invoiceId, UUID currentUserId) {

        Invoice invoice = invoiceRepository.findById(invoiceId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy hóa đơn!"));

        boolean isLandlord = invoice.getRoom().getArea().getLandlord().getId().equals(currentUserId);
        boolean isTenant = invoice.getContract().getTenant().getId().equals(currentUserId);

        if (!isLandlord && !isTenant) {
            throw new RuntimeException("Bạn không có quyền lấy mã QR thanh toán của phòng này!");
        }

        User landlord = invoice.getRoom().getArea().getLandlord();

        if (landlord.getBankId() == null || landlord.getAccountNo() == null || landlord.getAccountName() == null) {
            throw new RuntimeException("Chủ trọ chưa cấu hình thông tin tài khoản ngân hàng để nhận thanh toán!");
        }
        String bankId = landlord.getBankId();
        String accountNo = landlord.getAccountNo();
        String accountName = landlord.getAccountName();
        BigDecimal amount = invoice.getTotalAmount();

        String content = String.format("P%s THANH TOAN T%d",
                invoice.getRoom().getRoomNumber(),
                invoice.getInvoicePeriod().getMonthValue());

        String qrUrl = String.format("https://img.vietqr.io/image/%s-%s-compact2.png?amount=%.0f&addInfo=%s&accountName=%s",
                bankId,
                accountNo,
                amount,
                content.replace(" ", "%20"),
                accountName.replace(" ", "%20"));

        invoice.setVietqrUrl(qrUrl);
        invoiceRepository.save(invoice);

        return PaymentQrResponse.builder()
                .bankId(bankId)
                .accountNo(accountNo)
                .accountName(accountName)
                .amount(amount)
                .content(content)
                .qrImageUrl(qrUrl)
                .build();
    }

    @Transactional
    public InvoiceResponse confirmPayment(UUID invoiceId, UUID currentUserId) {
        Invoice invoice = invoiceRepository.findById(invoiceId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy hóa đơn!"));

        if (!invoice.getRoom().getArea().getLandlord().getId().equals(currentUserId)) {
            throw new RuntimeException("Bạn không có quyền xác nhận thanh toán cho hóa đơn này!");
        }

        if (invoice.getStatus() == InvoiceStatus.PAID) {
            throw new RuntimeException("Hóa đơn này đã được xác nhận thanh toán từ trước!");
        }

        invoice.setStatus(InvoiceStatus.PAID);
        invoice.setPaidAt(java.time.LocalDateTime.now());

        invoice = invoiceRepository.save(invoice);

        return convertToResponse(invoice);
    }
    @Transactional
    public void autoUpdateOverdueInvoices(){
        
    }
}