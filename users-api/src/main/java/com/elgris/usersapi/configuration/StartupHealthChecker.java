package com.elgris.usersapi.configuration;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

@Component
public class StartupHealthChecker {

    private static final Logger logger = LoggerFactory.getLogger(StartupHealthChecker.class);

    @Autowired
    private DataSource dataSource;

    private boolean isReady = false;

    @EventListener(ApplicationReadyEvent.class)
    public void onApplicationReady() {
        logger.info("Application startup completed, performing readiness checks...");

        // Check database connectivity
        if (checkDatabaseConnectivity()) {
            logger.info("Database connectivity check passed");
        } else {
            logger.error("Database connectivity check failed");
            // Don't fail the startup, but log the issue
        }

        isReady = true;
        logger.info("Application is ready to serve requests");
    }

    private boolean checkDatabaseConnectivity() {
        int maxRetries = 10;
        int retryCount = 0;
        long retryDelay = 2000; // 2 seconds

        while (retryCount < maxRetries) {
            try (Connection connection = dataSource.getConnection()) {
                if (connection.isValid(5)) {
                    try (PreparedStatement statement = connection.prepareStatement("SELECT 1")) {
                        try (ResultSet resultSet = statement.executeQuery()) {
                            if (resultSet.next() && resultSet.getInt(1) == 1) {
                                logger.info("Database connection successful on attempt {}", retryCount + 1);
                                return true;
                            }
                        }
                    }
                }
            } catch (Exception e) {
                retryCount++;
                logger.warn("Database connection attempt {} failed: {}. Retrying in {} ms",
                        retryCount, e.getMessage(), retryDelay);

                if (retryCount < maxRetries) {
                    try {
                        Thread.sleep(retryDelay);
                        retryDelay = Math.min(retryDelay * 2, 30000); // Exponential backoff, max 30 seconds
                    } catch (InterruptedException ie) {
                        Thread.currentThread().interrupt();
                        logger.error("Database connection retry interrupted");
                        return false;
                    }
                }
            }
        }

        logger.error("Failed to establish database connection after {} attempts", maxRetries);
        return false;
    }

    public boolean isReady() {
        return isReady;
    }
}