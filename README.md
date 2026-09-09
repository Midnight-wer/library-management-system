# 图书管理系统（毕业设计）

> 基于 Spring Boot + Vue3 前后端分离的校园图书借阅管理系统，支持普通用户与管理员双角色，覆盖图书浏览、借阅审批、归还确认、数据统计、Excel 导出等完整业务流程，可直接用于毕业设计答辩演示。

---

## 快速开始（3 步运行）

```bash
# 1. 克隆项目（GitHub / Gitee 任选其一，国内推荐 Gitee）
git clone https://gitee.com/happy-wang-jia-wei/library-management-system.git
# 或：git clone https://github.com/Midnight-wer/library-management-system.git
cd library-management-system

# 2. 导入数据库（需先启动 MySQL，账号 root 默认无密码）
mysql -u root < 数据库脚本/library.sql

# 3. 一键启动
#    Windows: 双击 一键启动.bat（或英文入口 start.bat），选择 1 开发模式 / 2 生产模式
#    Linux/macOS: chmod +x start-linux.sh && ./start-linux.sh
```

启动成功后浏览器自动打开：开发模式 http://localhost:5173 ，生产模式 http://localhost:4173

| 角色 | 账号 | 密码 |
|------|------|------|
| 管理员 | admin | 123456 |
| 普通用户 | zhangsan | 123456 |

> 环境要求：JDK 1.8+、Node.js 18+（Vite 5 要求）、MySQL 8.0（Windows 下 Maven 无需单独安装，后端自带 `mvnw.cmd`）。
> 详细环境配置、IDEA 启动、生产部署说明见下文对应章节。

---

## 一、技术栈

| 层级 | 技术 | 版本 |
|------|------|------|
| 后端框架 | Spring Boot | 2.7.18 |
| ORM | MyBatis-Plus | 3.5.3.1 |
| 数据库 | MySQL | 8.0 |
| 鉴权 | JWT (jjwt) | 0.9.1 |
| Excel 导出 | Apache POI | 4.1.2 |
| 工具类 | Hutool | 5.8.16 |
| JDK | Java | 1.8+ |
| 前端框架 | Vue 3 | 3.4.0 |
| 构建工具 | Vite | 5.0.10 |
| HTTP 库 | Axios | 1.6.2 |
| 路由 | Vue Router | 4.2.5 |
| 状态管理 | Pinia | 2.1.7 |
| UI 组件库 | Element Plus | 2.4.4 |
| 图表库 | ECharts | 5.4.3 |

---

## 二、项目目录结构

