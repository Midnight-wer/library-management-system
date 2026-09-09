package com.library.common;

import org.junit.jupiter.api.Test;
import org.springframework.core.MethodParameter;
import org.springframework.validation.BeanPropertyBindingResult;
import org.springframework.validation.BindException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;

import java.lang.reflect.Method;

import static org.junit.jupiter.api.Assertions.*;

/**
 * BUG-11 回归测试:
 *  - 参数校验异常必须返回 400(而非 500)
 *  - 系统异常不得向前端泄露内部异常细节
 *  - 业务异常按其自带 code 返回(如 404)
 */
class GlobalExceptionHandlerTest {

    private final GlobalExceptionHandler handler = new GlobalExceptionHandler();

    /** 用于构造 MethodParameter 的占位方法 */
    static void placeholder(String dto) { }

    private MethodArgumentNotValidException buildValidException() throws NoSuchMethodException {
        Method method = GlobalExceptionHandlerTest.class.getDeclaredMethod("placeholder", String.class);
        MethodParameter parameter = new MethodParameter(method, 0);
        BeanPropertyBindingResult bindingResult = new BeanPropertyBindingResult(new Object(), "dto");
        bindingResult.addError(new FieldError("dto", "newPassword", "新密码长度需在6~20之间"));
        return new MethodArgumentNotValidException(parameter, bindingResult);
    }

    @Test
    void 请求体参数校验异常返回400() throws NoSuchMethodException {
        Result<Void> result = handler.handleValidException(buildValidException());
        assertEquals(400, result.getCode(), "参数校验错误应返回 400");
        assertTrue(result.getMessage().contains("6~20"), "应透传校验提示信息, 实际: " + result.getMessage());
    }

    @Test
    void 表单绑定校验异常返回400() {
        BeanPropertyBindingResult bindingResult = new BeanPropertyBindingResult(new Object(), "form");
        bindingResult.addError(new FieldError("form", "username", "账号不能为空"));
        Result<Void> result = handler.handleBindException(new BindException(bindingResult));
        assertEquals(400, result.getCode(), "参数绑定错误应返回 400");
        assertTrue(result.getMessage().contains("账号不能为空"));
    }

    @Test
    void 系统异常不泄露内部错误细节() {
        RuntimeException internal = new RuntimeException("StringIndexOutOfBoundsException: -1");
        Result<Void> result = handler.handleException(internal);
        assertEquals(500, result.getCode());
        assertEquals("系统繁忙,请稍后重试", result.getMessage(),
                "系统异常必须返回通用提示, 实际: " + result.getMessage());
        assertFalse(result.getMessage().contains("StringIndexOutOfBounds"),
                "不得把原始异常内容返回给前端");
    }

    @Test
    void 业务异常按自定义错误码返回() {
        Result<Void> result = handler.handleBusinessException(new BusinessException(404, "图书不存在或已下架"));
        assertEquals(404, result.getCode());
        assertTrue(result.getMessage().contains("不存在"));
    }
}
