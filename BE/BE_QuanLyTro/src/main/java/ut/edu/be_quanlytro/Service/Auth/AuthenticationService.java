package ut.edu.be_quanlytro.Service.Auth;

import ut.edu.be_quanlytro.Dto.Request.LoginRequest;
import ut.edu.be_quanlytro.Dto.Request.RegisterRequest;
import ut.edu.be_quanlytro.Dto.Response.LoginResponse;
import ut.edu.be_quanlytro.Entity.User;
import ut.edu.be_quanlytro.Entity.Contract;
import ut.edu.be_quanlytro.Entity.Enum.RoleType;
import ut.edu.be_quanlytro.Entity.Enum.ContractStatus;
import ut.edu.be_quanlytro.Repository.UserRepository;
import ut.edu.be_quanlytro.Repository.ContractRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder; // Thêm import này nếu chưa có
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
@RequiredArgsConstructor
public class AuthenticationService {

    private final AuthenticationManager authenticationManager;
    private final JwtService jwtService;
    private final ContractRepository contractRepository;

    // BỔ SUNG 2 DÒNG NÀY ĐỂ FIX LỖI CANNOT RESOLVE SYMBOL
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public LoginResponse login(LoginRequest request) {
        // 1. Xác thực thông tin qua Spring Security bằng SĐT và Password
        Authentication auth = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.getPhone(), request.getPassword())
        );

        // 2. Ép kiểu Principal về Entity User của mình (đã implements UserDetails)
        User user = (User) auth.getPrincipal();

        String areaId = null;
        String roomId = null;

        // 3. Thực hiện kẹp ID trọ vào JWT theo yêu cầu của Nhóm trưởng
        if (user.getRole() == RoleType.TENANT) {
            // Nếu là Khách thuê, tìm hợp đồng đã ký (SIGNED) của họ
            Optional<Contract> activeContract = contractRepository.findByTenantIdAndStatus(user.getId(), ContractStatus.SIGNED);
            if (activeContract.isPresent()) {
                Contract contract = activeContract.get();
                roomId = contract.getRoom().getId().toString();
                areaId = contract.getRoom().getArea().getId().toString();
            }
        } else if (user.getRole() == RoleType.LANDLORD) {
            // Lưu ý: Chủ trọ có thể có nhiều Khu trọ (Areas).
            areaId = "ROLE_LANDLORD_ALL_AREAS";
        }

        // 4. Tạo token mang theo đầy đủ "vũ khí" ID dữ liệu
        return LoginResponse.builder()
                .accessToken(jwtService.generateAccessToken(user, areaId, roomId))
                .refreshToken(jwtService.generateRefreshToken(user))
                .build();
    }

    public void register(RegisterRequest request) {
        // 1. Kiểm tra xem Số điện thoại này đã có ai đăng ký chưa
        if (userRepository.existsByPhone(request.getPhone())) {
            throw new RuntimeException("Số điện thoại này đã được sử dụng hệ thống!");
        }

        // 2. Build một Object User mới từ thông tin đăng ký
        User newTenant = User.builder()
                .phone(request.getPhone())
                // Bắt buộc phải mã hóa mật khẩu thô bằng BCrypt trước khi lưu xuống SQL Server
                .password(passwordEncoder.encode(request.getPassword()))
                .role(RoleType.TENANT) // ĐÃ SỬA: Đổi từ viết thường sang VIẾT HOA cho khớp với file Enum của bạn
                .fullName(request.getFullName())
                .isFirstLogin(true) // Bật cờ true để bắt buộc đổi pass lần đầu theo UC31
                .build();

        // 3. Lưu vào cơ sở dữ liệu
        userRepository.save(newTenant);
    }
}