```
图书管理项目/
├── 后端服务/                       # 后端 Spring Boot 项目
│   ├── pom.xml                     # Maven 依赖
│   ├── mvnw.cmd                    # Maven Wrapper(无需全局安装 Maven)
│   └── src/main/
│       ├── java/com/library/
│       │   ├── LibraryApplication.java   # 启动类
│       │   ├── common/                   # 公共模块
│       │   │   ├── Result.java           # 统一返回结果
│       │   │   ├── BusinessException.java# 业务异常
│       │   │   ├── GlobalExceptionHandler.java # 全局异常处理
│       │   │   ├── JwtUtils.java         # JWT 工具类
│       │   │   ├── JwtInterceptor.java   # JWT 拦截器
│       │   │   ├── BaseContext.java      # 当前用户上下文
│       │   │   ├── CurrentUser.java      # 当前用户模型
│       │   │   ├── WebConfig.java         # 跨域+拦截器+静态资源
│       │   │   └── MybatisPlusConfig.java# MP 配置(分页插件)
│       │   ├── controller/              # 控制层
│       │   ├── service/                 # 业务层
│       │   ├── mapper/                  # 数据访问层
│       │   ├── entity/                  # 实体类
│       │   ├── dto/                     # 请求参数对象
│       │   └── vo/                      # 返回视图对象
│       └── resources/
│           ├── application.yml          # 应用配置
│           └── mapper/                  # MyBatis XML
├── 前端界面/                       # 前端 Vue3 项目
│   ├── package.json
│   ├── vite.config.js
│   ├── index.html
│   └── src/
│       ├── main.js                    # 入口
│       ├── App.vue
│       ├── api/                       # 接口封装
│       ├── components/                # 公共组件
│       │   ├── SearchBar.vue          # 通用搜索栏
│       │   ├── CommonTable.vue        # 通用表格
│       │   ├── ModalForm.vue          # 弹窗表单
│       │   └── StatusTag.vue          # 状态标签
│       ├── layouts/Layout.vue         # 主布局
│       ├── router/index.js            # 路由+守卫
│       ├── stores/user.js             # Pinia 用户状态
│       ├── styles/global.css
│       ├── utils/request.js           # Axios 封装
│       └── views/                     # 页面
│           ├── Login.vue / Register.vue
│           ├── BookList.vue / BookDetail.vue
│           ├── Profile.vue / NotFound.vue
│           └── admin/
│               ├── Dashboard.vue      # 后台首页(统计图表)
│               ├── BookManage.vue      # 图书管理
│               ├── CategoryManage.vue # 分类管理
│               ├── BorrowManage.vue   # 借阅记录管理
│               └── UserManage.vue      # 用户管理
├── 数据库脚本/
│   └── library.sql                 # 完整数据库脚本(建表+测试数据)
├── 一键启动.bat                     # Windows 一键启动(开发/生产模式可选)
├── 一键停止.bat                     # Windows 一键停止前后端服务
├── start.bat / stop.bat            # 等价英文入口(兼容中文文件名敏感环境)
├── start-linux.sh                  # Linux/macOS 启动脚本
├── stop-linux.sh                   # Linux/macOS 停止脚本
├── 启动问题排查报告.md               # 启动脚本缺陷排查与修复记录
└── README.md                        # 本文档
```

---

## 三、环境准备

### 3.1 必备软件版本

| 软件 | 版本要求 | 说明 |
|------|---------|------|
| JDK | 1.8 及以上 | 推荐 JDK 8 或 JDK 17 |
| Maven | 3.6+ | 后端依赖管理；Windows 下可用后端目录自带的 `mvnw.cmd` 免安装 |
| Node.js | 18 及以上 | Vite 5 要求，推荐 18 LTS 或 20 LTS |
| MySQL | 8.0 | 数据库 |
| IDEA / VSCode | 任意版本 | 开发工具 |

### 3.2 验证环境

```bash
# 验证 Java
java -version

# 验证 Maven
mvn -version

# 验证 Node
node -v
npm -v

# 验证 MySQL
mysql --version
```

### 3.3 一键启动（推荐）

无需手动执行下文第四、五、六节的分步操作，直接双击根目录的 **`一键启动.bat`**：

| 模式 | 说明 | 前端访问 |
|------|------|---------|
| 开发模式 | 后端 Maven 热编译运行 + 前端 Vite 热更新 | http://localhost:5173 |
| 生产模式 | 后端运行打包好的 Jar + 前端构建产物预览 | http://localhost:4173 |

脚本会自动完成：Java / Node.js / MySQL 环境检查（MySQL 未运行会尝试自动启动）→ 后端编译(生产模式首次) → 前端依赖安装(首次) → 启动服务 → 探测服务就绪 → 自动打开浏览器。每个步骤都有明确的 `[通过] / [失败] / [等待]` 状态反馈，服务就绪判定超时为 90 秒。

停止服务：双击 **`一键停止.bat`**（仅停止前后端，不影响 MySQL）。

> 若系统对中文文件名敏感，可使用等价的英文入口 **`start.bat` / `stop.bat`**。
> 注意：这 4 个 bat 文件必须以 **GBK(ANSI) 编码 + CRLF 行尾** 保存，修改时勿转为 UTF-8，否则双击会乱码闪退（详见《启动问题排查报告.md》）。

