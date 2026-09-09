package com.library;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.transaction.annotation.EnableTransactionManagement;

/**
 * 图书管理系统启动类
 */
@SpringBootApplication
@MapperScan("com.library.mapper")
@EnableTransactionManagement
@EnableCaching
public class LibraryApplication {

    public static void main(String[] args) {
        SpringApplication.run(LibraryApplication.class, args);
        System.out.println("\n================ 图书管理系统后端启动成功 ================");
        System.out.println("接口基础地址: http://localhost:8080/api");
        System.out.println("======================================================\n");
    }
}
