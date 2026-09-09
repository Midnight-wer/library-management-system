package com.library.common;

/**
 * 当前登录用户上下文 (ThreadLocal 存储)
 * 用于在请求线程中传递当前登录用户信息
 */
public class BaseContext {

    private static final ThreadLocal<CurrentUser> CURRENT_USER = new ThreadLocal<>();

    /** 设置当前用户 */
    public static void setCurrentUser(CurrentUser user) {
        CURRENT_USER.set(user);
    }

    /** 获取当前用户 */
    public static CurrentUser getCurrentUser() {
        return CURRENT_USER.get();
    }

    /** 获取当前用户ID */
    public static Long getCurrentUserId() {
        CurrentUser user = CURRENT_USER.get();
        return user != null ? user.getUserId() : null;
    }

    /** 获取当前用户角色 */
    public static String getCurrentRole() {
        CurrentUser user = CURRENT_USER.get();
        return user != null ? user.getRole() : null;
    }

    /** 获取当前用户名 */
    public static String getCurrentUsername() {
        CurrentUser user = CURRENT_USER.get();
        return user != null ? user.getUsername() : null;
    }

    /** 清除 */
    public static void clear() {
        CURRENT_USER.remove();
    }
}
