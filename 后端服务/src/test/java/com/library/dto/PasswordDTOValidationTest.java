package com.library.dto;

import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

import javax.validation.ConstraintViolation;
import javax.validation.Validation;
import javax.validation.Validator;
import javax.validation.ValidatorFactory;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.*;

/**
 * BUG-07 回归测试: 修改密码的新密码必须有 6~20 位长度校验, 与注册规则一致
 */
class PasswordDTOValidationTest {

    private static ValidatorFactory factory;
    private static Validator validator;

    @BeforeAll
    static void init() {
        factory = Validation.buildDefaultValidatorFactory();
        validator = factory.getValidator();
    }

    @AfterAll
    static void close() {
        factory.close();
    }

    private PasswordDTO dto(String oldPwd, String newPwd) {
        PasswordDTO d = new PasswordDTO();
        d.setOldPassword(oldPwd);
        d.setNewPassword(newPwd);
        return d;
    }

    @Test
    void 新密码1位时校验不通过() {
        Set<ConstraintViolation<PasswordDTO>> violations = validator.validate(dto("123456", "1"));
        assertTrue(violations.stream().anyMatch(v -> v.getMessage().contains("6~20")),
                "1 位新密码应触发长度校验, 实际违规: " + violations);
    }

    @Test
    void 新密码超过20位时校验不通过() {
        Set<ConstraintViolation<PasswordDTO>> violations =
                validator.validate(dto("123456", "abcdefghijklmnopqrstuvwxyz123"));
        assertTrue(violations.stream().anyMatch(v -> v.getMessage().contains("6~20")),
                "超长新密码应触发长度校验, 实际违规: " + violations);
    }

    @Test
    void 新密码为空时校验不通过() {
        Set<ConstraintViolation<PasswordDTO>> violations = validator.validate(dto("123456", ""));
        assertFalse(violations.isEmpty(), "空新密码应校验失败");
    }

    @Test
    void 合法长度新密码校验通过() {
        Set<ConstraintViolation<PasswordDTO>> violations = validator.validate(dto("123456", "abc123456"));
        assertTrue(violations.isEmpty(), "9 位新密码应通过校验, 实际违规: " + violations);
    }
}
