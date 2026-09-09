package com.library.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.library.dto.CategoryDTO;
import com.library.entity.BookCategory;

import java.util.List;

/**
 * 图书分类 Service
 */
public interface BookCategoryService extends IService<BookCategory> {

    /** 获取全部分类 */
    List<BookCategory> listAll();

    /** 新增分类 */
    void addCategory(CategoryDTO dto);

    /** 编辑分类 */
    void updateCategory(Long id, CategoryDTO dto);

    /** 删除分类(校验是否被图书引用) */
    void deleteCategory(Long id);
}
