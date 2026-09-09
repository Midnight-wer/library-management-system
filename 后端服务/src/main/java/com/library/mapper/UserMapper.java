package com.library.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.library.entity.User;
import org.apache.ibatis.annotations.Param;

/**
 * 用户 Mapper
 */
public interface UserMapper extends BaseMapper<User> {

    /**
     * 分页查询用户列表(支持账号/昵称/角色模糊搜索)
     */
    IPage<User> selectUserPage(Page<User> page,
                               @Param("keyword") String keyword,
                               @Param("role") String role);
}
