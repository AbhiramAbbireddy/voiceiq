package com.voiceiq.backend.auth.jwt;

import com.voiceiq.backend.auth.security.AuthenticatedUser;
import com.voiceiq.backend.auth.domain.User;
import com.voiceiq.backend.common.exception.BadRequestException;
import com.voiceiq.backend.config.JwtProperties;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jws;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;

@Service
public class JwtService {

    private final JwtProperties jwtProperties;

    public JwtService(JwtProperties jwtProperties) {
        this.jwtProperties = jwtProperties;
    }

    public String generateToken(User user) {
        Map<String, Object> claims = new HashMap<>();
        claims.put("email", user.getEmail());
        claims.put("fullName", user.getFullName());
        claims.put("targetRole", user.getTargetRole());

        Instant now = Instant.now();
        Instant expiry = now.plusMillis(jwtProperties.expiration());

        return Jwts.builder()
                .claims(claims)
                .subject(user.getId().toString())
                .issuer(jwtProperties.issuer())
                .issuedAt(Date.from(now))
                .expiration(Date.from(expiry))
                .signWith(secretKey())
                .compact();
    }

    public AuthenticatedUser parseToken(String token) {
        try {
            Jws<Claims> claims = Jwts.parser()
                    .verifyWith(secretKey())
                    .build()
                    .parseSignedClaims(token);

            Claims body = claims.getPayload();

            return new AuthenticatedUser(
                    java.util.UUID.fromString(body.getSubject()),
                    body.get("email", String.class),
                    body.get("fullName", String.class),
                    body.get("targetRole", String.class)
            );
        } catch (Exception exception) {
            throw new BadRequestException("Invalid or expired token");
        }
    }

    private SecretKey secretKey() {
        return Keys.hmacShaKeyFor(jwtProperties.secret().getBytes(StandardCharsets.UTF_8));
    }
}
