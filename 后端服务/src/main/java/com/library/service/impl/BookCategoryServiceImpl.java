package com.library.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.library.common.BusinessException;
import com.library.dto.CategoryDTO;
import com.library.entity.Book;
import com.library.entity.BookCategory;
import com.library.mapper.BookCategoryMapper;
import com.library.mapper.BookMapper;
import com.library.service.BookCategoryService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * 图书分类 Service 实现
 */
@Slf4j
@Service
public class BookCategoryServiceImpl extends ServiceImpl<BookCategoryMapper, BookCategory> implements BookCategoryService {

    /**
     * 分类列表缓存名: 分类数据变更频率低, 但图书列表/详情/分类下拉等场景高频读取
     */
    private static final String CACHE_CATEGORY_LIST = "categoryList";

    @Autowired
    private BookMapper bookMapper;

    @Override
    @Cacheable(value = CACHE_CATEGORY_LIST, key = "'all'")
    public List<BookCategory> listAll() {
        return baseMapper.selectList(new LambdaQueryWrapper<BookCategory>()
                .orderByAsc(BookCategory::getId));
    }

    @Override
    @CacheEvict(value = CACHE_CATEGORY_LIST, allEntries = true)
    public void addCategory(CategoryDTO dto) {
        // 校验分类名称唯一
        Long count = baseMapper.selectCount(new LambdaQueryWrapper<BookCategory>()
                .eq(BookCategory::getCategoryName, dto.getCategoryName()));
        if (count > 0) {
            throw new BusinessException("分类名称已存在");
        }
        BookCategory category = new BookCategory();
        category.setCategoryName(dto.getCategoryName());
        baseMapper.insert(category);
    }

    @Override
    @CacheEvict(value = CACHE_CATEGORY_LIST, allEntries = true)
    public void updateCategory(Long id, CategoryDTO dto) {
        BookCategory category = baseMapper.selectById(id);
        if (category == null) {
            throw new BusinessException("分类不存在");
        }
        // 校验分类名称唯一(排除自身)
        Long count = baseMapper.selectCount(new LambdaQueryWrapper<BookCategory>()
                .eq(BookCategory::getCategoryName, dto.getCategoryName())
                .ne(BookCategory::getId, id));
        if (count > 0) {
            throw new BusinessException("分类名称已存在");
        }
        BookCategory update = new BookCategory();
        update.setId(id);
        update.setCategoryName(dto.getCategoryName());
        baseMapper.updateById(update);
    }

    @Override
    @CacheEvict(value = CACHE_CATEGORY_LIST, allEntries = true)
    public void deleteCategory(Long id) {
        // 校验是否被图书引用
        Long bookCount = bookMapper.selectCount(new LambdaQueryWrapper<Book>()
                .eq(Book::getCategoryId, id));
        if (bookCount > 0) {
            throw new BusinessException("该分类下存在图书,无法删除");
        }
        baseMapper.deleteById(id);
    }
}
