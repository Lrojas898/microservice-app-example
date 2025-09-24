package com.elgris.usersapi.security;

import com.elgris.usersapi.configuration.JwtProperties;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import io.jsonwebtoken.security.SignatureException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.GenericFilterBean;

import javax.servlet.FilterChain;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.Key;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Component
public class JwtAuthenticationFilter extends GenericFilterBean {

    private static final Logger logger = LoggerFactory.getLogger(JwtAuthenticationFilter.class);

    @Autowired
    private JwtProperties jwtProperties;

    public void doFilter(final ServletRequest req, final ServletResponse res, final FilterChain chain)
            throws IOException, ServletException {

        final HttpServletRequest request = (HttpServletRequest) req;
        final HttpServletResponse response = (HttpServletResponse) res;
        final String authHeader = request.getHeader("authorization");

        logger.debug("JWT Filter: Processing {} {}", request.getMethod(), request.getRequestURI());
        logger.debug("JWT Filter: Authorization header = {}", authHeader != null ? "Bearer [TOKEN]" : "null");

        if ("OPTIONS".equals(request.getMethod())) {
            response.setStatus(HttpServletResponse.SC_OK);

            chain.doFilter(req, res);
        } else {

            if (authHeader == null || !authHeader.startsWith("Bearer ")) {
                logger.debug("JWT Filter: Missing or invalid Authorization header");
                // Return 401 instead of throwing to avoid surfacing as 500 to clients
                response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Missing or invalid Authorization header");
                return;
            }

            final String token = authHeader.substring(7);
            logger.debug("JWT Filter: Extracted token length = {}", token.length());
            logger.debug("JWT Filter: JWT secret being used = {}", jwtProperties.getSecret());

            try {
                // Create a key from the secret that's compatible with JJWT 0.11.x
                Key key = Keys.hmacShaKeyFor(jwtProperties.getSecret().getBytes(StandardCharsets.UTF_8));

                logger.debug("JWT Filter: About to parse JWT token...");
                final Claims claims = Jwts.parserBuilder()
                        .setSigningKey(key)
                        .build()
                        .parseClaimsJws(token)
                        .getBody();
                logger.debug("JWT Filter: Token parsed successfully. Claims: {}", claims);
                request.setAttribute("claims", claims);

                // Create Spring Security authentication object
                String username = (String) claims.get("username");
                Authentication auth = new UsernamePasswordAuthenticationToken(username, null, null);
                SecurityContextHolder.getContext().setAuthentication(auth);
                logger.debug("JWT Filter: Authentication set for user: {}", username);
            } catch (final SignatureException e) {
                logger.debug("JWT Filter: SignatureException - Invalid token signature: {}", e.getMessage());
                // Invalid signature -> 401
                response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Invalid token");
                return;
            } catch (final Exception e) {
                logger.debug("JWT Filter: Exception parsing token: {} - {}", e.getClass().getSimpleName(), e.getMessage());
                // Any other token parsing/validation error -> 401
                response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Token processing error: " + e.getMessage());
                return;
            }

            chain.doFilter(req, res);
        }
    }
}