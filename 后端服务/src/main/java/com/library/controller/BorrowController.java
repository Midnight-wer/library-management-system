package com.library.controller;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.library.common.PageUtil;
import com.library.common.Result;
import com.library.dto.AuditDTO;
import com.library.dto.BorrowDTO;
import com.library.entity.BorrowRecord;
import com.library.service.BorrowRecordService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpServletResponse;
import javax.validation.Valid;

/**
 * 借阅接口
 */
@Slf4j
@RestController
@RequestMapping("/borrow")
public class BorrowController {

    @Autowired
    private BorrowRecordService borrowRecordService;

    /**
     * 提交借阅申请【user】
     * POST /api/borrow
     */
    @PostMapping
    public Result<Void> submit(@RequestBody @Valid BorrowDTO dto) {
        borrowRecordService.submitBorrow(dto);
        return Result.success("借阅申请已提交,等待管理员审核", null);
    }

    /**
     * 我的借阅记录分页【user】
     * GET /api/borrow/my
     */
    @GetMapping("/my")
    public Result<IPage<BorrowRecord>> my(@RequestParam(defaultValue = "1") int pageNum,
                                          @RequestParam(defaultValue = "10") int pageSize,
                                          @RequestParam(required = false) String status,
                                          @RequestParam(required = false) String keyword) {
        // 分页参数合法性钳制
        pageNum = PageUtil.normalizePageNum(pageNum);
        pageSize = PageUtil.normalizePageSize(pageSize);
        IPage<BorrowRecord> page = borrowRecordService.myBorrowPage(pageNum, pageSize, status, keyword);
        return Result.success(page);
    }

    /**
     * 全部借阅记录分页【admin】
     * GET /api/borrow/list
     */
    @GetMapping("/list")
    public Result<IPage<BorrowRecord>> list(@RequestParam(defaultValue = "1") int pageNum,
                                            @RequestParam(defaultValue = "10") int pageSize,
                                            @RequestParam(required = false) String status,
                                            @RequestParam(required = false) String keyword) {
        // 分页参数合法性钳制
        pageNum = PageUtil.normalizePageNum(pageNum);
        pageSize = PageUtil.normalizePageSize(pageSize);
        IPage<BorrowRecord> page = borrowRecordService.allBorrowPage(pageNum, pageSize, status, keyword);
        return Result.success(page);
    }

    /**
     * 借阅审核(通过/驳回)【admin】
     * PUT /api/borrow/{id}/audit
     */
    @PutMapping("/{id}/audit")
    public Result<Void> audit(@PathVariable Long id, @RequestBody @Valid AuditDTO dto) {
        borrowRecordService.auditBorrow(id, dto);
        return Result.success("操作成功", null);
    }

    /**
     * 确认归还图书【admin】
     * PUT /api/borrow/{id}/return
     */
    @PutMapping("/{id}/return")
    public Result<Void> returnBook(@PathVariable Long id) {
        borrowRecordService.returnBorrow(id);
        return Result.success("归还成功", null);
    }

    /**
     * 导出借阅 Excel【admin】
     * GET /api/borrow/export
     */
    @GetMapping("/export")
    public void export(@RequestParam(required = false) String status,
                       @RequestParam(required = false) String keyword,
                       HttpServletResponse response) {
        borrowRecordService.exportBorrow(status, keyword, response);
    }
}
