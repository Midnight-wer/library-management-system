package com.library.dto;

import lombok.Data;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Size;

/**
 * 注册请求
 */
@Data
public class RegisterDTO {

    @NotBlank(message = "账号不能为空")
    @Size(min = 3, max = 50, message = "账号长度需在3~50之间")
    private String username;

    @NotBlank(message = "密码不能为空")
    @Size(min = 6, max = 20, message = "密码长度需在6~20之间")
    private String password;

    @Size(max = 50, message = "昵称长度不能超过50")
    private String nickname;

    @Size(max = 20, message = "手机号长度不能超过20")
    private String phone;
}
