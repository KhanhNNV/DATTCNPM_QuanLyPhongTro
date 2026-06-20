package ut.edu.be_quanlytro.Entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;
import ut.edu.be_quanlytro.Entity.Enum.ContractStatus;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "contracts")
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Contract {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @JdbcTypeCode(SqlTypes.VARCHAR)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "room_id", nullable = false)
    private Room room;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "tenant_id", nullable = false)
    private User tenant;


    @OneToMany(mappedBy = "contract", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    private List<ContractMember> members = new ArrayList<>();

    @Column(name = "start_date")
    private LocalDate startDate;

    @Column(name = "end_date")
    private LocalDate endDate;

    @Column(name = "deposit_amount")
    private BigDecimal depositAmount;

    @Column(name = "tenant_signature", columnDefinition = "TEXT")
    private String tenantSignature;

    @Column(name = "landlord_signature", columnDefinition = "TEXT")
    private String landlordSignature;

    @Column(name = "contract_file_url")
    private String contractFileUrl;

    @Enumerated(EnumType.STRING)
    @Builder.Default
    private ContractStatus status = ContractStatus.DRAFT;
    // 1. Dùng để thống kê: Hợp đồng này được tạo ra từ Mẫu nào?
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "template_id")
    private ContractTemplate template;

    // 2. Chụp ảnh văn bản gốc (Lõi Pháp Lý):
    // Toàn bộ HTML sau khi điền tên, ngày tháng, chữ ký sẽ bị "đóng băng" ở đây.
    // Chủ trọ có sửa template gốc thì văn bản này vẫn bất di bất dịch.
    @Column(name = "contract_terms", columnDefinition = "LONGTEXT")
    private String contractTerms;

    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}