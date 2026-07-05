package com.ecommerce.notification.controller;
import java.util.Map;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HealthController {
    @GetMapping("/api/status")
    public Map<String, String> status() {
        return Map.of("service", "notification-service", "status", "listening for order events");
    }
}