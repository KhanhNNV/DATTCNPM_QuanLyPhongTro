package ut.edu.be_quanlytro.Service.Auth;


import com.nimbusds.jose.*;
import com.nimbusds.jose.crypto.MACSigner;
import com.nimbusds.jose.crypto.MACVerifier;
import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.SignedJWT;
import ut.edu.be_quanlytro.Entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.text.ParseException;
import java.time.temporal.ChronoUnit;
import java.util.Date;

@Service
@RequiredArgsConstructor
public class JwtService {

    private final TokenBlacklistService tokenBlacklistService;

    @Value("${app.jwt.secretKey}")
    private String secretKey;

    public String generateAccessToken(User user, String areaId, String roomId) {
        JWSHeader jwsHeader = new JWSHeader(JWSAlgorithm.HS512);
        Date issueTime = new Date();
        Date expiredTime = Date.from(issueTime.toInstant().plus(30, ChronoUnit.MINUTES));

        // Thiết lập các thông tin nhét vào ví JWT
        JWTClaimsSet.Builder claimsBuilder = new JWTClaimsSet.Builder()
                .subject(user.getPhone())
                .issueTime(issueTime)
                .expirationTime(expiredTime)
                .claim("userId", user.getId().toString()) // Lưu ID người dùng
                .claim("role", user.getRole().name());   // Lưu Quyền (LANDLORD/TENANT)


        if (areaId != null) claimsBuilder.claim("areaId", areaId);
        if (roomId != null) claimsBuilder.claim("roomId", roomId);

        return signToken(jwsHeader, claimsBuilder.build());
    }

    public String generateRefreshToken(User user) {
        JWSHeader jwsHeader = new JWSHeader(JWSAlgorithm.HS512);
        Date issueTime = new Date();
        Date expiredTime = Date.from(issueTime.toInstant().plus(30, ChronoUnit.DAYS));

        JWTClaimsSet claimsSet = new JWTClaimsSet.Builder()
                .subject(user.getPhone())
                .issueTime(issueTime)
                .expirationTime(expiredTime)
                .claim("userId", user.getId().toString())
                .build();

        return signToken(jwsHeader, claimsSet);
    }

    private String signToken(JWSHeader header, JWTClaimsSet claimsSet) {
        Payload payload = new Payload(claimsSet.toJSONObject());
        JWSObject jwsObject = new JWSObject(header, payload);
        try {
            jwsObject.sign(new MACSigner(secretKey));
            return jwsObject.serialize();
        } catch (JOSEException e) {
            throw new RuntimeException("Error signing token", e);
        }
    }

    public boolean verifyToken(String token) throws ParseException, JOSEException {
        if (tokenBlacklistService.isBlacklisted(token)) {
            return false;
        }
        SignedJWT signedJWT = SignedJWT.parse(token);
        Date expirationTime = signedJWT.getJWTClaimsSet().getExpirationTime();
        if (expirationTime.before(new Date())) {
            return false;
        }
        MACVerifier verifier = new MACVerifier(secretKey.getBytes(StandardCharsets.UTF_8));
        return signedJWT.verify(verifier);
    }

    public String extractPhone(String token) throws ParseException {
        SignedJWT signedJWT = SignedJWT.parse(token);
        return signedJWT.getJWTClaimsSet().getSubject();
    }
}