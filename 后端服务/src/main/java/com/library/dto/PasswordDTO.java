package com.library.dto;

import lombok.Data;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Size;

/**
 * 修改密码请求
 */
@Data
public class PasswordDTO {

    @NotBlank(message = "原密码不能为空")
    private String oldPassword;

    @NotBlank(message = "新密码不能为空")
    @Size(min = 6, max = 20, message = "新密码长度需在6~20之间")
    private String newPassword;
}
