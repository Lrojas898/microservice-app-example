package com.elgris.usersapi;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.HashMap;
import java.util.Map;

@SpringBootApplication
@EnableConfigurationProperties
@RestController
public class UsersApiApplication {

	private static final Logger logger = LoggerFactory.getLogger(UsersApiApplication.class);
	private final Instant startTime = Instant.now();

	@GetMapping("/")
	public ResponseEntity<Map<String, Object>> root() {
		Map<String, Object> response = new HashMap<>();
		response.put("service", "users-api");
		response.put("status", "running");
		response.put("version", "1.0.0");
		response.put("uptime", Instant.now().getEpochSecond() - startTime.getEpochSecond());
		response.put("timestamp", Instant.now().toString());

		logger.debug("Root endpoint accessed");
		return ResponseEntity.ok(response);
	}

	@GetMapping("/health")
	public ResponseEntity<Map<String, Object>> healthCheck() {
		Map<String, Object> health = new HashMap<>();
		health.put("status", "UP");
		health.put("service", "users-api");
		health.put("timestamp", Instant.now().toString());
		health.put("uptime", Instant.now().getEpochSecond() - startTime.getEpochSecond());

		logger.debug("Health check endpoint accessed");
		return ResponseEntity.ok(health);
	}

	@GetMapping("/ready")
	public ResponseEntity<Map<String, Object>> readiness() {
		Map<String, Object> readiness = new HashMap<>();
		readiness.put("ready", true);
		readiness.put("service", "users-api");
		readiness.put("timestamp", Instant.now().toString());

		logger.debug("Readiness check endpoint accessed");
		return ResponseEntity.ok(readiness);
	}

	public static void main(String[] args) {
		logger.info("Starting Users API Application...");
		SpringApplication.run(UsersApiApplication.class, args);
		logger.info("Users API Application started successfully");
	}
}
