package com.library.entity;

import com.baomidou.mybatisplus.annotation.FieldFill;
import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 图书分类实体
 */
@Data
@TableName("book_category")
public class BookCategory {

    @TableId(type = IdType.AUTO)
    private Long id;

    private String categoryName;

    /** 创建时间(应用层自动填充) */
    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createTime;
}
