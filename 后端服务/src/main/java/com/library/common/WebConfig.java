package com.library.common;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * Web 配置:
 * 1. 跨域配置
 * 2. JWT 拦截器注册 (排除登录/注册等公开接口)
 * 3. 文件上传静态资源映射
 */
@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Autowired
    private JwtInterceptor jwtInterceptor;

    @Value("${file.upload-dir}")
    private String uploadDir;

    @Value("${file.access-path}")
    private String accessPath;

    /**
     * 跨域配置
     */
    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/**")
                .allowedOriginPatterns("*")
                .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH")
                .allowedHeaders("*")
                .allowCredentials(true)
                .maxAge(3600);
    }

    /**
     * 拦截器注册: 仅登录、注册接口放行, 其余所有接口需校验 token
     */
    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(jwtInterceptor)
                .addPathPatterns("/**")
                .excludePathPatterns(
                        "/user/login",
                        "/user/register",
                        // 静态资源放行
                        "/uploads/**"
                );
    }

    /**
     * 文件上传目录静态资源映射
     * 访问 /api/uploads/xxx.jpg 即可访问到上传的文件
     */
    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        // 将 uploadDir 转为绝对路径(相对路径在不同启动方式/工作目录下解析不一致)
        String location = new java.io.File(uploadDir).getAbsolutePath().replace("\\", "/");
        if (!location.endsWith("/")) {
            location = location + "/";
        }
        registry.addResourceHandler(accessPath)
                .addResourceLocations("file:" + location);
    }
}
