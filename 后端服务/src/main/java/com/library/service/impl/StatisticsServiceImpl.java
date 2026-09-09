package com.library.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.library.entity.Book;
import com.library.entity.BookCategory;
import com.library.entity.BorrowRecord;
import com.library.entity.User;
import com.library.mapper.BookCategoryMapper;
import com.library.mapper.BookMapper;
import com.library.mapper.BorrowRecordMapper;
import com.library.mapper.UserMapper;
import com.library.service.StatisticsService;
import com.library.vo.StatisticsVO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

/**
 * 数据统计 Service 实现
 */
@Slf4j
@Service
public class StatisticsServiceImpl implements StatisticsService {

    @Autowired
    private BookMapper bookMapper;
    @Autowired
    private UserMapper userMapper;
    @Autowired
    private BorrowRecordMapper borrowRecordMapper;
    @Autowired
    private BookCategoryMapper bookCategoryMapper;

    @Override
    public StatisticsVO homeStatistics() {
        StatisticsVO vo = new StatisticsVO();

        // 总图书数
        Long totalBooks = bookMapper.selectCount(null);
        vo.setTotalBooks(totalBooks == null ? 0 : totalBooks);

        // 总用户数 (排除管理员)
        Long totalUsers = userMapper.selectCount(new LambdaQueryWrapper<User>()
                .eq(User::getRole, "user"));
        vo.setTotalUsers(totalUsers == null ? 0 : totalUsers);

        // 在借数量 (状态=借阅中)
        Long borrowingCount = borrowRecordMapper.selectCount(new LambdaQueryWrapper<BorrowRecord>()
                .eq(BorrowRecord::getStatus, "借阅中"));
        vo.setBorrowingCount(borrowingCount == null ? 0 : borrowingCount);

        // 累计借阅次数 (排除驳回)
        Long totalBorrowCount = borrowRecordMapper.selectCount(new LambdaQueryWrapper<BorrowRecord>()
                .ne(BorrowRecord::getStatus, "驳回"));
        vo.setTotalBorrowCount(totalBorrowCount == null ? 0 : totalBorrowCount);

        // 分类图书数量 (饼图): 单条 GROUP BY 查询, 避免按分类循环 count 的 N+1 问题
        List<Map<String, Object>> categoryBookCount = new ArrayList<>();
        List<Map<String, Object>> categoryCounts = bookMapper.selectCategoryBookCount();
        for (Map<String, Object> row : categoryCounts) {
            Map<String, Object> item = new HashMap<>(2);
            item.put("name", row.get("categoryName"));
            Object bookCount = row.get("bookCount");
            item.put("value", bookCount == null ? 0 : ((Number) bookCount).longValue());
            categoryBookCount.add(item);
        }
        vo.setCategoryBookCount(categoryBookCount);

        // 借阅趋势 (最近7天每日新增借阅记录数, 折线图)
        LocalDate today = LocalDate.now();
        LocalDate start = today.minusDays(6);
        LocalDateTime startTime = start.atStartOfDay();
        LocalDateTime endTime = today.atTime(LocalTime.MAX);

        List<BorrowRecord> records = borrowRecordMapper.selectList(new LambdaQueryWrapper<BorrowRecord>()
                .between(BorrowRecord::getCreateTime, startTime, endTime));

        // 初始化每天计数为0
        DateTimeFormatter fmt = DateTimeFormatter.ofPattern("yyyy-MM-dd");
        LinkedHashMap<String, Long> dateCountMap = new LinkedHashMap<>();
        for (int i = 0; i <= 6; i++) {
            String dateStr = start.plusDays(i).format(fmt);
            dateCountMap.put(dateStr, 0L);
        }
        // 统计每天记录数
        for (BorrowRecord r : records) {
            if (r.getCreateTime() != null) {
                String dateStr = r.getCreateTime().toLocalDate().format(fmt);
                dateCountMap.computeIfPresent(dateStr, (k, v) -> v + 1);
            }
        }

        Map<String, Object> trend = new HashMap<>(2);
        trend.put("dates", new ArrayList<>(dateCountMap.keySet()));
        trend.put("counts", new ArrayList<>(dateCountMap.values()));
        vo.setBorrowTrend(trend);

        return vo;
    }
}
