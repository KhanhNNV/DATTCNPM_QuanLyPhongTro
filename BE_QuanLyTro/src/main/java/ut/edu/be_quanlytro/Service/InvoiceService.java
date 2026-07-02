package ut.edu.be_quanlytro.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import ut.edu.be_quanlytro.Dto.Request.InvoiceCreateRequest;
import ut.edu.be_quanlytro.Dto.Response.InvoiceDetailResponse;
import ut.edu.be_quanlytro.Dto.Response.InvoiceItemResponse;
import ut.edu.be_quanlytro.Dto.Response.InvoiceResponse;
import ut.edu.be_quanlytro.Dto.Response.PaymentQrResponse;
import ut.edu.be_quanlytro.Entity.*;
import ut.edu.be_quanlytro.Entity.Enum.ContractStatus;
import ut.edu.be_quanlytro.Entity.Enum.InvoiceStatus;
import ut.edu.be_quanlytro.Entity.Enum.NotificationType;
import ut.edu.be_quanlytro.Repository.*;
import org.springframework.security.access.AccessDeniedException;
import ut.edu.be_quanlytro.Exception.BadRequestException;
import ut.edu.be_quanlytro.Exception.ResourceNotFoundException;

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
    private final NotificationService notificationService;
    private final CloudinaryService cloudinaryService;

    /**
     * LÚC 1: CHỦ TRỌ BẤM TẠO BẰNG TAY (API MANUAL)
     */
    @Transactional
    public InvoiceResponse createInvoice(InvoiceCreateRequest request, UUID currentUserId) {
        LocalDate normalizedPeriod = request.getInvoicePeriod().withDayOfMonth(1);

        if (invoiceRepository.existsByRoomIdAndInvoicePeriod(request.getRoomId(), normalizedPeriod)) {
            throw new BadRequestException("Phòng này đã được tạo hóa đơn cho kỳ " + normalizedPeriod);
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
                            .orElseThrow(() -> new BadRequestException("Chưa chốt số " + service.getName() + " cho phòng này!"));
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
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy hóa đơn yêu cầu!"));

        boolean isLandlord = invoice.getRoom().getArea().getLandlord().getId().equals(currentUserId);
        boolean isTenant = invoice.getContract().getTenant().getId().equals(currentUserId);

        if (!isLandlord && !isTenant) {
            throw new AccessDeniedException("Bạn không có quyền xem hóa đơn của phòng này!");
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
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy hóa đơn!"));

        boolean isLandlord = invoice.getRoom().getArea().getLandlord().getId().equals(currentUserId);
        boolean isTenant = invoice.getContract().getTenant().getId().equals(currentUserId);

        if (!isLandlord && !isTenant) {
            throw new AccessDeniedException("Bạn không có quyền lấy mã QR thanh toán của phòng này!");
        }

        User landlord = invoice.getRoom().getArea().getLandlord();

        if (landlord.getBankId() == null || landlord.getAccountNo() == null || landlord.getAccountName() == null) {
            throw new BadRequestException("Chủ trọ chưa cấu hình thông tin tài khoản ngân hàng để nhận thanh toán!");
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
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy hóa đơn!"));

        if (!invoice.getRoom().getArea().getLandlord().getId().equals(currentUserId)) {
            throw new AccessDeniedException("Bạn không có quyền xác nhận thanh toán cho hóa đơn này!");
        }

        if (invoice.getStatus() == InvoiceStatus.PAID) {
            throw new BadRequestException("Hóa đơn này đã được xác nhận thanh toán từ trước!");
        }

        invoice.setStatus(InvoiceStatus.PAID);
        invoice.setPaidAt(java.time.LocalDateTime.now());

        invoice = invoiceRepository.save(invoice);
        String title = "Thanh toán thành công!";
        String content = "Chủ trọ đã xác nhận minh chứng thanh toán cho hóa đơn phòng " + invoice.getRoom().getRoomNumber() + ". Cảm ơn bạn!";
        notificationService.createNotification(
                invoice.getContract().getTenant(),
                title,
                content,
                NotificationType.PAYMENT_APPROVED
        );

        return convertToResponse(invoice);
    }

    /**
     * UC27: TỰ ĐỘNG CẬP NHẬT TRẠNG THÁI QUÁ HẠN (OVERDUE)
     */
    @Transactional
    public void autoUpdateOverdueInvoices() {
        LocalDate today = LocalDate.now();
        List<Invoice> overdueInvoices = invoiceRepository.findByStatusAndDueDateLessThan(InvoiceStatus.UNPAID, today);

        for (Invoice invoice : overdueInvoices) {
            invoice.setStatus(InvoiceStatus.OVERDUE);
            invoiceRepository.save(invoice);

            // 🚀 LƯU THÔNG BÁO VÀO DATABASE
            String title = "Hóa đơn quá hạn thanh toán!";
            String content = "Hóa đơn phòng " + invoice.getRoom().getRoomNumber() + " đã quá hạn. Vui lòng thanh toán sớm để tránh gián đoạn dịch vụ nhé!";
            notificationService.createNotification(
                    invoice.getContract().getTenant(), // Gửi cho ai? -> Gửi cho Khách thuê
                    title,
                    content,
                    NotificationType.INVOICE_OVERDUE
            );

            System.out.println("[UC27] Đã chuyển hóa đơn phòng " + invoice.getRoom().getRoomNumber() + " sang QUÁ HẠN và lưu thông báo!");
        }
    }

    /**
     * UC26: TỰ ĐỘNG NHẮC NỢ HÀNG THÁNG
     */
    @Transactional
    public void autoRemindMonthlyDebts() {
        LocalDate today = LocalDate.now();
        List<Invoice> remindInvoices = invoiceRepository.findByStatusAndDueDate(InvoiceStatus.UNPAID, today.plusDays(1));

        for (Invoice invoice : remindInvoices) {
            // 🚀 LƯU THÔNG BÁO VÀO DATABASE
            String title = "Nhắc nhở hạn chót thanh toán";
            String content = "Hôm nay là hạn chót đóng tiền phòng " + invoice.getRoom().getRoomNumber()
                    + " (Tổng: " + invoice.getTotalAmount() + "đ). Bạn nhớ thanh toán nhé!";
            notificationService.createNotification(
                    invoice.getContract().getTenant(), // Gửi cho Khách thuê
                    title,
                    content,
                    NotificationType.INVOICE_REMINDER
            );

            System.out.println(" Đã lưu thông báo nhắc nợ cho phòng " + invoice.getRoom().getRoomNumber());
        }
    }

    /**
     * UC23: GỬI MINH CHỨNG THANH TOÁN (DÙNG CLOUDINARY)
     */
    @Transactional
    public void uploadPaymentProof(UUID invoiceId, MultipartFile file) {

        Invoice invoice = invoiceRepository.findById(invoiceId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy hóa đơn"));

        if (invoice.getStatus() != InvoiceStatus.UNPAID && invoice.getStatus() != InvoiceStatus.OVERDUE) {
            throw new BadRequestException("Chỉ có thể gửi minh chứng cho hóa đơn chưa thanh toán hoặc quá hạn!");
        }


        String fileUrl = cloudinaryService.uploadFile(file, "payment_proofs");

        // 3. Cập nhật Database
        invoice.setPaymentProofUrl(fileUrl);
        invoice.setStatus(InvoiceStatus.PENDING); // Chuyển sang chờ duyệt
        invoiceRepository.save(invoice);

        // 4. Bắn thông báo cho Chủ trọ biết
        String title = "Có minh chứng thanh toán mới!";
        String content = "Khách thuê phòng " + invoice.getRoom().getRoomNumber() + " vừa tải lên minh chứng thanh toán. Vui lòng kiểm tra và xét duyệt!";
        notificationService.createNotification(
                invoice.getRoom().getArea().getLandlord(), // Gửi cho Chủ trọ
                title,
                content,
                NotificationType.PAYMENT_APPROVED
        );
    }

    /**
     * UC24: TỪ CHỐI MINH CHỨNG THANH TOÁN (CHỦ TRỌ)
     */
    @Transactional
    public InvoiceResponse rejectPaymentProof(UUID invoiceId, String reason, UUID currentUserId) {
        Invoice invoice = invoiceRepository.findById(invoiceId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy hóa đơn!"));

        if (!invoice.getRoom().getArea().getLandlord().getId().equals(currentUserId)) {
            throw new AccessDeniedException("Bạn không có quyền từ chối thanh toán cho hóa đơn này!");
        }

        if (invoice.getStatus() != InvoiceStatus.PENDING) {
            throw new BadRequestException("Hóa đơn này không ở trạng thái chờ duyệt minh chứng!");
        }

        LocalDate today = LocalDate.now();
        if (today.isAfter(invoice.getDueDate())) {
            invoice.setStatus(InvoiceStatus.OVERDUE); // Quá hạn rồi thì phạt OVERDUE
        } else {
            invoice.setStatus(InvoiceStatus.UNPAID);  // Chưa quá hạn thì trả về UNPAID cho đóng lại
        }

        // 5. Xóa link ảnh minh chứng cũ để khách thuê biết đường upload ảnh mới lên thay thế
        invoice.setPaymentProofUrl(null);
        invoice = invoiceRepository.save(invoice);

        String title = "Minh chứng thanh toán bị từ chối!";
        String content = String.format("Chủ trọ không duyệt minh chứng phòng %s. Lý do: %s. Vui lòng kiểm tra và gửi lại nhé!",
                invoice.getRoom().getRoomNumber(), reason);

        notificationService.createNotification(
                invoice.getContract().getTenant(),
                title,
                content,
                NotificationType.PAYMENT_REJECTED
        );

        return convertToResponse(invoice);
    }
}