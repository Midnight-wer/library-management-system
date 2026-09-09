package com.library.controller;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.library.common.PageUtil;
import com.library.common.Result;
import com.library.dto.LoginDTO;
import com.library.dto.PasswordDTO;
import com.library.dto.RegisterDTO;
import com.library.dto.UserUpdateDTO;
import com.library.entity.User;
import com.library.service.UserService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;
import java.util.Map;

/**
 * 用户接口
 */
@Slf4j
@RestController
@RequestMapping("/user")
public class UserController {

    @Autowired
    private UserService userService;

    /**
     * 注册【公开】
     * POST /api/user/register
     */
    @PostMapping("/register")
    public Result<Void> register(@RequestBody @Valid RegisterDTO dto) {
        userService.register(dto);
        return Result.success("注册成功", null);
    }

    /**
     * 登录【公开】
     * POST /api/user/login
     */
    @PostMapping("/login")
    public Result<Map<String, Object>> login(@RequestBody @Valid LoginDTO dto) {
        Map<String, Object> data = userService.login(dto);
        return Result.success("登录成功", data);
    }

    /**
     * 获取当前登录用户【登录】
     * GET /api/user/info
     */
    @GetMapping("/info")
    public Result<User> info() {
        return Result.success(userService.getCurrentUserInfo());
    }

    /**
     * 修改个人资料【登录】
     * PUT /api/user/info
     */
    @PutMapping("/info")
    public Result<Void> updateInfo(@RequestBody @Valid UserUpdateDTO dto) {
        userService.updateProfile(dto);
        return Result.success("修改成功", null);
    }

    /**
     * 修改密码【登录】
     * PUT /api/user/password
     */
    @PutMapping("/password")
    public Result<Void> updatePassword(@RequestBody @Valid PasswordDTO dto) {
        userService.updatePassword(dto);
        return Result.success("密码修改成功", null);
    }

    /**
     * 用户分页搜索列表【admin】
     * GET /api/user/list
     */
    @GetMapping("/list")
    public Result<IPage<User>> list(@RequestParam(defaultValue = "1") int pageNum,
                                   @RequestParam(defaultValue = "10") int pageSize,
                                   @RequestParam(required = false) String keyword,
                                   @RequestParam(required = false) String role) {
        // 分页参数合法性钳制
        pageNum = PageUtil.normalizePageNum(pageNum);
        pageSize = PageUtil.normalizePageSize(pageSize);
        IPage<User> page = userService.userPage(pageNum, pageSize, keyword, role);
        return Result.success(page);
    }

    /**
     * 编辑用户【admin】
     * PUT /api/user/{id}
     */
    @PutMapping("/{id}")
    public Result<Void> updateUser(@PathVariable Long id, @RequestBody @Valid UserUpdateDTO dto) {
        userService.updateUser(id, dto);
        return Result.success("修改成功", null);
    }

    /**
     * 删除用户【admin】
     * DELETE /api/user/{id}
     */
    @DeleteMapping("/{id}")
    public Result<Void> deleteUser(@PathVariable Long id) {
        userService.deleteUser(id);
        return Result.success("删除成功", null);
    }
}
