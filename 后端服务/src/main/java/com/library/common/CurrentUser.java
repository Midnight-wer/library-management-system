package com.library.common;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 当前登录用户信息
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class CurrentUser {

    private Long userId;
    private String username;
    private String role;
}
