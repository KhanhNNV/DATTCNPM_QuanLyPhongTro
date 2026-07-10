package ut.edu.be_quanlytro;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableJpaAuditing
@EnableScheduling//Kích hoạt tính năng chạy tác vụ tự động
@EnableAsync// Tính năng luồng chạy ngầm
public class BeQuanLyTroApplication {

    public static void main(String[] args) {
        SpringApplication.run(BeQuanLyTroApplication.class, args);
    }

}
