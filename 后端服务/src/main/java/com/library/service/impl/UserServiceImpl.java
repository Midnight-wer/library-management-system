package com.library.service.impl;

import cn.hutool.crypto.digest.BCrypt;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.library.common.BaseContext;
import com.library.common.BusinessException;
import com.library.common.JwtUtils;
import com.library.dto.LoginDTO;
import com.library.dto.PasswordDTO;
import com.library.dto.RegisterDTO;
import com.library.dto.UserUpdateDTO;
import com.library.entity.BorrowRecord;
import com.library.entity.User;
import com.library.mapper.BorrowRecordMapper;
import com.library.mapper.UserMapper;
import com.library.service.UserService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.util.HashMap;
import java.util.Map;

/**
 * 用户 Service 实现
 */
@Slf4j
@Service
public class UserServiceImpl extends ServiceImpl<UserMapper, User> implements UserService {

    @Autowired
    private JwtUtils jwtUtils;

    @Autowired
    private BorrowRecordMapper borrowRecordMapper;

    @Override
    public void register(RegisterDTO dto) {
        // 校验账号唯一
        Long count = baseMapper.selectCount(new LambdaQueryWrapper<User>()
                .eq(User::getUsername, dto.getUsername()));
        if (count > 0) {
            throw new BusinessException("账号已存在,请更换账号");
        }
        User user = new User();
        user.setUsername(dto.getUsername());
        // 密码 BCrypt 加密
        user.setPassword(BCrypt.hashpw(dto.getPassword()));
        user.setNickname(StringUtils.hasText(dto.getNickname()) ? dto.getNickname() : dto.getUsername());
        user.setPhone(dto.getPhone());
        user.setRole("user");
        baseMapper.insert(user);
    }

    @Override
    public Map<String, Object> login(LoginDTO dto) {
        User user = baseMapper.selectOne(new LambdaQueryWrapper<User>()
                .eq(User::getUsername, dto.getUsername()));
        if (user == null) {
            throw new BusinessException("账号不存在");
        }
        // 校验密码
        if (!BCrypt.checkpw(dto.getPassword(), user.getPassword())) {
            throw new BusinessException("账号或密码错误");
        }
        // 生成 token
        String token = jwtUtils.generateToken(user.getId(), user.getUsername(), user.getRole());

        Map<String, Object> result = new HashMap<>(4);
        result.put("token", token);
        // 用户信息(不含密码,实体已用 @JsonIgnore 屏蔽)
        Map<String, Object> userInfo = new HashMap<>(8);
        userInfo.put("id", user.getId());
        userInfo.put("username", user.getUsername());
        userInfo.put("nickname", user.getNickname());
        userInfo.put("phone", user.getPhone());
        userInfo.put("avatar", user.getAvatar());
        userInfo.put("role", user.getRole());
        result.put("userInfo", userInfo);
        return result;
    }

    @Override
    public IPage<User> userPage(int pageNum, int pageSize, String keyword, String role) {
        Page<User> page = new Page<>(pageNum, pageSize);
        return baseMapper.selectUserPage(page, keyword, role);
    }

    @Override
    public User getCurrentUserInfo() {
        Long userId = BaseContext.getCurrentUserId();
        if (userId == null) {
            throw new BusinessException(401, "未登录");
        }
        User user = baseMapper.selectById(userId);
        if (user == null) {
            throw new BusinessException("用户不存在");
        }
        return user;
    }

    @Override
    public void updateProfile(UserUpdateDTO dto) {
        Long userId = BaseContext.getCurrentUserId();
        if (userId == null) {
            throw new BusinessException(401, "未登录");
        }
        User user = new User();
        user.setId(userId);
        user.setNickname(dto.getNickname());
        user.setPhone(dto.getPhone());
        user.setAvatar(dto.getAvatar());
        baseMapper.updateById(user);
    }

    @Override
    public void updatePassword(PasswordDTO dto) {
        Long userId = BaseContext.getCurrentUserId();
        if (userId == null) {
            throw new BusinessException(401, "未登录");
        }
        User user = baseMapper.selectById(userId);
        if (user == null) {
            throw new BusinessException("用户不存在");
        }
        // 校验原密码
        if (!BCrypt.checkpw(dto.getOldPassword(), user.getPassword())) {
            throw new BusinessException("原密码错误");
        }
        User update = new User();
        update.setId(userId);
        update.setPassword(BCrypt.hashpw(dto.getNewPassword()));
        baseMapper.updateById(update);
    }

    @Override
    public void updateUser(Long id, UserUpdateDTO dto) {
        User user = baseMapper.selectById(id);
        if (user == null) {
            throw new BusinessException("用户不存在");
        }
        User update = new User();
        update.setId(id);
        update.setNickname(dto.getNickname());
        update.setPhone(dto.getPhone());
        update.setAvatar(dto.getAvatar());
        baseMapper.updateById(update);
    }

    @Override
    public void deleteUser(Long id) {
        User user = baseMapper.selectById(id);
        if (user == null) {
            throw new BusinessException("用户不存在");
        }
        // 禁止删除当前登录的管理员账号自身
        Long currentId = BaseContext.getCurrentUserId();
        if (id.equals(currentId)) {
            throw new BusinessException("不能删除当前登录账号");
        }
        // 存在借阅记录(含历史记录)的用户禁止删除, 避免借阅记录关联用户信息丢失
        Long borrowCount = borrowRecordMapper.selectCount(new LambdaQueryWrapper<BorrowRecord>()
                .eq(BorrowRecord::getUserId, id));
        if (borrowCount > 0) {
            throw new BusinessException("该用户存在借阅记录,无法删除");
        }
        // 删除管理员时, 系统至少保留一个管理员账号
        if ("admin".equals(user.getRole())) {
            Long adminCount = baseMapper.selectCount(new LambdaQueryWrapper<User>()
                    .eq(User::getRole, "admin"));
            if (adminCount <= 1) {
                throw new BusinessException("系统至少保留一个管理员账号");
            }
        }
        baseMapper.deleteById(id);
    }
}
