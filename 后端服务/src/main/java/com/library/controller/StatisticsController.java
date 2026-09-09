package com.library.controller;

import com.library.common.Result;
import com.library.service.StatisticsService;
import com.library.vo.StatisticsVO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 统计 & 文件导出接口
 */
@Slf4j
@RestController
@RequestMapping("/statistics")
public class StatisticsController {

    @Autowired
    private StatisticsService statisticsService;

    /**
     * 后台首页统计数据【admin】
     * GET /api/statistics/home
     */
    @GetMapping("/home")
    public Result<StatisticsVO> home() {
        return Result.success(statisticsService.homeStatistics());
    }
}
