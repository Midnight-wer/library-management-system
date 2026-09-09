package com.library.service;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.service.IService;
import com.library.dto.LoginDTO;
import com.library.dto.RegisterDTO;
import com.library.dto.UserUpdateDTO;
import com.library.dto.PasswordDTO;
import com.library.entity.User;

import java.util.Map;

/**
 * 用户 Service
 */
public interface UserService extends IService<User> {

    /** 注册 */
    void register(RegisterDTO dto);

    /** 登录, 返回 token 和用户信息 */
    Map<String, Object> login(LoginDTO dto);

    /** 管理员分页查询用户列表 */
    IPage<User> userPage(int pageNum, int pageSize, String keyword, String role);

    /** 获取当前登录用户信息 */
    User getCurrentUserInfo();

    /** 修改个人资料 */
    void updateProfile(UserUpdateDTO dto);

    /** 修改密码 */
    void updatePassword(PasswordDTO dto);

    /** 管理员编辑用户 */
    void updateUser(Long id, UserUpdateDTO dto);

    /** 管理员删除用户(禁止删除自己/有借阅记录的用户/最后一个管理员) */
    void deleteUser(Long id);
}
