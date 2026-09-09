package com.library.common;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

/**
 * BUG-10 回归测试: 分页参数钳制工具
 *  - 页码最小为 1
 *  - 每页条数上限 100, 非法值回退默认值 10
 */
class PageUtilTest {

    @Test
    void 页码负数和零都兜底为1() {
        assertEquals(1, PageUtil.normalizePageNum(-99));
        assertEquals(1, PageUtil.normalizePageNum(0));
    }

    @Test
    void 合法页码原样返回() {
        assertEquals(5, PageUtil.normalizePageNum(5));
    }

    @Test
    void 每页条数超过100时钳制为100() {
        assertEquals(100, PageUtil.normalizePageSize(100000));
        assertEquals(100, PageUtil.normalizePageSize(101));
    }

    @Test
    void 每页条数非法时回退默认值10() {
        assertEquals(10, PageUtil.normalizePageSize(0));
        assertEquals(10, PageUtil.normalizePageSize(-1));
    }

    @Test
    void 合法每页条数原样返回() {
        assertEquals(20, PageUtil.normalizePageSize(20));
        assertEquals(1, PageUtil.normalizePageSize(1));
        assertEquals(100, PageUtil.normalizePageSize(100));
    }
}
