package ut.edu.be_quanlytro.Service.Auth;

import ut.edu.be_quanlytro.Dto.Request.ChangePasswordRequest;
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
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public LoginResponse login(LoginRequest request) {
        // 1. Xác thực thông tin qua Spring Security bằng SĐT và Password
        Authentication auth = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.getPhone(), request.getPassword())
        );

        // 2. Ép kiểu Principal về Entity User
        User user = (User) auth.getPrincipal();

        String areaId = null;
        String roomId = null;

        // 3. Thực hiện kẹp ID trọ vào JWT
        if (user.getRole() == RoleType.TENANT) {
            // Nếu là Khách thuê, tìm hợp đồng đã ký (SIGNED) của họ
            Optional<Contract> activeContract = contractRepository.findByTenantIdAndStatus(user.getId(), ContractStatus.SIGNED);
            if (activeContract.isPresent()) {
                Contract contract = activeContract.get();
                roomId = contract.getRoom().getId().toString();
                areaId = contract.getRoom().getArea().getId().toString();
            }
        } else if (user.getRole() == RoleType.LANDLORD) {
            // Chủ trọ có thể có nhiều Khu trọ (Areas).
            areaId = "ROLE_LANDLORD_ALL_AREAS";
        }

        // 4. Tạo token mang theo đầy đủ  ID dữ liệu
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

        // 2. Build Object User: Đăng ký tự do trên app/web mặc định là CHỦ TRỌ
        User newLandlord = User.builder()
                .phone(request.getPhone())
                .password(passwordEncoder.encode(request.getPassword()))
                .role(RoleType.LANDLORD)
                .fullName(request.getFullName())
                .isFirstLogin(false) 
                .build();

        userRepository.save(newLandlord);
    }
    public void changePassword(ChangePasswordRequest request, String phone) {
        User user = userRepository.findByPhone(phone)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng!"));
        if (!passwordEncoder.matches(request.getOldPassword(), user.getPassword())) {
            throw new RuntimeException("Mật khẩu hiện tại không chính xác!");
        }
        user.setPassword(passwordEncoder.encode(request.getNewPassword()));
        user.setIsFirstLogin(false);
        userRepository.save(user);
    }
}