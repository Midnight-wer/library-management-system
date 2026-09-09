package com.library.common;

import com.baomidou.mybatisplus.core.handlers.MetaObjectHandler;
import org.apache.ibatis.reflection.MetaObject;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;

/**
 * MyBatis-Plus 自动填充处理器
 * 用途: 自动填充 createTime / updateTime 字段
 * 兼容: 数据库 DATETIME 字段不设置默认值时, 由应用层填充
 */
@Component
public class MyMetaObjectHandler implements MetaObjectHandler {

    /**
     * 插入时自动填充
     */
    @Override
    public void insertFill(MetaObject metaObject) {
        LocalDateTime now = LocalDateTime.now();
        // 填充 createTime
        Object createTime = getFieldValByName("createTime", metaObject);
        if (createTime == null) {
            strictInsertFill(metaObject, "createTime", LocalDateTime.class, now);
        }
        // 填充 updateTime
        Object updateTime = getFieldValByName("updateTime", metaObject);
        if (updateTime == null) {
            strictInsertFill(metaObject, "updateTime", LocalDateTime.class, now);
        }
    }

    /**
     * 更新时自动填充
     */
    @Override
    public void updateFill(MetaObject metaObject) {
        // 更新时刷新 updateTime
        strictUpdateFill(metaObject, "updateTime", LocalDateTime.class, LocalDateTime.now());
    }
}
