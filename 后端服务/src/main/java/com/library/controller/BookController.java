package com.library.controller;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.library.common.BusinessException;
import com.library.common.PageUtil;
import com.library.common.Result;
import com.library.dto.BookDTO;
import com.library.entity.Book;
import com.library.service.BookService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;

/**
 * 图书接口
 */
@Slf4j
@RestController
@RequestMapping("/book")
public class BookController {

    @Autowired
    private BookService bookService;

    /**
     * 图书分页列表, 支持搜索【登录】
     * GET /api/book/list
     */
    @GetMapping("/list")
    public Result<IPage<Book>> list(@RequestParam(defaultValue = "1") int pageNum,
                                    @RequestParam(defaultValue = "10") int pageSize,
                                    @RequestParam(required = false) String bookName,
                                    @RequestParam(required = false) String author,
                                    @RequestParam(required = false) Long categoryId) {
        // 分页参数合法性钳制
        pageNum = PageUtil.normalizePageNum(pageNum);
        pageSize = PageUtil.normalizePageSize(pageSize);
        IPage<Book> page = bookService.queryPage(pageNum, pageSize, bookName, author, categoryId);
        return Result.success(page);
    }

    /**
     * 图书详情【登录】
     * GET /api/book/{id}
     */
    @GetMapping("/{id}")
    public Result<Book> detail(@PathVariable Long id) {
        Book book = bookService.getById(id);
        if (book == null) {
            throw new BusinessException(404, "图书不存在或已下架");
        }
        return Result.success(book);
    }

    /**
     * 新增图书【admin】
     * POST /api/book
     */
    @PostMapping
    public Result<Void> add(@RequestBody @Valid BookDTO dto) {
        bookService.addBook(dto);
        return Result.success("新增成功", null);
    }

    /**
     * 编辑图书【admin】
     * PUT /api/book/{id}
     */
    @PutMapping("/{id}")
    public Result<Void> update(@PathVariable Long id, @RequestBody @Valid BookDTO dto) {
        bookService.updateBook(id, dto);
        return Result.success("修改成功", null);
    }

    /**
     * 删除图书【admin】
     * DELETE /api/book/{id}
     */
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        bookService.deleteBook(id);
        return Result.success("删除成功", null);
    }
}
