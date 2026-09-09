package com.library.service.impl;

import cn.hutool.core.util.StrUtil;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.library.common.BaseContext;
import com.library.common.BusinessException;
import com.library.dto.AuditDTO;
import com.library.dto.BorrowDTO;
import com.library.entity.Book;
import com.library.entity.BorrowRecord;
import com.library.mapper.BookMapper;
import com.library.mapper.BorrowRecordMapper;
import com.library.service.BorrowRecordService;
import lombok.extern.slf4j.Slf4j;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;

/**
 * 借阅记录 Service 实现
 * 借阅/归还操作使用事务同步维护图书库存
 */
@Slf4j
@Service
public class BorrowRecordServiceImpl extends ServiceImpl<BorrowRecordMapper, BorrowRecord> implements BorrowRecordService {

    @Autowired
    private BookMapper bookMapper;

    @Override
    public void submitBorrow(BorrowDTO dto) {
        Long userId = BaseContext.getCurrentUserId();
        if (userId == null) {
            throw new BusinessException(401, "未登录");
        }
        Book book = bookMapper.selectById(dto.getBookId());
        if (book == null) {
            throw new BusinessException("图书不存在");
        }
        // 校验库存: 可借 = 总库存 - 已借出
        int available = (book.getTotalNum() == null ? 0 : book.getTotalNum())
                - (book.getBorrowNum() == null ? 0 : book.getBorrowNum());
        if (available <= 0) {
            throw new BusinessException("该图书已无可借库存");
        }
        // 校验是否已有该图书在借中/待审核(防止重复借阅)
        Long activeCount = baseMapper.selectCount(new LambdaQueryWrapper<BorrowRecord>()
                .eq(BorrowRecord::getUserId, userId)
                .eq(BorrowRecord::getBookId, dto.getBookId())
                .in(BorrowRecord::getStatus, "待审核", "借阅中"));
        if (activeCount > 0) {
            throw new BusinessException("您已借阅该图书且尚未归还,不能重复借阅");
        }
        // 创建借阅申请记录, 状态=待审核
        BorrowRecord record = new BorrowRecord();
        record.setUserId(userId);
        record.setBookId(dto.getBookId());
        record.setStatus("待审核");
        baseMapper.insert(record);
    }

    @Override
    public IPage<BorrowRecord> myBorrowPage(int pageNum, int pageSize, String status, String keyword) {
        Long userId = BaseContext.getCurrentUserId();
        if (userId == null) {
            throw new BusinessException(401, "未登录");
        }
        Page<BorrowRecord> page = new Page<>(pageNum, pageSize);
        return baseMapper.selectBorrowPage(page, userId, status, keyword);
    }

