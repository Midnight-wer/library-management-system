package com.library.controller;

import com.library.common.Result;
import com.library.dto.CategoryDTO;
import com.library.entity.BookCategory;
import com.library.service.BookCategoryService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;
import java.util.List;

/**
 * 图书分类接口
 */
@Slf4j
@RestController
@RequestMapping("/category")
public class CategoryController {

    @Autowired
    private BookCategoryService bookCategoryService;

    /**
     * 获取全部分类【登录】
     * GET /api/category/list
     */
    @GetMapping("/list")
    public Result<List<BookCategory>> list() {
        return Result.success(bookCategoryService.listAll());
    }

    /**
     * 新增分类【admin】
     * POST /api/category
     */
    @PostMapping
    public Result<Void> add(@RequestBody @Valid CategoryDTO dto) {
        bookCategoryService.addCategory(dto);
        return Result.success("新增成功", null);
    }

    /**
     * 编辑分类【admin】
     * PUT /api/category/{id}
     */
    @PutMapping("/{id}")
    public Result<Void> update(@PathVariable Long id, @RequestBody @Valid CategoryDTO dto) {
        bookCategoryService.updateCategory(id, dto);
        return Result.success("修改成功", null);
    }

    /**
     * 删除分类【admin】
     * DELETE /api/category/{id}
     */
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        bookCategoryService.deleteCategory(id);
        return Result.success("删除成功", null);
    }
}
