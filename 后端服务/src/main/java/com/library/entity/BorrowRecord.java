package com.library.entity;

import com.baomidou.mybatisplus.annotation.FieldFill;
import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 借阅记录实体
 */
@Data
@TableName("borrow_record")
public class BorrowRecord {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long userId;

    private Long bookId;

    private LocalDateTime borrowTime;

    private LocalDateTime returnTime;

    /** 状态: 待审核 / 借阅中 / 已归还 / 驳回 */
    private String status;

    /** 驳回备注 */
    private String remark;

    /** 记录创建时间(应用层自动填充) */
    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createTime;

    /** 非数据库字段: 图书名称(联表查询) */
    private transient String bookName;

    /** 非数据库字段: 作者 */
    private transient String author;

    /** 非数据库字段: 图书封面 */
    private transient String cover;

    /** 非数据库字段: 借阅用户账号 */
    private transient String username;

    /** 非数据库字段: 借阅用户昵称 */
    private transient String nickname;
}
