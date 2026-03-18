package com.voiceiq.backend.auth.service;

import com.voiceiq.backend.auth.domain.PlanType;
import com.voiceiq.backend.auth.domain.User;
import com.voiceiq.backend.auth.dto.AuthResponse;
import com.voiceiq.backend.auth.dto.LoginRequest;
import com.voiceiq.backend.auth.dto.RegisterRequest;
import com.voiceiq.backend.auth.jwt.JwtService;
import com.voiceiq.backend.auth.repository.UserRepository;
import com.voiceiq.backend.common.exception.BadRequestException;
import com.voiceiq.backend.common.exception.NotFoundException;
import com.voiceiq.backend.subscription.service.SubscriptionService;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final SubscriptionService subscriptionService;

    public AuthService(
            UserRepository userRepository,
            PasswordEncoder passwordEncoder,
            JwtService jwtService,
            SubscriptionService subscriptionService
    ) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
        this.subscriptionService = subscriptionService;
    }

    public AuthResponse register(RegisterRequest request) {
        String normalizedEmail = request.email().trim().toLowerCase();
        userRepository.findByEmailIgnoreCase(request.email()).ifPresent(user -> {
            throw new BadRequestException("Email is already registered");
        });

        User user = new User();
        user.setId(UUID.randomUUID());
        user.setFullName(request.fullName());
        user.setEmail(normalizedEmail);
        user.setPasswordHash(passwordEncoder.encode(request.password()));
        user.setTargetRole(request.targetRole());
        user.setPlan(PlanType.FREE);

        User savedUser = subscriptionService.applyDeveloperPlan(userRepository.save(user));
        subscriptionService.ensureSubscription(savedUser);
        subscriptionService.currentUsage(savedUser);
        return mapAuthResponse(savedUser);
    }

    public AuthResponse login(LoginRequest request) {
        User user = userRepository.findByEmailIgnoreCase(request.email())
                .orElseThrow(() -> new NotFoundException("User not found for email"));

        if (!passwordEncoder.matches(request.password(), user.getPasswordHash())) {
            throw new BadRequestException("Invalid email or password");
        }

        user = subscriptionService.applyDeveloperPlan(user);
        subscriptionService.ensureSubscription(user);
        subscriptionService.currentUsage(user);
        return mapAuthResponse(user);
    }

    private AuthResponse mapAuthResponse(User user) {
        return new AuthResponse(
                user.getId(),
                user.getFullName(),
                user.getEmail(),
                user.getTargetRole(),
                user.getPlan(),
                jwtService.generateToken(user)
        );
    }
}
