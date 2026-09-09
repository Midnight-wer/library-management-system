package com.library.common;

import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.servlet.HandlerInterceptor;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.util.HashMap;
import java.util.Map;

/**
 * JWT 鉴权拦截器
 * 校验 token 有效性 + 角色权限
 * 公开接口(登录/注册) 在 WebConfig 中直接排除, 不进入本拦截器
 */
@Slf4j
@Component
public class JwtInterceptor implements HandlerInterceptor {

    @Autowired
    private JwtUtils jwtUtils;

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {
        // OPTIONS 预检请求直接放行
        if ("OPTIONS".equalsIgnoreCase(request.getMethod())) {
            return true;
        }

        String token = request.getHeader("Authorization");
        if (StringUtils.hasText(token) && token.startsWith("Bearer ")) {
            token = token.substring(7);
        }

        // token 为空
        if (!StringUtils.hasText(token)) {
            return writeError(response, 401, "未登录或token失效,请重新登录");
        }

        // 校验 token
        if (!jwtUtils.validateToken(token)) {
            return writeError(response, 401, "token已过期,请重新登录");
        }

        Long userId = jwtUtils.getUserId(token);
        String username = jwtUtils.getUsername(token);
        String role = jwtUtils.getRole(token);

        if (userId == null || !StringUtils.hasText(role)) {
            return writeError(response, 401, "token无效,请重新登录");
        }

        // 存入上下文
        BaseContext.setCurrentUser(new CurrentUser(userId, username, role));

        // 角色权限校验: 管理员接口要求 role=admin
        if (isAdminOnlyApi(request) && !"admin".equals(role)) {
            return writeError(response, 403, "权限不足,无法访问该接口");
        }

        return true;
    }

    @Override
    public void afterCompletion(HttpServletRequest request, HttpServletResponse response, Object handler, Exception ex) {
        // 清除线程上下文
        BaseContext.clear();
    }

    /**
     * 判断当前请求是否为管理员专属接口
     * (公开接口已在 WebConfig 排除, 这里只需区分登录后接口与管理员接口)
     */
    private boolean isAdminOnlyApi(HttpServletRequest request) {
        String method = request.getMethod();
        String uri = request.getRequestURI();
        // 去掉 context-path 前缀 /api
        if (uri.startsWith("/api")) {
            uri = uri.substring(4);
        }

        // 用户管理 admin: GET /user/list, PUT/DELETE /user/{id}
        if ("GET".equals(method) && uri.matches("^/user/list$")) {
            return true;
        }
        if (("PUT".equals(method) || "DELETE".equals(method)) && uri.matches("^/user/\\d+$")) {
            return true;
        }
        // 图书增删改 admin: POST /book, PUT/DELETE /book/{id}
        if ("POST".equals(method) && uri.matches("^/book$")) {
            return true;
        }
        if (("PUT".equals(method) || "DELETE".equals(method)) && uri.matches("^/book/\\d+$")) {
            return true;
        }
        // 分类增删改 admin: POST /category, PUT/DELETE /category/{id}
        if ("POST".equals(method) && uri.matches("^/category$")) {
            return true;
        }
        if (("PUT".equals(method) || "DELETE".equals(method)) && uri.matches("^/category/\\d+$")) {
            return true;
        }
        // 借阅管理 admin: GET /borrow/list, PUT /borrow/{id}/audit, PUT /borrow/{id}/return, GET /borrow/export
        if ("GET".equals(method) && uri.matches("^/borrow/list$")) {
            return true;
        }
        if ("GET".equals(method) && uri.matches("^/borrow/export$")) {
            return true;
        }
        if ("PUT".equals(method) && (uri.matches("^/borrow/\\d+/audit$") || uri.matches("^/borrow/\\d+/return$"))) {
            return true;
        }
        // 统计 admin
        if (uri.matches("^/statistics.*$")) {
            return true;
        }
        return false;
    }

    /**
     * 输出错误响应
     */
    private boolean writeError(HttpServletResponse response, int code, String message) throws Exception {
        response.setStatus(200);
        response.setContentType("application/json;charset=UTF-8");
        Map<String, Object> result = new HashMap<>(3);
        result.put("code", code);
        result.put("message", message);
        result.put("data", null);
        response.getWriter().write(objectMapper.writeValueAsString(result));
        return false;
    }
}
