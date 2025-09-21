package com.elgris.usersapi.api;

import com.elgris.usersapi.configuration.StartupHealthChecker;
import com.elgris.usersapi.models.User;
import com.elgris.usersapi.repository.UserRepository;
import io.jsonwebtoken.Claims;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpServletRequest;
import javax.sql.DataSource;
import java.sql.Connection;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;

@RestController()
@RequestMapping("/users")
public class UsersController {

    private static final Logger logger = LoggerFactory.getLogger(UsersController.class);

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private StartupHealthChecker startupHealthChecker;

    @Autowired
    private DataSource dataSource;

    @RequestMapping(value = "/health", method = RequestMethod.GET)
    public ResponseEntity<Map<String, Object>> health() {
        Map<String, Object> healthStatus = new HashMap<>();
        healthStatus.put("status", "UP");
        healthStatus.put("service", "users-api");
        healthStatus.put("timestamp", System.currentTimeMillis());

        try {
            // Check database connectivity
            try (Connection connection = dataSource.getConnection()) {
                if (connection.isValid(2)) {
                    healthStatus.put("database", "UP");
                } else {
                    healthStatus.put("database", "DOWN");
                    healthStatus.put("status", "DOWN");
                }
            }
        } catch (Exception e) {
            logger.error("Health check database connection failed", e);
            healthStatus.put("database", "DOWN");
            healthStatus.put("status", "DOWN");
            healthStatus.put("error", e.getMessage());
        }

        HttpStatus status = "UP".equals(healthStatus.get("status")) ? HttpStatus.OK : HttpStatus.SERVICE_UNAVAILABLE;
        return new ResponseEntity<>(healthStatus, status);
    }

    @RequestMapping(value = "/ready", method = RequestMethod.GET)
    public ResponseEntity<Map<String, Object>> readiness() {
        Map<String, Object> readinessStatus = new HashMap<>();

        boolean isReady = startupHealthChecker.isReady();
        readinessStatus.put("ready", isReady);
        readinessStatus.put("service", "users-api");
        readinessStatus.put("timestamp", System.currentTimeMillis());

        if (!isReady) {
            readinessStatus.put("message", "Service is starting up");
            return new ResponseEntity<>(readinessStatus, HttpStatus.SERVICE_UNAVAILABLE);
        }

        return new ResponseEntity<>(readinessStatus, HttpStatus.OK);
    }

    @RequestMapping(value = "/", method = RequestMethod.GET)
    public List<User> getUsers() {
        logger.debug("Fetching all users");
        List<User> response = new LinkedList<>();

        try {
            userRepository.findAll().forEach(response::add);
            logger.debug("Successfully fetched {} users", response.size());
        } catch (Exception e) {
            logger.error("Error fetching users", e);
            throw e;
        }

        return response;
    }

    @RequestMapping(value = "/{username}", method = RequestMethod.GET)
    public User getUser(HttpServletRequest request, @PathVariable("username") String username) {
        logger.debug("Fetching user: {}", username);

        Object requestAttribute = request.getAttribute("claims");
        if ((requestAttribute == null) || !(requestAttribute instanceof Claims)) {
            logger.warn("Missing or invalid JWT claims for user: {}", username);
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Missing or invalid authentication token");
        }

        Claims claims = (Claims) requestAttribute;

        if (!username.equalsIgnoreCase((String) claims.get("username"))) {
            logger.warn("Access denied for user: {} requesting: {}", claims.get("username"), username);
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "No access for requested entity");
        }

        try {
            User user = userRepository.findOneByUsername(username);
            if (user != null) {
                logger.debug("Successfully fetched user: {}", username);
            } else {
                logger.warn("User not found: {}", username);
            }
            return user;
        } catch (Exception e) {
            logger.error("Error fetching user: {}", username, e);
            throw e;
        }
    }

}
