package com.library.controller;

import com.library.common.BusinessException;
import com.library.common.Result;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.time.LocalDate;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

/**
 * 文件上传接口
 * 支持头像、图书封面上传, 保存到服务器本地
 */
@Slf4j
@RestController
@RequestMapping("/file")
public class FileController {

    @Value("${file.upload-dir}")
    private String uploadDir;

    /**
     * 文件上传
     * 接口: POST /file/upload  【需登录】
     * 返回访问URL: /api/uploads/yyyy/MM/dd/xxx.jpg
     */
    @PostMapping("/upload")
    public Result<Map<String, String>> upload(@RequestParam("file") MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new BusinessException("上传文件不能为空");
        }

        // 原始文件名
        String originalFilename = file.getOriginalFilename();
        if (originalFilename == null) {
            throw new BusinessException("文件名不合法");
        }
        // 校验文件后缀(文件名无扩展名时 lastIndexOf 返回 -1, 需先拦截避免越界异常)
        int dotIndex = originalFilename.lastIndexOf(".");
        if (dotIndex < 0 || dotIndex == originalFilename.length() - 1) {
            throw new BusinessException("文件缺少扩展名,仅支持图片格式(jpg/jpeg/png/gif/bmp/webp)");
        }
        String suffix = originalFilename.substring(dotIndex).toLowerCase();
        if (!suffix.matches("\\.(jpg|jpeg|png|gif|bmp|webp)")) {
            throw new BusinessException("仅支持图片格式(jpg/jpeg/png/gif/bmp/webp)");
        }

        // 按日期分目录: yyyy/MM/dd
        String datePath = LocalDate.now().toString().replace("-", "/");

        // 上传目录(转为绝对路径: 相对路径会被 Tomcat 解析到临时 work 目录导致写入失败)
        File baseDir = new File(uploadDir).getAbsoluteFile();
        File dir = new File(baseDir, datePath);
        if (!dir.exists() && !dir.mkdirs()) {
            throw new BusinessException("创建上传目录失败");
        }

        // 新文件名
        String newFileName = UUID.randomUUID().toString().replace("-", "") + suffix;

        try {
            File destFile = new File(dir, newFileName);
            file.transferTo(destFile);
        } catch (IOException e) {
            log.error("文件上传失败", e);
            throw new BusinessException("文件上传失败");
        }

        // 返回可访问的URL (context-path 为 /api)
        String url = "/api/uploads/" + datePath + "/" + newFileName;
        Map<String, String> data = new HashMap<>(2);
        data.put("url", url);
        data.put("name", newFileName);
        log.info("文件上传成功: {}", url);
        return Result.success("上传成功", data);
    }
}
