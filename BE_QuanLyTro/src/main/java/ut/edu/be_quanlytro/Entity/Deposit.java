package ut.edu.be_quanlytro.Entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;
import ut.edu.be_quanlytro.Entity.Enum.DepositStatus;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "deposits")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Deposit {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @JdbcTypeCode(SqlTypes.VARCHAR)
    private UUID id;

    // Liên kết N-1 với Phòng (Phòng nào đang được cọc)
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "room_id", nullable = false)
    private Room room;

    @Column(unique = true, nullable = false)
    private String phone;

    @Column(name = "tenant_full_name")
    private String tenantFullName;

    // Liên kết 1-1 với Hợp đồng (Khi cọc chuyển thành hợp đồng)
    // Cột này ban đầu có thể null
    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "contract_id")
    private Contract contract;

    @Column(nullable = false)
    private BigDecimal depositAmount;

    @Column(nullable = false)
    private LocalDate depositDate;

    // Ngày dự kiến chuyển vào
    @Column(nullable = false)
    private LocalDate expectedMoveInDate;

    @Column(length = 500)
    private String note;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private DepositStatus status = DepositStatus.PENDING;
}