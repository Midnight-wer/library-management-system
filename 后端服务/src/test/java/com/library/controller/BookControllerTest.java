package com.library.controller;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.library.common.BusinessException;
import com.library.common.Result;
import com.library.entity.Book;
import com.library.service.BookService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * BUG-06 回归测试: 不存在的图书详情必须返回业务错误(404), 不能返回 200 + null
 * BUG-10 回归测试: 分页参数必须被钳制(pageNum>=1, 1<=pageSize<=100)
 */
@ExtendWith(MockitoExtension.class)
class BookControllerTest {

    @Mock
    private BookService bookService;

    @InjectMocks
    private BookController bookController;

    @Test
    void 图书不存在时详情返回404业务异常() {
        when(bookService.getById(999999L)).thenReturn(null);

        BusinessException ex = assertThrows(BusinessException.class, () -> bookController.detail(999999L));
        assertEquals(404, ex.getCode(), "不存在的图书应返回 404");
        assertTrue(ex.getMessage().contains("不存在"));
    }

    @Test
    void 图书存在时详情正常返回() {
        Book book = new Book();
        book.setId(1L);
        book.setBookName("Java核心技术");
        when(bookService.getById(1L)).thenReturn(book);

        Result<Book> result = bookController.detail(1L);
        assertEquals(200, result.getCode());
        assertEquals("Java核心技术", result.getData().getBookName());
    }

    @Test
    @SuppressWarnings("unchecked")
    void 超大pageSize被钳制为100() {
        when(bookService.queryPage(anyInt(), anyInt(), any(), any(), any()))
                .thenReturn(mock(IPage.class));

        bookController.list(1, 100000, null, null, null);

        verify(bookService).queryPage(eq(1), eq(100), isNull(), isNull(), isNull());
    }

    @Test
    @SuppressWarnings("unchecked")
    void 非法分页参数被钳制为页码1和默认每页条数10() {
        when(bookService.queryPage(anyInt(), anyInt(), any(), any(), any()))
                .thenReturn(mock(IPage.class));

        bookController.list(-99, -1, null, null, null);

        // 页码兜底为 1; 每页条数非法时回退为默认值 10
        verify(bookService).queryPage(eq(1), eq(10), isNull(), isNull(), isNull());
    }

    @Test
    @SuppressWarnings("unchecked")
    void 合法分页参数原样传递() {
        when(bookService.queryPage(anyInt(), anyInt(), any(), any(), any()))
                .thenReturn(mock(IPage.class));

        bookController.list(3, 20, "Java", null, null);

        verify(bookService).queryPage(eq(3), eq(20), eq("Java"), isNull(), isNull());
    }
}
