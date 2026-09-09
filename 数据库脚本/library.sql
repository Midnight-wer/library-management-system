-- ============================================================
-- 图书管理系统 数据库脚本 (MySQL 8.0, 兼容 MySQL 5.5)
-- 包含: 建表语句 + 初始化测试数据
-- 注: DATETIME 字段默认值由应用层 (MyBatis-Plus MetaObjectHandler) 自动填充
--     以兼容 MySQL 5.5 不支持 DATETIME DEFAULT CURRENT_TIMESTAMP 的问题
-- ============================================================

DROP DATABASE IF EXISTS library_db;
CREATE DATABASE library_db DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE library_db;

-- ----------------------------
-- 1. 用户表
-- ----------------------------
DROP TABLE IF EXISTS `user`;
CREATE TABLE `user` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键自增',
  `username` VARCHAR(50) NOT NULL COMMENT '账号唯一',
  `password` VARCHAR(100) NOT NULL COMMENT '密码加密存储',
  `nickname` VARCHAR(50) DEFAULT NULL COMMENT '昵称',
  `phone` VARCHAR(20) DEFAULT NULL COMMENT '手机号',
  `avatar` VARCHAR(255) DEFAULT NULL COMMENT '头像地址',
  `role` VARCHAR(20) NOT NULL DEFAULT 'user' COMMENT '角色 user/admin',
  `create_time` DATETIME DEFAULT NULL COMMENT '创建时间(应用层填充)',
  `update_time` DATETIME DEFAULT NULL COMMENT '更新时间(应用层填充)',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_username` (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';

-- ----------------------------
-- 2. 图书分类表
-- ----------------------------
DROP TABLE IF EXISTS `book_category`;
CREATE TABLE `book_category` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键自增',
  `category_name` VARCHAR(50) NOT NULL COMMENT '分类名称',
  `create_time` DATETIME DEFAULT NULL COMMENT '创建时间(应用层填充)',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='图书分类表';

-- ----------------------------
-- 3. 图书表
-- ----------------------------
DROP TABLE IF EXISTS `book`;
CREATE TABLE `book` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键自增',
  `book_name` VARCHAR(100) NOT NULL COMMENT '图书名称',
  `author` VARCHAR(100) DEFAULT NULL COMMENT '作者',
  `isbn` VARCHAR(50) DEFAULT NULL COMMENT 'ISBN编号',
  `category_id` BIGINT DEFAULT NULL COMMENT '关联分类id',
  `cover` VARCHAR(255) DEFAULT NULL COMMENT '图书封面',
  `total_num` INT NOT NULL DEFAULT 1 COMMENT '总库存',
  `borrow_num` INT NOT NULL DEFAULT 0 COMMENT '已借出数量',
  `introduction` TEXT COMMENT '图书简介',
  `create_time` DATETIME DEFAULT NULL COMMENT '创建时间(应用层填充)',
  `update_time` DATETIME DEFAULT NULL COMMENT '更新时间(应用层填充)',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_isbn` (`isbn`),
  KEY `idx_category_id` (`category_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='图书表';

-- ----------------------------
-- 4. 借阅记录表
-- ----------------------------
DROP TABLE IF EXISTS `borrow_record`;
CREATE TABLE `borrow_record` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键自增',
  `user_id` BIGINT NOT NULL COMMENT '借阅用户id',
  `book_id` BIGINT NOT NULL COMMENT '图书id',
  `borrow_time` DATETIME DEFAULT NULL COMMENT '借阅时间(业务层填充)',
  `return_time` DATETIME DEFAULT NULL COMMENT '归还时间(业务层填充)',
  `status` VARCHAR(20) NOT NULL DEFAULT '待审核' COMMENT '待审核/借阅中/已归还/驳回',
  `remark` VARCHAR(255) DEFAULT NULL COMMENT '驳回备注',
  `create_time` DATETIME DEFAULT NULL COMMENT '记录创建时间(应用层填充)',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_book_id` (`book_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='借阅记录表';

-- ============================================================
-- 初始化测试数据
-- 注: 时间字段使用 NOW() 显式插入, 不依赖数据库默认值
-- ============================================================

-- 管理员账号 admin / 123456 (密码使用 BCrypt 加密)
INSERT INTO `user` (`username`,`password`,`nickname`,`phone`,`avatar`,`role`,`create_time`,`update_time`) VALUES
('admin','$2a$10$HcwfJP5IBUIOBwwZ2hPeBuu19JI2Tb/pNDUsEfHlBn1l2zo0N6lGW','超级管理员','13800000000',NULL,'admin',NOW(),NOW()),
('zhangsan','$2a$10$HcwfJP5IBUIOBwwZ2hPeBuu19JI2Tb/pNDUsEfHlBn1l2zo0N6lGW','张三','13800000001',NULL,'user',NOW(),NOW()),
('lisi','$2a$10$HcwfJP5IBUIOBwwZ2hPeBuu19JI2Tb/pNDUsEfHlBn1l2zo0N6lGW','李四','13800000002',NULL,'user',NOW(),NOW());

-- 图书分类
INSERT INTO `book_category` (`category_name`,`create_time`) VALUES
('计算机科学',NOW()),
('文学小说',NOW()),
('历史人文',NOW()),
('科学技术',NOW()),
('经济管理',NOW()),
('哲学宗教',NOW());

-- 图书测试数据
INSERT INTO `book` (`book_name`,`author`,`isbn`,`category_id`,`cover`,`total_num`,`borrow_num`,`introduction`,`create_time`,`update_time`) VALUES
('Java核心技术 卷I','Cay S. Horstmann','9787115554296',1,NULL,5,0,'《Java核心技术》是Java领域的经典著作，全面系统地讲解Java核心技术。',NOW(),NOW()),
('深入理解Java虚拟机','周志明','9787111641260',1,NULL,3,0,'本书从源码角度深入剖析JVM，是Java进阶必读经典。',NOW(),NOW()),
('Vue.js设计与实现','霍春阳','9787115583869',1,NULL,4,0,'本书全面剖析Vue.js的设计思路与实现原理。',NOW(),NOW()),
('Spring Boot实战','丁雪丰','9787115461341',1,NULL,3,0,'Spring Boot入门到实战，快速构建微服务应用。',NOW(),NOW()),
('红楼梦','曹雪芹','9787020002207',2,NULL,10,0,'中国古典四大名著之一，长篇章回体小说巅峰之作。',NOW(),NOW()),
('三国演义','罗贯中','9787020002191',2,NULL,8,0,'中国古典四大名著之一，讲述东汉末年群雄逐鹿的故事。',NOW(),NOW()),
('明朝那些事儿','当年明月','9787540461001',3,NULL,6,0,'以通俗幽默的笔调讲述明朝三百年历史。',NOW(),NOW()),
('人类简史','尤瓦尔·赫拉利','9787508647357',3,NULL,5,0,'从认知革命到科学革命，重新审视人类发展历程。',NOW(),NOW()),
('三体','刘慈欣','9787536692930',2,NULL,7,0,'中国科幻里程碑，描述地球文明与三体文明的接触。',NOW(),NOW()),
('Python编程从入门到实践','埃里克·马瑟斯','9787115458016',1,NULL,6,0,'Python入门经典，通过项目实战学习编程。',NOW(),NOW()),
('时间简史','史蒂芬·霍金','9787535732309',4,NULL,5,0,'探索宇宙起源与时空本质的科普名著。',NOW(),NOW()),
('经济学原理','曼昆','9787305098970',5,NULL,4,0,'经济学入门经典教材，讲述供需与市场原理。',NOW(),NOW()),
('苏菲的世界','乔斯坦·贾德','9787544291003',6,NULL,5,0,'以小说形式讲述西方哲学发展史的哲学启蒙读物。',NOW(),NOW()),
('设计模式','GoF','9787111063079',1,NULL,3,0,'面向对象软件设计的经典著作，介绍23种设计模式。',NOW(),NOW()),
('活着','余华','9787506365437',2,NULL,9,0,'余华代表作，讲述福贵苦难而坚韧的一生。',NOW(),NOW());

-- 借阅记录测试数据 (为 admin/zhangsan 等预置部分记录)
INSERT INTO `borrow_record` (`user_id`,`book_id`,`borrow_time`,`return_time`,`status`,`remark`,`create_time`) VALUES
(2,1,NOW(),NULL,'借阅中',NULL,NOW()),
(2,5,NOW(),NULL,'借阅中',NULL,NOW()),
(3,6,NOW(),NULL,'已归还',NULL,NOW()),
(3,8,NOW(),NULL,'待审核',NULL,NOW()),
(2,9,DATE_SUB(NOW(), INTERVAL 30 DAY),DATE_SUB(NOW(), INTERVAL 5 DAY),'已归还',NULL,DATE_SUB(NOW(), INTERVAL 30 DAY)),
(3,10,DATE_SUB(NOW(), INTERVAL 20 DAY),NULL,'驳回','库存不足，暂不外借',DATE_SUB(NOW(), INTERVAL 20 DAY));

-- 同步图书已借出数量(borrow_num 只统计当前"借阅中"的数量; 已归还/驳回/待审核不计入)
UPDATE `book` SET `borrow_num`=1 WHERE `id`=1;
UPDATE `book` SET `borrow_num`=1 WHERE `id`=5;
-- id=6(三国演义)的记录为"已归还", borrow_num 应为 0, 无需更新

-- ============================================================
-- 账号说明:
--   管理员: admin / 123456
--   普通用户: zhangsan / 123456  或  lisi / 123456
-- 密码均为 123456 (BCrypt 加密后存储)
-- ============================================================
