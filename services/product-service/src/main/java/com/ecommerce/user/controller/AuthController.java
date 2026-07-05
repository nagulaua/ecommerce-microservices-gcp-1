package com.ecommerce.user.controller;
import java.util.Map;

import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.ecommerce.user.dto.AuthRequest;
import com.ecommerce.user.service.UserService;

@RestController
@RequestMapping("/api/auth")
public class AuthController {
    private final UserService userService;

    public AuthController(UserService userService) {
        this.userService = userService;
    }

    @PostMapping("/register")
    public Map<String, String> register(@RequestBody AuthRequest req) {
        String token = userService.register(req.getEmail(), req.getPassword(), req.getFullName());
        return Map.of("token", token);
    }

    @PostMapping("/login")
    public Map<String, String> login(@RequestBody AuthRequest req) {
        String token = userService.login(req.getEmail(), req.getPassword());
        return Map.of("token", token);
    }
}