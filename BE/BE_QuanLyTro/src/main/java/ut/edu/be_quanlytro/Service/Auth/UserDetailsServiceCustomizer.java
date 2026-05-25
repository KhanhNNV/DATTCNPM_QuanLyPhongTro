package ut.edu.be_quanlytro.Service.Auth;

import ut.edu.be_quanlytro.Repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class UserDetailsServiceCustomizer implements UserDetailsService {

    private final UserRepository userRepository;

    @Override
    public UserDetails loadUserByUsername(String phone) throws UsernameNotFoundException {
        // Đăng nhập hệ thống bằng Số điện thoại
        return userRepository.findByPhone(phone)
                .orElseThrow(() -> new UsernameNotFoundException("Không tìm thấy người dùng với SĐT: " + phone));
    }
}