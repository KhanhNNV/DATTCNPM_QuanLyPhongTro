package ut.edu.be_quanlytro.Entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.math.BigDecimal;
import java.util.UUID;

@Entity
@Table(name = "invoice_details")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class InvoiceDetail {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @JdbcTypeCode(SqlTypes.VARCHAR)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "invoice_id", nullable = false)
    private Invoice invoice;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "meter_reading_id")
    private MeterReading meterReading;

    @Column(name = "service_name")
    private String serviceName;

    @Column(name = "old_index")
    private Integer oldIndex;

    @Column(name = "new_index")
    private Integer newIndex;

    private Integer quantity;

    private BigDecimal price;

    @Column(name = "total_amount")
    private BigDecimal totalAmount;
}