Linux/macOS 用户使用 `start-linux.sh` 与 `stop-linux.sh`。

---

## 四、数据库初始化

### 4.1 执行 SQL 脚本

方式一（命令行，默认 root 无密码）：

```bash
# 在项目根目录执行（脚本自带 CREATE DATABASE / USE，无需手动建库）
mysql -u root < 数据库脚本/library.sql

# 若你的 MySQL 设置了密码，改用：
# mysql -u root -p < 数据库脚本/library.sql
```

方式二（图形化工具 Navicat / DataGrip / MySQL Workbench）：

1. 连接本地 MySQL（默认账号 `root`，密码为空）。
2. 打开 `数据库脚本/library.sql` 文件，全选执行。

### 4.2 默认账号

脚本执行完成后，自带如下测试账号（密码统一为 `123456`）：

| 账号 | 密码 | 角色 |
|------|------|------|
| admin | 123456 | 管理员 |
| zhangsan | 123456 | 普通用户 |
| lisi | 123456 | 普通用户 |

> 已预置：6 个图书分类、15 本图书、6 条借阅记录（覆盖待审核/借阅中/已归还/驳回四种状态）。

### 4.3 数据库连接配置

本项目默认 MySQL 账号为 `root`，密码为空。如本地 MySQL 配置不同，请修改：

文件：`后端服务/src/main/resources/application.yml`

```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/library_db?useUnicode=true&characterEncoding=utf-8&useSSL=false&serverTimezone=Asia/Shanghai&allowPublicKeyRetrieval=true
    username: root      # 修改为实际账号
    password:           # 修改为实际密码（本项目默认为空）
```

> 同时同步修改 `start-linux.sh` 脚本中的 `mysql -u root` 命令为 `mysql -u root -p你的密码`。

---

## 五、后端启动步骤

### 5.1 配置说明

后端默认配置（`application.yml`）：

