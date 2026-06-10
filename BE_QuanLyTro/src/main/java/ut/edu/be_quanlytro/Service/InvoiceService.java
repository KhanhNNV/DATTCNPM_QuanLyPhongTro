package ut.edu.be_quanlytro.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ut.edu.be_quanlytro.Dto.Request.InvoiceCreateRequest;
import ut.edu.be_quanlytro.Dto.Response.InvoiceResponse;
import ut.edu.be_quanlytro.Entity.*;
import ut.edu.be_quanlytro.Entity.Enum.ContractStatus;
import ut.edu.be_quanlytro.Entity.Enum.InvoiceStatus;
import ut.edu.be_quanlytro.Repository.*;

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
}


