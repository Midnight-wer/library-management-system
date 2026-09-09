package com.library.service;

import com.library.common.BusinessException;
import com.library.entity.Book;
import com.library.mapper.BookMapper;
import com.library.mapper.BorrowRecordMapper;
import com.library.service.impl.BookServiceImpl;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

/**
 * BUG-04 回归测试: 删除图书必须校验借阅记录, 防止产生孤儿借阅数据
 */
@ExtendWith(MockitoExtension.class)
class BookServiceImplTest {

    // 字段名必须为 baseMapper: MyBatis-Plus ServiceImpl 父类的字段名,
    // 否则存在两个 BaseMapper 类型 mock 时 Mockito 无法按名称消歧
    @Mock
    private BookMapper baseMapper;

    @Mock
    private BorrowRecordMapper borrowRecordMapper;

    @InjectMocks
    private BookServiceImpl bookService;

    @Test
    void deleteBook_图书不存在时抛出业务异常且不执行删除() {
        when(baseMapper.selectById(999L)).thenReturn(null);

        BusinessException ex = assertThrows(BusinessException.class, () -> bookService.deleteBook(999L));
        assertTrue(ex.getMessage().contains("图书不存在"));
        verify(baseMapper, never()).deleteById(anyLong());
    }

    @Test
    void deleteBook_存在借阅记录时禁止删除() {
        Book book = new Book();
        book.setId(1L);
        book.setBookName("Java核心技术");
        when(baseMapper.selectById(1L)).thenReturn(book);
        // 该书有 2 条借阅记录(含历史)
        when(borrowRecordMapper.selectCount(any())).thenReturn(2L);

        BusinessException ex = assertThrows(BusinessException.class, () -> bookService.deleteBook(1L));
        assertTrue(ex.getMessage().contains("借阅记录"), "应提示存在借阅记录, 实际: " + ex.getMessage());
        verify(baseMapper, never()).deleteById(anyLong());
    }

    @Test
    void deleteBook_无借阅记录时删除成功() {
        Book book = new Book();
        book.setId(15L);
        book.setBookName("无记录图书");
        when(baseMapper.selectById(15L)).thenReturn(book);
        when(borrowRecordMapper.selectCount(any())).thenReturn(0L);

        assertDoesNotThrow(() -> bookService.deleteBook(15L));
        verify(baseMapper, times(1)).deleteById(15L);
    }
}
