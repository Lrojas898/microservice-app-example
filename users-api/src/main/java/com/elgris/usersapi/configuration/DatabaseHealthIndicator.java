package com.elgris.usersapi.configuration;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.actuator.health.Health;
import org.springframework.boot.actuator.health.HealthIndicator;
import org.springframework.stereotype.Component;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

@Component
public class DatabaseHealthIndicator implements HealthIndicator {

    @Autowired
    private DataSource dataSource;

    @Override
    public Health health() {
        try (Connection connection = dataSource.getConnection()) {
            if (connection.isValid(5)) {
                // Test query to verify database is working
                try (PreparedStatement statement = connection.prepareStatement("SELECT 1")) {
                    try (ResultSet resultSet = statement.executeQuery()) {
                        if (resultSet.next() && resultSet.getInt(1) == 1) {
                            return Health.up()
                                    .withDetail("database", "PostgreSQL")
                                    .withDetail("connection", "Available")
                                    .withDetail("validation", "Successful")
                                    .build();
                        }
                    }
                }
            }
        } catch (Exception e) {
            return Health.down()
                    .withDetail("database", "PostgreSQL")
                    .withDetail("connection", "Failed")
                    .withDetail("error", e.getMessage())
                    .build();
        }

        return Health.down()
                .withDetail("database", "PostgreSQL")
                .withDetail("connection", "Invalid")
                .build();
    }
}