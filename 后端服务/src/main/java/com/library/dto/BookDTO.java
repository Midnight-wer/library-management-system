package com.library.dto;

import lombok.Data;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.Size;
import javax.validation.constraints.Min;

/**
 * 新增/编辑图书请求
 */
@Data
public class BookDTO {

    @NotBlank(message = "图书名称不能为空")
    @Size(max = 100, message = "图书名称长度不能超过100")
    private String bookName;

    @Size(max = 100, message = "作者长度不能超过100")
    private String author;

    @Size(max = 50, message = "ISBN长度不能超过50")
    private String isbn;

    private Long categoryId;

    @Size(max = 255, message = "封面地址长度不能超过255")
    private String cover;

    @NotNull(message = "总库存不能为空")
    @Min(value = 1, message = "总库存至少为1")
    private Integer totalNum;

    private String introduction;
}
