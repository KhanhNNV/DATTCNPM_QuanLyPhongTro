package ut.edu.be_quanlytro.Config;

import ut.edu.be_quanlytro.Service.Auth.TokenBlacklistService;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtException;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;

@Component
@RequiredArgsConstructor
public class JwtDecoderConfig implements JwtDecoder {

    private final TokenBlacklistService tokenBlacklistService;
    private NimbusJwtDecoder jwtDecoder;

    @Value("${app.jwt.secretKey}")
    private String secretKey;

    @Override
    public Jwt decode(String token) throws JwtException {
        try {
            if (tokenBlacklistService.isBlacklisted(token)) {
                throw new JwtException("Token này đã đăng xuất và nằm trong Blacklist!");
            }

            if (jwtDecoder == null) {
                SecretKey secretKeySpec = new SecretKeySpec(secretKey.getBytes(), "HS512");
                jwtDecoder = NimbusJwtDecoder.withSecretKey(secretKeySpec)
                        .macAlgorithm(MacAlgorithm.HS256)
                        .build();
            }
            return jwtDecoder.decode(token);
        } catch (Exception e) {
            throw new JwtException(e.getMessage());
        }
    }
}