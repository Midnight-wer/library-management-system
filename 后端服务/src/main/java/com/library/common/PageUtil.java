package com.library.common;

/**
 * 分页参数处理工具
 * 统一各分页接口的页码/每页条数合法性钳制规则
 */
public final class PageUtil {

    /** 每页最大条数, 防止超大分页一次加载过多数据拖垮服务 */
    public static final int MAX_PAGE_SIZE = 100;

    /** 默认每页条数 */
    public static final int DEFAULT_PAGE_SIZE = 10;

    private PageUtil() {
    }

    /** 页码最小为 1 */
    public static int normalizePageNum(int pageNum) {
        return Math.max(pageNum, 1);
    }

    /** 每页条数钳制在 1~MAX_PAGE_SIZE, 非法值(<=0)回退为默认值 */
    public static int normalizePageSize(int pageSize) {
        if (pageSize < 1) {
            return DEFAULT_PAGE_SIZE;
        }
        return Math.min(pageSize, MAX_PAGE_SIZE);
    }
}