    @Override
    public IPage<BorrowRecord> allBorrowPage(int pageNum, int pageSize, String status, String keyword) {
        Page<BorrowRecord> page = new Page<>(pageNum, pageSize);
        return baseMapper.selectBorrowPage(page, null, status, keyword);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void auditBorrow(Long id, AuditDTO dto) {
        BorrowRecord record = baseMapper.selectById(id);
        if (record == null) {
            throw new BusinessException("借阅记录不存在");
        }
        if (!"待审核".equals(record.getStatus())) {
            throw new BusinessException("该记录当前状态不允许审核");
        }
        Book book = bookMapper.selectById(record.getBookId());
        if (book == null) {
            throw new BusinessException("关联图书不存在");
        }

        if ("pass".equals(dto.getAction())) {
            // 审核通过: 校验库存, 状态变更为借阅中, 借阅时间记为当前, 图书已借出数量+1
            int available = (book.getTotalNum() == null ? 0 : book.getTotalNum())
                    - (book.getBorrowNum() == null ? 0 : book.getBorrowNum());
            if (available <= 0) {
                throw new BusinessException("库存不足,无法通过审核");
            }
            BorrowRecord update = new BorrowRecord();
            update.setId(id);
            update.setStatus("借阅中");
            update.setBorrowTime(LocalDateTime.now());
            baseMapper.updateById(update);
            // 图书已借出数量 +1
            Book bookUpdate = new Book();
            bookUpdate.setId(book.getId());
            bookUpdate.setBorrowNum((book.getBorrowNum() == null ? 0 : book.getBorrowNum()) + 1);
            bookMapper.updateById(bookUpdate);
        } else if ("reject".equals(dto.getAction())) {
            // 驳回: 状态变更为驳回, 记录驳回备注
            if (StrUtil.isBlank(dto.getRemark())) {
                throw new BusinessException("驳回时必须填写驳回备注");
            }
            BorrowRecord update = new BorrowRecord();
            update.setId(id);
            update.setStatus("驳回");
            update.setRemark(dto.getRemark());
            baseMapper.updateById(update);
        } else {
            throw new BusinessException("审核动作非法,应为 pass 或 reject");
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void returnBorrow(Long id) {
        BorrowRecord record = baseMapper.selectById(id);
        if (record == null) {
            throw new BusinessException("借阅记录不存在");
        }
        if (!"借阅中".equals(record.getStatus())) {
            throw new BusinessException("仅借阅中的记录可确认归还");
        }
        Book book = bookMapper.selectById(record.getBookId());
        if (book == null) {
            throw new BusinessException("关联图书不存在");
        }
        // 更新借阅记录: 状态=已归还, 归还时间=当前
        BorrowRecord update = new BorrowRecord();
        update.setId(id);
        update.setStatus("已归还");
        update.setReturnTime(LocalDateTime.now());
        baseMapper.updateById(update);
        // 图书已借出数量 -1, 不能小于0
        Book bookUpdate = new Book();
        bookUpdate.setId(book.getId());
        int newBorrowNum = (book.getBorrowNum() == null ? 0 : book.getBorrowNum()) - 1;
        if (newBorrowNum < 0) {
            newBorrowNum = 0;
        }
        bookUpdate.setBorrowNum(newBorrowNum);
        bookMapper.updateById(bookUpdate);
    }

    @Override
    public void exportBorrow(String status, String keyword, HttpServletResponse response) {
        List<BorrowRecord> list = baseMapper.selectExportList(status, keyword);

        try (Workbook workbook = new XSSFWorkbook()) {
            Sheet sheet = workbook.createSheet("借阅记录");

            // 标题行样式
            CellStyle headerStyle = workbook.createCellStyle();
            Font font = workbook.createFont();
            font.setBold(true);
            headerStyle.setFont(font);
            headerStyle.setAlignment(HorizontalAlignment.CENTER);
            headerStyle.setFillForegroundColor(IndexedColors.GREY_25_PERCENT.getIndex());
            headerStyle.setFillPattern(FillPatternType.SOLID_FOREGROUND);

            // 表头
            String[] headers = {"记录ID", "用户账号", "用户昵称", "图书名称", "作者",
                    "借阅时间", "归还时间", "状态", "驳回备注", "创建时间"};
            Row headerRow = sheet.createRow(0);
            for (int i = 0; i < headers.length; i++) {
                Cell cell = headerRow.createCell(i);
                cell.setCellValue(headers[i]);
                cell.setCellStyle(headerStyle);
            }

            // 数据行
            DateTimeFormatter fmt = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
            for (int i = 0; i < list.size(); i++) {
                BorrowRecord r = list.get(i);
                Row row = sheet.createRow(i + 1);
                row.createCell(0).setCellValue(r.getId() == null ? "" : r.getId().toString());
                row.createCell(1).setCellValue(r.getUsername() == null ? "" : r.getUsername());
                row.createCell(2).setCellValue(r.getNickname() == null ? "" : r.getNickname());
                row.createCell(3).setCellValue(r.getBookName() == null ? "" : r.getBookName());
                row.createCell(4).setCellValue(r.getAuthor() == null ? "" : r.getAuthor());
                row.createCell(5).setCellValue(r.getBorrowTime() == null ? "" : r.getBorrowTime().format(fmt));
                row.createCell(6).setCellValue(r.getReturnTime() == null ? "" : r.getReturnTime().format(fmt));
                row.createCell(7).setCellValue(r.getStatus() == null ? "" : r.getStatus());
                row.createCell(8).setCellValue(r.getRemark() == null ? "" : r.getRemark());
                row.createCell(9).setCellValue(r.getCreateTime() == null ? "" : r.getCreateTime().format(fmt));
            }

            // 自适应列宽
            for (int i = 0; i < headers.length; i++) {
                sheet.autoSizeColumn(i);
                // 适当加宽, 中文自适应偏窄
                sheet.setColumnWidth(i, Math.min(sheet.getColumnWidth(i) + 1000, 6000));
            }

            // 设置响应头, 触发文件下载
            response.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
            response.setCharacterEncoding("UTF-8");
            String fileName = "借阅记录_" + LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss")) + ".xlsx";
            response.setHeader("Content-Disposition", "attachment;filename=" + java.net.URLEncoder.encode(fileName, "UTF-8"));
            response.setHeader("Access-Control-Expose-Headers", "Content-Disposition");
            workbook.write(response.getOutputStream());
        } catch (IOException e) {
            log.error("导出借阅记录失败", e);
            throw new BusinessException("导出失败");
        }
    }
}
