package com.library.dto;

import lombok.Data;

import javax.validation.constraints.Size;

/**
 * 修改个人资料请求
 */
@Data
public class UserUpdateDTO {

    @Size(max = 50, message = "昵称长度不能超过50")
    private String nickname;

    @Size(max = 20, message = "手机号长度不能超过20")
    private String phone;

    @Size(max = 255, message = "头像地址长度不能超过255")
    private String avatar;
}
