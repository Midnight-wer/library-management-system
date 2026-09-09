package com.library.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.library.common.BusinessException;
import com.library.dto.BookDTO;
import com.library.entity.Book;
import com.library.entity.BorrowRecord;
import com.library.mapper.BookMapper;
import com.library.mapper.BorrowRecordMapper;
import com.library.service.BookService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

/**
 * 图书 Service 实现
 */
@Slf4j
@Service
public class BookServiceImpl extends ServiceImpl<BookMapper, Book> implements BookService {

    @Autowired
    private BorrowRecordMapper borrowRecordMapper;

    @Override
    public IPage<Book> queryPage(int pageNum, int pageSize, String bookName, String author, Long categoryId) {
        Page<Book> page = new Page<>(pageNum, pageSize);
        return baseMapper.selectBookPage(page, bookName, author, categoryId);
    }

    @Override
    public void addBook(BookDTO dto) {
        // ISBN 唯一性校验(若填写)
        if (StringUtils.hasText(dto.getIsbn())) {
            Long count = baseMapper.selectCount(new LambdaQueryWrapper<Book>()
                    .eq(Book::getIsbn, dto.getIsbn()));
            if (count > 0) {
                throw new BusinessException("ISBN已存在,请勿重复添加");
            }
        }
        Book book = new Book();
        book.setBookName(dto.getBookName());
        book.setAuthor(dto.getAuthor());
        book.setIsbn(dto.getIsbn());
        book.setCategoryId(dto.getCategoryId());
        book.setCover(dto.getCover());
        book.setTotalNum(dto.getTotalNum());
        book.setBorrowNum(0);
        book.setIntroduction(dto.getIntroduction());
        baseMapper.insert(book);
    }

    @Override
    public void updateBook(Long id, BookDTO dto) {
        Book book = baseMapper.selectById(id);
        if (book == null) {
            throw new BusinessException("图书不存在");
        }
        // ISBN 唯一性校验(排除自身)
        if (StringUtils.hasText(dto.getIsbn())) {
            Long count = baseMapper.selectCount(new LambdaQueryWrapper<Book>()
                    .eq(Book::getIsbn, dto.getIsbn())
                    .ne(Book::getId, id));
            if (count > 0) {
                throw new BusinessException("ISBN已被其他图书占用");
            }
        }
        // 新的总库存不能小于已借出数量
        if (dto.getTotalNum() != null && book.getBorrowNum() != null
                && dto.getTotalNum() < book.getBorrowNum()) {
            throw new BusinessException("总库存不能小于已借出数量(" + book.getBorrowNum() + ")");
        }
        Book update = new Book();
        update.setId(id);
        update.setBookName(dto.getBookName());
        update.setAuthor(dto.getAuthor());
        update.setIsbn(dto.getIsbn());
        update.setCategoryId(dto.getCategoryId());
        update.setCover(dto.getCover());
        update.setTotalNum(dto.getTotalNum());
        update.setIntroduction(dto.getIntroduction());
        baseMapper.updateById(update);
    }

    @Override
    public void deleteBook(Long id) {
        Book book = baseMapper.selectById(id);
        if (book == null) {
            throw new BusinessException("图书不存在");
        }
        // 存在借阅记录(含历史记录)时禁止删除, 避免借阅记录关联图书信息丢失成为孤儿数据
        Long borrowCount = borrowRecordMapper.selectCount(new LambdaQueryWrapper<BorrowRecord>()
                .eq(BorrowRecord::getBookId, id));
        if (borrowCount > 0) {
            throw new BusinessException("该图书存在借阅记录,无法删除");
        }
        baseMapper.deleteById(id);
    }
}
