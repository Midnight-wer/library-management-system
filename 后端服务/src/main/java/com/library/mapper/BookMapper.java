package com.library.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.library.entity.Book;
import org.apache.ibatis.annotations.Param;

import java.util.List;
import java.util.Map;

/**
 * 图书 Mapper
 */
public interface BookMapper extends BaseMapper<Book> {

    /**
     * 分页查询图书列表(支持名称/作者/分类搜索)
     */
    IPage<Book> selectBookPage(Page<Book> page,
                               @Param("bookName") String bookName,
                               @Param("author") String author,
                               @Param("categoryId") Long categoryId);

    /**
     * 统计每个分类下的图书数量(单条 GROUP BY 查询, 避免循环 N+1)
     * @return 每行包含 categoryId / categoryName / bookCount
     */
    List<Map<String, Object>> selectCategoryBookCount();
}
