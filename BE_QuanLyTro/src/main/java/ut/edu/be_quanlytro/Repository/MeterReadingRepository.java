package ut.edu.be_quanlytro.Repository;


import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import ut.edu.be_quanlytro.Entity.MeterReading;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface MeterReadingRepository extends JpaRepository<MeterReading, UUID> {
   boolean existsByRoomIdAndServiceIdAndReadingMonth(UUID roomId, UUID serviceId, LocalDate readingMonth);
   Optional<MeterReading> findTopByRoomIdAndServiceIdAndReadingMonthBeforeOrderByReadingMonthDesc(
           UUID roomId, UUID serviceId, LocalDate readingMonth);
    Optional<MeterReading> findFirstByRoomIdAndServiceIdAndIsInvoicedFalse(UUID roomId, UUID serviceId);

    List<MeterReading> findByRoomIdAndReadingMonth(UUID roomId, LocalDate readingMonth);

    Optional<MeterReading> findFirstByRoomIdAndServiceIdOrderByCreatedAtDesc(UUID roomId, UUID serviceId);
}
