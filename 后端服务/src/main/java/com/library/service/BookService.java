package com.library.service;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.service.IService;
import com.library.dto.BookDTO;
import com.library.entity.Book;

/**
 * 图书 Service
 */
public interface BookService extends IService<Book> {

    /** 分页查询图书 */
    IPage<Book> queryPage(int pageNum, int pageSize, String bookName, String author, Long categoryId);

    /** 新增图书 */
    void addBook(BookDTO dto);

    /** 编辑图书 */
    void updateBook(Long id, BookDTO dto);

    /** 删除图书(存在借阅记录时禁止删除) */
    void deleteBook(Long id);
}
