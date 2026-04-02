package com.oraiopoli.supermarket.service;

import com.oraiopoli.supermarket.dto.request.LoginRequest;
import com.oraiopoli.supermarket.dto.request.RefreshTokenRequest;
import com.oraiopoli.supermarket.dto.request.RegisterRequest;
import com.oraiopoli.supermarket.dto.response.AuthResponse;
import com.oraiopoli.supermarket.dto.response.UserResponse;
import com.oraiopoli.supermarket.entity.Address;
import com.oraiopoli.supermarket.entity.Cart;
import com.oraiopoli.supermarket.entity.Role;
import com.oraiopoli.supermarket.entity.User;
import com.oraiopoli.supermarket.exception.BadRequestException;
import com.oraiopoli.supermarket.repository.AddressRepository;
import com.oraiopoli.supermarket.repository.CartRepository;
import com.oraiopoli.supermarket.repository.UserRepository;
import com.oraiopoli.supermarket.security.JwtService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class AuthService {

    private final UserRepository userRepository;
    private final AddressRepository addressRepository;
    private final CartRepository cartRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final AuthenticationManager authenticationManager;

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new BadRequestException("Email already registered");
        }

        User user = User.builder()
                .fullName(request.getFullName())
                .email(request.getEmail())
                .phone(request.getPhone())
                .password(passwordEncoder.encode(request.getPassword()))
                .role(Role.CUSTOMER)
                .enabled(true)
                .build();

        user = userRepository.save(user);

        // Create default address
        Address address = Address.builder()
                .label("Home")
                .addressLine(request.getAddress())
                .isDefault(true)
                .user(user)
                .build();
        addressRepository.save(address);

        // Create empty cart
        Cart cart = Cart.builder().user(user).build();
        cartRepository.save(cart);

        String accessToken = jwtService.generateAccessToken(user);
        String refreshToken = jwtService.generateRefreshToken(user);

        return AuthResponse.of(accessToken, refreshToken, UserResponse.fromEntity(user));
    }

    public AuthResponse login(LoginRequest request) {
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.getEmail(), request.getPassword())
        );

        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new BadRequestException("User not found"));

        String accessToken = jwtService.generateAccessToken(user);
        String refreshToken = jwtService.generateRefreshToken(user);

        return AuthResponse.of(accessToken, refreshToken, UserResponse.fromEntity(user));
    }

    public AuthResponse adminLogin(LoginRequest request) {
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.getEmail(), request.getPassword())
        );

        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new BadRequestException("User not found"));

        if (user.getRole() != Role.ADMIN && user.getRole() != Role.SUPER_ADMIN) {
            throw new BadRequestException("Access denied. Admin role required.");
        }

        String accessToken = jwtService.generateAccessToken(user);
        String refreshToken = jwtService.generateRefreshToken(user);

        return AuthResponse.of(accessToken, refreshToken, UserResponse.fromEntity(user));
    }

    public AuthResponse refreshToken(RefreshTokenRequest request) {
        String userEmail = jwtService.extractUsername(request.getRefreshToken());
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new BadRequestException("User not found"));

        if (!jwtService.isTokenValid(request.getRefreshToken(), user)) {
            throw new BadRequestException("Invalid refresh token");
        }

        String accessToken = jwtService.generateAccessToken(user);
        return AuthResponse.of(accessToken, request.getRefreshToken(), UserResponse.fromEntity(user));
    }
}

