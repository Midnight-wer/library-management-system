package com.library.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.library.entity.BorrowRecord;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 借阅记录 Mapper
 */
public interface BorrowRecordMapper extends BaseMapper<BorrowRecord> {

    /**
     * 分页查询借阅记录(关联图书、用户信息)
     *
     * @param userId   指定用户ID(我的借阅使用), null 则查全部
     * @param status   状态筛选
     * @param keyword  图书名称模糊搜索
     */
    IPage<BorrowRecord> selectBorrowPage(Page<BorrowRecord> page,
                                         @Param("userId") Long userId,
                                         @Param("status") String status,
                                         @Param("keyword") String keyword);

    /**
     * 查询导出数据(全部借阅记录, 支持条件筛选)
     */
    List<BorrowRecord> selectExportList(@Param("status") String status,
                                        @Param("keyword") String keyword);
}
