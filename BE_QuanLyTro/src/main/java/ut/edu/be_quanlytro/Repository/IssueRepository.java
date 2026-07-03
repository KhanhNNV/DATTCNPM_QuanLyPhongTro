package ut.edu.be_quanlytro.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import ut.edu.be_quanlytro.Entity.Issue;
import java.util.UUID;

public interface IssueRepository extends JpaRepository<Issue, UUID> {
}