package com.elgris.usersapi.configuration;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurerAdapter;

import javax.servlet.http.HttpServletRequest;
import java.time.Instant;
import java.util.HashMap;
import java.util.Map;

@Configuration
public class WebConfiguration {

    @Bean
    public WebMvcConfigurerAdapter corsConfigurer() {
        return new WebMvcConfigurerAdapter() {
            @Override
            public void addCorsMappings(CorsRegistry registry) {
                registry.addMapping("/**")
                        .allowedOrigins("*")
                        .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                        .allowedHeaders("*");
            }
        };
    }

    @ControllerAdvice
    public static class GlobalExceptionHandler {

        private static final Logger logger = LoggerFactory.getLogger(GlobalExceptionHandler.class);

        @ExceptionHandler(Exception.class)
        public ResponseEntity<Map<String, Object>> handleGenericException(Exception e, HttpServletRequest request) {
            logger.error("Unhandled exception in request to {}: {}", request.getRequestURI(), e.getMessage(), e);

            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("error", "Internal Server Error");
            errorResponse.put("message", e.getMessage());
            errorResponse.put("timestamp", Instant.now().toString());
            errorResponse.put("path", request.getRequestURI());
            errorResponse.put("status", HttpStatus.INTERNAL_SERVER_ERROR.value());

            return new ResponseEntity<>(errorResponse, HttpStatus.INTERNAL_SERVER_ERROR);
        }

        @ExceptionHandler(RuntimeException.class)
        public ResponseEntity<Map<String, Object>> handleRuntimeException(RuntimeException e,
                HttpServletRequest request) {
            logger.error("Runtime exception in request to {}: {}", request.getRequestURI(), e.getMessage(), e);

            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("error", "Runtime Error");
            errorResponse.put("message", e.getMessage());
            errorResponse.put("timestamp", Instant.now().toString());
            errorResponse.put("path", request.getRequestURI());
            errorResponse.put("status", HttpStatus.INTERNAL_SERVER_ERROR.value());

            return new ResponseEntity<>(errorResponse, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
}