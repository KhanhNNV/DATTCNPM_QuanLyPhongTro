package ut.edu.be_quanlytro.Service.Auth;

import org.springframework.transaction.annotation.Transactional;
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
import ut.edu.be_quanlytro.Exception.BadRequestException;
import ut.edu.be_quanlytro.Exception.ResourceNotFoundException;

import java.util.Optional;

@Service
@RequiredArgsConstructor
public class AuthenticationService {

    private final AuthenticationManager authenticationManager;
    private final JwtService jwtService;
    private final ContractRepository contractRepository;
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final TokenBlacklistService tokenBlacklistService;

    @Transactional
    public LoginResponse login(LoginRequest request) {
        Authentication auth = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.getPhone(), request.getPassword())
        );

        User user = (User) auth.getPrincipal();

        String areaId = null;
        String roomId = null;

        if (user.getRole() == RoleType.TENANT) {
            Optional<Contract> activeContract = contractRepository.findByTenantIdAndStatus(user.getId(), ContractStatus.SIGNED);
            if (activeContract.isPresent()) {
                Contract contract = activeContract.get();
                roomId = contract.getRoom().getId().toString();
                areaId = contract.getRoom().getArea().getId().toString();
            }
        } else if (user.getRole() == RoleType.LANDLORD) {
            areaId = null;
        }

        return LoginResponse.builder()
                .accessToken(jwtService.generateAccessToken(user, areaId, roomId))
                .refreshToken(jwtService.generateRefreshToken(user))
                .build();
    }

    public void register(RegisterRequest request) {
        if (userRepository.existsByPhone(request.getPhone())) {
            throw new BadRequestException("Số điện thoại này đã được sử dụng hệ thống!");
        }

        User newLandlord = User.builder()
                .phone(request.getPhone())
                .password(passwordEncoder.encode(request.getPassword()))
                .role(RoleType.LANDLORD)
                .fullName(request.getFullName())
                .idCardNumber(request.getIdCardNumber())
                .hometown(request.getHometown())
                .email(request.getEmail())
                .isFirstLogin(false)
                .build();

        userRepository.save(newLandlord);
    }
    public void changePassword(ChangePasswordRequest request, String phone) {
        User user = userRepository.findByPhone(phone)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy người dùng!"));
        if (!passwordEncoder.matches(request.getOldPassword(), user.getPassword())) {
            throw new BadRequestException("Mật khẩu hiện tại không chính xác!");
        }
        user.setPassword(passwordEncoder.encode(request.getNewPassword()));
        user.setIsFirstLogin(false);
        userRepository.save(user);
    }


    public LoginResponse refreshToken(String refreshToken) {
        try {
            if (refreshToken == null || !jwtService.verifyToken(refreshToken)) {
                throw new BadRequestException("Refresh Token không hợp lệ hoặc đã hết hạn");
            }

            String phone = jwtService.extractPhone(refreshToken);
            User user = userRepository.findByPhone(phone)
                    .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy người dùng hệ thống"));

            String newAccessToken = jwtService.generateAccessToken(user, null, null);

            return LoginResponse.builder()
                    .accessToken(newAccessToken)
                    .refreshToken(refreshToken)
                    .build();

        } catch (Exception e) {
            throw new BadRequestException("Lỗi xác thực Refresh Token");
        }
    }
    public void logout(String accessToken, String refreshToken) {

        if (accessToken != null && !accessToken.isEmpty()) {
            tokenBlacklistService.addToBlacklist(accessToken);
        }

        if (refreshToken != null && !refreshToken.isEmpty()) {
            tokenBlacklistService.addToBlacklist(refreshToken);
        }
    }
}