package com.library.vo;

import lombok.Data;

import java.util.List;
import java.util.Map;

/**
 * 后台首页统计数据
 */
@Data
public class StatisticsVO {

    /** 统计卡片 */
    private Long totalBooks;
    private Long totalUsers;
    private Long borrowingCount;
    private Long totalBorrowCount;

    /** 分类图书数量 (饼图): [{name, value}] */
    private List<Map<String, Object>> categoryBookCount;

    /** 借阅趋势 (折线图): {dates, counts} */
    private Map<String, Object> borrowTrend;
}
