package com.library.entity;

import com.baomidou.mybatisplus.annotation.FieldFill;
import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 图书实体
 */
@Data
@TableName("book")
public class Book {

    @TableId(type = IdType.AUTO)
    private Long id;

    private String bookName;

    private String author;

    private String isbn;

    private Long categoryId;

    private String cover;

    private Integer totalNum;

    private Integer borrowNum;

    private String introduction;

    /** 创建时间(应用层自动填充) */
    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createTime;

    /** 更新时间(应用层自动填充) */
    @TableField(fill = FieldFill.INSERT_UPDATE)
    private LocalDateTime updateTime;
}
