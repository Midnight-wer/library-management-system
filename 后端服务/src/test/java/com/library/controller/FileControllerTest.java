package com.library.controller;

import com.library.common.BusinessException;
import com.library.common.Result;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.multipart.MultipartFile;

import java.io.ByteArrayInputStream;
import java.nio.file.Path;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

/**
 * BUG-03 回归测试: 文件上传必须安全处理扩展名(无扩展名文件不得抛 StringIndexOutOfBounds)
 * BUG-02 回归测试: 上传目录使用绝对路径, 合法图片可上传成功并返回访问URL
 */
class FileControllerTest {

    private FileController controller;

    @TempDir
    Path tempDir;

    @BeforeEach
    void setUp() {
        controller = new FileController();
        ReflectionTestUtils.setField(controller, "uploadDir", tempDir.toString());
    }

    private MultipartFile mockFile(String originalName, byte[] content) throws Exception {
        MultipartFile file = mock(MultipartFile.class);
        when(file.isEmpty()).thenReturn(content == null || content.length == 0);
        when(file.getOriginalFilename()).thenReturn(originalName);
        if (content != null) {
            when(file.getInputStream()).thenAnswer(inv -> new ByteArrayInputStream(content));
        }
        return file;
    }

    @Test
    void 空文件被拒绝() throws Exception {
        MultipartFile file = mockFile("a.png", new byte[0]);
        BusinessException ex = assertThrows(BusinessException.class, () -> controller.upload(file));
        assertTrue(ex.getMessage().contains("不能为空"));
    }

    @Test
    void 文件名为null时被拒绝() {
        MultipartFile file = mock(MultipartFile.class);
        when(file.isEmpty()).thenReturn(false);
        when(file.getOriginalFilename()).thenReturn(null);
        BusinessException ex = assertThrows(BusinessException.class, () -> controller.upload(file));
        assertTrue(ex.getMessage().contains("文件名不合法"));
    }

    @Test
    void 无扩展名文件返回业务提示而非系统异常() throws Exception {
        MultipartFile file = mockFile("test-noext", new byte[]{1, 2, 3});
        BusinessException ex = assertThrows(BusinessException.class, () -> controller.upload(file));
        assertTrue(ex.getMessage().contains("扩展名"), "应提示缺少扩展名, 实际: " + ex.getMessage());
    }

    @Test
    void 非图片格式被拒绝() throws Exception {
        MultipartFile file = mockFile("notes.txt", "hello".getBytes());
        BusinessException ex = assertThrows(BusinessException.class, () -> controller.upload(file));
        assertTrue(ex.getMessage().contains("图片"), "应提示仅支持图片, 实际: " + ex.getMessage());
    }

    @Test
    void 点结尾文件名被拒绝() throws Exception {
        MultipartFile file = mockFile("weird.", new byte[]{1});
        BusinessException ex = assertThrows(BusinessException.class, () -> controller.upload(file));
        assertTrue(ex.getMessage().contains("扩展名"));
    }

    @Test
    void 合法PNG上传成功并返回可访问URL() throws Exception {
        // 1x1 PNG
        byte[] png = java.util.Base64.getDecoder()
                .decode("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==");
        MultipartFile file = mockFile("cover.png", png);

        Result<Map<String, String>> result = controller.upload(file);
        assertEquals(200, result.getCode());
        assertNotNull(result.getData());
        assertTrue(result.getData().get("url").startsWith("/api/uploads/"),
                "应返回 /api/uploads/ 开头的访问URL, 实际: " + result.getData().get("url"));
        assertTrue(result.getData().get("name").endsWith(".png"));
    }
}
