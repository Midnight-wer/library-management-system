package com.library.dto;

import lombok.Data;

import javax.validation.constraints.NotNull;

/**
 * 提交借阅申请请求
 */
@Data
public class BorrowDTO {

    @NotNull(message = "图书ID不能为空")
    private Long bookId;
}
