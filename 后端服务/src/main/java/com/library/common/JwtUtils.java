package com.library.common;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.util.Date;
import java.util.HashMap;
import java.util.Map;

/**
 * JWT 工具类: 生成、解析、校验 token
 */
@Slf4j
@Component
public class JwtUtils {

    @Value("${jwt.secret}")
    private String secret;

    @Value("${jwt.expiration}")
    private long expiration;

    /**
     * 生成 token
     *
     * @param userId   用户ID
     * @param username 账号
     * @param role     角色
     */
    public String generateToken(Long userId, String username, String role) {
        Map<String, Object> claims = new HashMap<>(4);
        claims.put("userId", userId);
        claims.put("username", username);
        claims.put("role", role);
        Date now = new Date();
        Date expiryDate = new Date(now.getTime() + expiration * 3600 * 1000L);
        return Jwts.builder()
                .setClaims(claims)
                .setIssuedAt(now)
                .setExpiration(expiryDate)
                .signWith(SignatureAlgorithm.HS256, secret)
                .compact();
    }

    /**
     * 解析 token, 获取 claims
     */
    public Claims parseToken(String token) {
        try {
            return Jwts.parser()
                    .setSigningKey(secret)
                    .parseClaimsJws(token)
                    .getBody();
        } catch (Exception e) {
            log.warn("token 解析失败: {}", e.getMessage());
            return null;
        }
    }

    /**
     * 校验 token 是否有效
     */
    public boolean validateToken(String token) {
        Claims claims = parseToken(token);
        if (claims == null) {
            return false;
        }
        Date expiration = claims.getExpiration();
        return expiration != null && !expiration.before(new Date());
    }

    /**
     * 从 token 中获取用户ID
     */
    public Long getUserId(String token) {
        Claims claims = parseToken(token);
        if (claims == null) {
            return null;
        }
        Object userId = claims.get("userId");
        if (userId instanceof Integer) {
            return ((Integer) userId).longValue();
        }
        return userId != null ? Long.valueOf(userId.toString()) : null;
    }

    /**
     * 从 token 中获取角色
     */
    public String getRole(String token) {
        Claims claims = parseToken(token);
        return claims != null ? (String) claims.get("role") : null;
    }

    /**
     * 从 token 中获取用户名
     */
    public String getUsername(String token) {
        Claims claims = parseToken(token);
        return claims != null ? (String) claims.get("username") : null;
    }
}
