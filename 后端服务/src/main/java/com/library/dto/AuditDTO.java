package com.library.dto;

import lombok.Data;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Size;

/**
 * 借阅审核请求
 */
@Data
public class AuditDTO {

    /** 审核结果: pass=通过 reject=驳回 */
    @NotBlank(message = "审核动作不能为空")
    private String action;

    /** 驳回备注 (action=reject时必填) */
    @Size(max = 255, message = "驳回备注长度不能超过255")
    private String remark;
}