| 配置项 | 默认值 | 说明 |
|--------|--------|------|
| server.port | 8080 | 后端服务端口 |
| context-path | /api | 接口统一前缀 |
| 数据库 | library_db | MySQL 数据库名 |
| JWT 过期时间 | 24 小时 | Token 有效期 |
| 文件上传目录 | ./uploads | 服务端本地保存 |
| 文件访问路径 | /uploads/** | 静态资源映射 |

### 5.2 IDEA 启动（推荐）

1. 用 IDEA 打开 `backend` 目录，识别为 Maven 项目。
2. 等待 Maven 自动下载依赖（首次较慢，需联网）。
3. 找到启动类 `com.library.LibraryApplication`，右键 `Run 'LibraryApplication'`。
4. 控制台出现 `Started LibraryApplication in xxx seconds` 即启动成功。
5. 访问接口基址：`http://localhost:8080/api`。

### 5.3 命令行启动

```bash
# 进入后端目录
cd 后端服务

# 编译打包(跳过测试)
mvn clean package -DskipTests

# 运行 jar
java -jar target/library-admin-1.0.0.jar
```

### 5.4 验证后端

浏览器访问：

```
http://localhost:8080/api/user/login
```

返回 JSON（如 405 或参数校验提示，说明服务已运行）即代表后端正常。

---

## 六、前端启动步骤

### 6.1 安装依赖

```bash
# 进入前端目录
cd 前端界面

# 安装依赖(首次较慢,建议使用淘宝镜像)
npm install --registry=https://registry.npmmirror.com
```

### 6.2 开发模式启动

```bash
npm run dev
```

启动后浏览器自动打开 `http://localhost:5173`，并自动重定向到登录页。

> Vite 已配置代理：`/api` 与 `/uploads` 均转发到 `http://localhost:8080`，故**必须先启动后端再启动前端**。

### 6.3 生产构建

```bash
# 构建生产包
npm run build

# 预览构建产物(端口 4173, 已配置后端代理)
npm run preview
```

构建产物位于 `前端界面/dist/`，可部署至 Nginx 等 Web 服务器。

---

## 七、部署说明

### 7.1 单机部署（开发/演示）

1. 启动 MySQL，执行 `数据库脚本/library.sql`。
2. 启动后端 Spring Boot 服务（端口 8080）。
3. 启动前端 Vite 开发服务（端口 5173）。
4. 浏览器访问 `http://localhost:5173`。

> Windows 下可直接双击 `一键启动.bat` 完成以上 2-4 步。

### 7.2 生产部署（Nginx + Jar）

**后端打包：**

```bash
cd 后端服务
mvn clean package -DskipTests
# 产物: 后端服务/target/library-admin-1.0.0.jar
nohup java -jar target/library-admin-1.0.0.jar > nohup.out 2>&1 &
```

**前端打包：**

```bash
cd 前端界面
npm install
npm run build
# 产物: 前端界面/dist/
```

**Nginx 配置示例**（`/etc/nginx/conf.d/library.conf`）：

```nginx
server {
    listen       80;
    server_name  localhost;

    # 前端静态资源
    location / {
        root   /usr/local/nginx/html/library-dist;
        index  index.html;
        try_files $uri $uri/ /index.html;
    }

    # 后端 API 代理
    location /api/ {
        proxy_pass http://127.0.0.1:8080/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    # 上传文件访问代理
    location /uploads/ {
        proxy_pass http://127.0.0.1:8080/uploads/;
    }
}
```

将 `前端界面/dist/` 内容拷贝到 `/usr/local/nginx/html/library-dist/`，重启 Nginx 即可。

### 7.3 文件上传目录

后端默认把上传的文件保存在运行目录的 `./uploads/`，生产环境如需固定路径，请修改：

```yaml
file:
  upload-dir: /data/library/uploads
  access-path: /uploads/**
```

---

## 八、核心业务流程

### 8.1 借阅状态流转

```
用户提交借阅申请
       │
       ▼
   【待审核】
       │
       ├─管理员通过──►【借阅中】──管理员确认归还──►【已归还】
       │
       └─管理员驳回──►【驳回】（填写驳回备注）
```

### 8.2 借阅/归还的库存同步

- 审核通过：图书 `borrow_num + 1`（已借出数 +1），事务保证与借阅记录状态变更一致。
- 确认归还：图书 `borrow_num - 1`（已借出数 -1），同时写回 `return_time`。
- 校验：借阅前判断库存是否充足，避免超借。

---

## 九、接口清单（RESTful）

接口统一前缀：`/api`

### 用户模块

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| POST | /user/register | 注册 | 公开 |
| POST | /user/login | 登录返回 token | 公开 |
| GET  | /user/info | 获取当前登录用户 | 登录 |
| PUT  | /user/info | 修改个人资料 | 登录 |
| PUT  | /user/password | 修改密码 | 登录 |
| GET  | /user/list | 用户分页搜索 | admin |
| PUT  | /user/{id} | 编辑用户 | admin |
| DELETE | /user/{id} | 删除用户 | admin |

### 图书模块

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| GET | /book/list | 图书分页搜索 | 登录 |
| GET | /book/{id} | 图书详情 | 登录 |
| POST | /book | 新增图书 | admin |
| PUT | /book/{id} | 编辑图书 | admin |
| DELETE | /book/{id} | 删除图书 | admin |

### 图书分类模块

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| GET | /category/list | 全部分类 | 登录 |
| POST | /category | 新增分类 | admin |
| PUT | /category/{id} | 编辑分类 | admin |
| DELETE | /category/{id} | 删除分类 | admin |

### 借阅模块

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| POST | /borrow | 提交借阅申请 | user |
| GET | /borrow/my | 我的借阅分页 | user |
| GET | /borrow/list | 全部借阅分页 | admin |
| PUT | /borrow/{id}/audit | 审核(通过/驳回) | admin |
| PUT | /borrow/{id}/return | 确认归还 | admin |
| GET | /borrow/export | 导出借阅 Excel | admin |

### 统计 & 文件

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| GET | /statistics/home | 后台首页统计 | admin |
| POST | /file/upload | 文件上传 | 登录 |

### 统一返回结构

```json
{
  "code": 200,
  "message": "success",
  "data": {}
}
```

约定：`200` 成功；`401` 未登录/Token 失效；`403` 权限不足；`500` 业务异常。

---

## 十、演示验收流程

> 以下流程为系统必须跑通的最小验收闭环，按步骤操作即可完成全功能演示。

### 步骤 1：账号准备

- 管理员账号：`admin / 123456`（脚本自带）
- 普通用户账号：`zhangsan / 123456`（脚本自带）
- 或自行通过注册页注册一个新的普通用户账号

### 步骤 2：普通用户提交借阅申请

1. 使用普通用户 `zhangsan` 登录系统。
2. 进入「图书列表」页，搜索/浏览图书。
3. 点击某本图书进入「图书详情」页。
4. 点击「提交借阅申请」按钮，提示申请已提交。
5. 进入「个人中心」页，查看「我的借阅记录」。
6. 确认新记录状态为 **待审核**。

### 步骤 3：管理员审核借阅申请

1. 退出普通用户，使用管理员 `admin` 登录。
2. 进入「借阅管理」页面，看到刚才的待审核申请。
3. 点击「通过」按钮，审核通过。
4. 进入「后台首页」，查看 ECharts 统计图表与统计卡片。
5. 在「借阅管理」页点击「导出 Excel」，下载借阅记录文件。
6. 进入「图书管理」页面，点击「新增图书」，填写信息并保存。

### 步骤 4：普通用户查看借阅状态变更

1. 切回普通用户 `zhangsan` 登录。
2. 进入「个人中心」，查看「我的借阅记录」。
3. 确认刚才的借阅状态已变为 **借阅中**。

### 步骤 5：管理员确认归还

1. 切回管理员 `admin` 登录。
2. 进入「借阅管理」，找到借阅中状态的记录。
3. 点击「确认归还」按钮，归还成功。
4. 切回普通用户 `zhangsan`，刷新「我的借阅记录」。
5. 确认记录状态已更新为 **已归还**。

至此，全部业务流程闭环演示完成。

---

## 十一、验收检查清单

> 以下逐条对照需求文档，全部已实现。

### 后端强制要求

- [x] 统一返回 JSON 结构 `{code, message, data}`
- [x] 约定 code：200/401/403/500
- [x] 全局统一异常处理器（参数校验、业务异常、权限不足）
- [x] JWT 鉴权（仅登录/注册放行）
- [x] Token 有效性 + 角色权限校验
- [x] 普通用户不能调用管理员接口
- [x] 跨域配置类
- [x] 文件上传接口（头像、图书封面，保存服务器本地）

### 数据库

- [x] user 表（id/username/password/nickname/phone/avatar/role/create_time/update_time）
- [x] book 表（id/book_name/author/isbn/category_id/cover/total_num/borrow_num/introduction/create_time/update_time）
- [x] book_category 表（id/category_name/create_time）
- [x] borrow_record 表（id/user_id/book_id/borrow_time/return_time/status/remark/create_time）
- [x] 初始化管理员账号 + 若干图书/分类测试数据

### 接口清单

- [x] 用户模块 8 个接口
- [x] 图书模块 5 个接口
- [x] 图书分类模块 4 个接口
- [x] 借阅模块 5 个接口
- [x] 统计 & 文件 2 个接口（含 Excel 导出）

### 业务逻辑

- [x] 借阅状态流转：待审核 → 借阅中 / 驳回（驳回备注）→ 已归还
- [x] 借阅/归还同步维护图书库存（borrow_num）
- [x] 数据库事务保证数据一致性

### 前端强制要求

- [x] Vue Router 路由守卫登录拦截
- [x] 角色路由控制（普通用户访问管理员页面拦截提示）
- [x] 未登录跳转登录页
- [x] Axios 请求拦截自动带上 token
- [x] Axios 响应拦截统一错误提示
- [x] Token 过期跳转登录
- [x] Pinia 全局状态管理（token、用户信息）

### 公共可复用组件

- [x] SearchBar 通用搜索栏（搜索输入、筛选下拉、查询重置按钮）
- [x] CommonTable 通用表格（分页、插槽操作栏）
- [x] ModalForm 弹窗表单（新增编辑弹窗、表单插槽）
- [x] StatusTag 状态标签（借阅状态展示）

### 全部页面

- [x] 登录/注册页（表单校验）
- [x] 图书列表页（搜索、分页、封面展示、用户可发起借阅）
- [x] 图书详情页（完整信息、可提交借阅申请）
- [x] 个人中心页（修改昵称/手机号/头像上传、修改密码、我的借阅记录分页搜索）
- [x] 管理员后台首页（ECharts 图表、统计卡片）
- [x] 图书管理页面（分页搜索、新增编辑弹窗、封面上传、删除）
- [x] 图书分类管理页面（增删改查）
- [x] 借阅记录管理页面（审核、驳回备注、确认归还、导出 Excel）
- [x] 用户管理页面（分页搜索、编辑、删除）
- [x] 按钮级别权限控制（管理员才显示新增/编辑/删除/导出按钮）

### 加分项（必须完成）

- [x] Pinia 全局状态管理（前端）
- [x] 文件上传（头像、图书封面）
- [x] Excel 导出借阅记录（管理员）
- [x] ECharts 统计图表后台展示

### 交付文件

- [x] SpringBoot 后端完整项目代码
- [x] Vue3 前端完整项目代码
- [x] mysql.sql 完整数据库脚本（建表 + 初始化测试数据）
- [x] README.md 文档（环境版本、启动步骤、部署说明）
- [x] 项目目录结构完整，代码注释清晰

### 演示验收流程

- [x] 注册/使用两个账号（普通用户、管理员）
- [x] 普通用户提交借阅申请 → 状态为待审核
- [x] 管理员审核通过、查看统计图表、导出 Excel、新增图书
- [x] 普通用户借阅状态变为借阅中
- [x] 管理员确认归还 → 普通用户记录更新为已归还

---

## 十二、常见问题

**Q1：启动后端报错数据库连接失败？**
A：检查 MySQL 是否启动、`library_db` 是否已创建、`application.yml` 中 `username/password` 是否与本地一致（本项目默认 `root` + 空密码）。

**Q2：前端登录提示跨域错误？**
A：确认后端已启动且监听 8080 端口；Vite 已配置代理，开发模式不要直接访问 8080，应访问 5173。

**Q3：上传的头像/封面打不开？**
A：上传接口返回的访问路径形如 `/api/uploads/yyyy/MM/dd/xxx.jpg`，通过前端访问为 `http://localhost:5173/api/uploads/xxx.jpg`（开发模式，Vite 代理）或 `http://localhost:4173/api/uploads/xxx.jpg`（生产预览）；直连后端为 `http://localhost:8080/api/uploads/xxx.jpg`。注意路径中必须包含 `/api` 前缀。

**Q4：Token 过期如何处理？**
A：默认 24 小时有效期，过期后响应拦截器自动跳转登录页，重新登录即可。

**Q5：Excel 导出乱码或下载失败？**
A：浏览器需允许弹窗/下载，导出接口返回 `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet` 类型。

---

## 十三、项目说明

- 本项目所有代码均在本地，不依赖外部云服务，可拷贝至任意电脑运行。
- 数据库脚本 `数据库脚本/library.sql` 包含完整建表语句与初始化测试数据，开箱即用。
- 密码采用 BCrypt 加密存储，密文均对应明文 `123456`。
- 项目可直接用于毕业设计答辩演示，禁止新增文档以外功能，禁止删减需求。
