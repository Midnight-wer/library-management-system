package com.library.service;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.service.IService;
import com.library.dto.AuditDTO;
import com.library.dto.BorrowDTO;
import com.library.entity.BorrowRecord;

import javax.servlet.http.HttpServletResponse;
import java.util.List;

/**
 * 借阅记录 Service
 */
public interface BorrowRecordService extends IService<BorrowRecord> {

    /** 提交借阅申请 */
    void submitBorrow(BorrowDTO dto);

    /** 我的借阅记录分页 */
    IPage<BorrowRecord> myBorrowPage(int pageNum, int pageSize, String status, String keyword);

    /** 全部借阅记录分页 */
    IPage<BorrowRecord> allBorrowPage(int pageNum, int pageSize, String status, String keyword);

    /** 借阅审核(通过/驳回) */
    void auditBorrow(Long id, AuditDTO dto);

    /** 确认归还图书 */
    void returnBorrow(Long id);

    /** 导出借阅记录 Excel */
    void exportBorrow(String status, String keyword, HttpServletResponse response);
}
