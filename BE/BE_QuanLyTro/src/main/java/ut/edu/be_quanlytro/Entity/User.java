package ut.edu.be_quanlytro.Entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;
import ut.edu.be_quanlytro.Entity.Enum.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "users")
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(unique = true, nullable = false)
    private String phone;

    @Column(nullable = false)
    private String password;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private RoleType role;

    @Column(name = "full_name")
    private String fullName;

    private LocalDate dob;

    private String hometown;

    @Column(name = "id_card_front")
    private String idCardFront;

    @Column(name = "id_card_back")
    private String idCardBack;

    @Column(name = "is_first_login", nullable = false)
    @Builder.Default
    private Boolean isFirstLogin = true;

    @Column(name = "landlord_signature", columnDefinition = "TEXT")
    private String landlordSignature;

    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}