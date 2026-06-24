package ut.edu.be_quanlytro.Entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "contract_templates")
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ContractTemplate {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @JdbcTypeCode(SqlTypes.VARCHAR)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "landlord_id")
    private User landlord;

    @Column(nullable = false)
    private String name;

    // ================== CÁC TRƯỜNG NỘI DUNG ĐƯỢC PHÉP TÙY CHỈNH ==================
    @Column(name = "rental_content", columnDefinition = "LONGTEXT")
    private String rentalContent;   // Nội dung thuê phòng (Giá cả, diện tích, mục đích...)

    @Column(name = "landlord_duty", columnDefinition = "LONGTEXT")
    private String landlordDuty;    // Trách nhiệm bên A (Chủ trọ)

    @Column(name = "tenant_duty", columnDefinition = "LONGTEXT")
    private String tenantDuty;      // Trách nhiệm bên B (Khách thuê)

    @Column(name = "execution_terms", columnDefinition = "LONGTEXT")
    private String executionTerms;  // Điều khoản thực hiện (Chấm dứt hợp đồng, giải quyết tranh chấp...)
    // =============================================================================

    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private Boolean isActive = true;

    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}