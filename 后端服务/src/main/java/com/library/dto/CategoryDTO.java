package com.library.dto;

import lombok.Data;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Size;

/**
 * 新增/编辑分类请求
 */
@Data
public class CategoryDTO {

    @NotBlank(message = "分类名称不能为空")
    @Size(max = 50, message = "分类名称长度不能超过50")
    private String categoryName;
}
