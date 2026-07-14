package ut.edu.be_quanlytro.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import ut.edu.be_quanlytro.Entity.Deposit;
import ut.edu.be_quanlytro.Entity.Enum.DepositStatus;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface DepositRepository extends JpaRepository<Deposit, UUID> {

    @Query("SELECT d FROM Deposit d WHERE d.room.area.id = :areaId")
    List<Deposit> findByAreaId(@Param("areaId") UUID areaId);

    @Query("SELECT d FROM Deposit d WHERE d.room.area.id = :areaId AND d.status = :status ORDER BY d.depositDate DESC")
    List<Deposit> findByAreaIdAndStatus(@Param("areaId") UUID areaId, @Param("status") DepositStatus status);

    List<Deposit> findAllByStatusAndExpectedMoveInDateBefore(DepositStatus status, LocalDate date);

    Optional<Deposit> findByContractId(UUID contractId);
}