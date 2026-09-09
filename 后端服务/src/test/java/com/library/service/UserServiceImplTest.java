package com.library.service;

import com.library.common.BaseContext;
import com.library.common.BusinessException;
import com.library.common.CurrentUser;
import com.library.common.JwtUtils;
import com.library.entity.User;
import com.library.mapper.BorrowRecordMapper;
import com.library.mapper.UserMapper;
import com.library.service.impl.UserServiceImpl;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.*;

/**
 * BUG-05 回归测试: 删除用户必须校验
 * 1) 用户存在性 2) 禁止删除当前登录账号 3) 有借阅记录禁删 4) 至少保留一个管理员
 */
@ExtendWith(MockitoExtension.class)
class UserServiceImplTest {

    // 字段名必须为 baseMapper: MyBatis-Plus ServiceImpl 父类的字段名,
    // 否则存在两个 BaseMapper 类型 mock 时 Mockito 无法按名称消歧
    @Mock
    private UserMapper baseMapper;

    @Mock
    private BorrowRecordMapper borrowRecordMapper;

    @Mock
    private JwtUtils jwtUtils;

    @InjectMocks
    private UserServiceImpl userService;

    /** 模拟当前登录的管理员: id=1, admin */
    @BeforeEach
    void setUp() {
        BaseContext.setCurrentUser(new CurrentUser(1L, "admin", "admin"));
    }

    @AfterEach
    void tearDown() {
        BaseContext.clear();
    }

    private User user(Long id, String username, String role) {
        User u = new User();
        u.setId(id);
        u.setUsername(username);
        u.setRole(role);
        return u;
    }

    @Test
    void deleteUser_用户不存在时抛出异常且不删除() {
        when(baseMapper.selectById(999L)).thenReturn(null);

        BusinessException ex = assertThrows(BusinessException.class, () -> userService.deleteUser(999L));
        assertTrue(ex.getMessage().contains("用户不存在"));
        verify(baseMapper, never()).deleteById(anyLong());
    }

    @Test
    void deleteUser_禁止删除当前登录的管理员自己() {
        when(baseMapper.selectById(1L)).thenReturn(user(1L, "admin", "admin"));

        BusinessException ex = assertThrows(BusinessException.class, () -> userService.deleteUser(1L));
        assertTrue(ex.getMessage().contains("当前登录"), "应提示不能删除当前登录账号, 实际: " + ex.getMessage());
        verify(baseMapper, never()).deleteById(anyLong());
    }

    @Test
    void deleteUser_目标用户有借阅记录时禁止删除() {
        when(baseMapper.selectById(2L)).thenReturn(user(2L, "zhangsan", "user"));
        when(borrowRecordMapper.selectCount(any())).thenReturn(3L);

        BusinessException ex = assertThrows(BusinessException.class, () -> userService.deleteUser(2L));
        assertTrue(ex.getMessage().contains("借阅记录"), "应提示存在借阅记录, 实际: " + ex.getMessage());
        verify(baseMapper, never()).deleteById(anyLong());
    }

    @Test
    void deleteUser_删除最后一个管理员时禁止() {
        // 当前登录 id=1(admin), 删除目标 id=5(admin), 但全系统管理员总数为 1 -> 拦截
        when(baseMapper.selectById(5L)).thenReturn(user(5L, "boss", "admin"));
        when(borrowRecordMapper.selectCount(any())).thenReturn(0L);
        when(baseMapper.selectCount(any())).thenReturn(1L);

        BusinessException ex = assertThrows(BusinessException.class, () -> userService.deleteUser(5L));
        assertTrue(ex.getMessage().contains("至少保留一个管理员"), "应提示保留管理员, 实际: " + ex.getMessage());
        verify(baseMapper, never()).deleteById(anyLong());
    }

    @Test
    void deleteUser_无借阅记录的普通用户可正常删除() {
        when(baseMapper.selectById(3L)).thenReturn(user(3L, "tmpuser", "user"));
        when(borrowRecordMapper.selectCount(any())).thenReturn(0L);

        assertDoesNotThrow(() -> userService.deleteUser(3L));
        verify(baseMapper, times(1)).deleteById(3L);
    }

    @Test
    void deleteUser_存在多个管理员时可删除其他管理员() {
        when(baseMapper.selectById(5L)).thenReturn(user(5L, "boss", "admin"));
        when(borrowRecordMapper.selectCount(any())).thenReturn(0L);
        when(baseMapper.selectCount(any())).thenReturn(2L);

        assertDoesNotThrow(() -> userService.deleteUser(5L));
        verify(baseMapper, times(1)).deleteById(5L);
    }
}
