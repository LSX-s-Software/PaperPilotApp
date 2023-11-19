# PaperPilot App

![macOS 14.0+](https://img.shields.io/badge/macOS-14.0%2B-ffffff) ![iPadOS 17.0+](https://img.shields.io/badge/iPadOS-17.0%2B-ffffff) ![visionOS 1.0+](https://img.shields.io/badge/visionOS-1.0%2B-ffffff) ![Swift 5.9+](https://img.shields.io/badge/Swift-5.9%2B-F05138) ![gRPC](https://img.shields.io/badge/gRPC-proto3-2ca1aa)

![wakatime](https://wakatime.com/badge/user/271fef5a-1d0a-45c6-a8f0-9fb67a1417b6/project/c213100d-56fa-45ff-8ade-7c744cf7f708.svg) + ![wakatime](https://wakatime.com/badge/user/271fef5a-1d0a-45c6-a8f0-9fb67a1417b6/project/018b704b-24a1-4f1c-ae04-fae191ff7dc8.svg)

基于 SwiftUI 的多平台多人协作文献管理软件

**100% 原生，不含任何网页、JavaScript 等代码**

## 核心功能

> 功能正在开发中

- [ ] 文献管理
  - [x] 通过文献的元数据查询文献
  - [ ] 自动识别文献的元数据并归类
- [x] 跨平台、跨设备访问
  - [x] 在电脑、平板等设备上查看文献
  - [x] 数据多端同步
- [x] 多人协同阅读
  - [x] **实时同步**富文本笔记
  - [x] **实时同步**论文批注
- [x] AI 协助阅读
  - [x] 论文划词翻译
  - [x] 论文解析、总结、重写
  - [x] 可引用论文内容、保留上下文的自由聊天

更多功能详见[完整功能列表](#完整功能列表)


## 支持的平台

- macOS 14.0+
- iPadOS 17.0+
- visionOS 1.0+

## 开发要求

- macOS 14.0+
- Xcode 15.0+
- [protoc、protoc-gen-swift、protoc-gen-grpc-swift](https://github.com/grpc/grpc-swift#getting-the-protoc-plugins)

## 完整功能列表

### 项目

- 本地项目
  - 无需注册、可完全离线使用
  - 将本地项目转换为远程项目
- 远程项目
  - 部分功能可离线使用
  - 自动同步项目更改、自动解决冲突
  - 通过邀请码、链接邀请他人加入项目
  - 通过输入邀请码加入他人创建的项目
  - 通过分享链接在网页上查看邀请信息、打开 Paper Pilot 并自动填写邀请码
  - 分享链接支持 [Open Graph 协议](https://ogp.me/)
  - 查看项目成员列表
  - 退出加入的项目

### 论文

- 通过 URL/DOI 自动获取论文信息和 PDF 文件
- 通过本地文件添加论文
- 通过拖放、系统共享表单等方式导入 PDF 文件
- 论文列表
  - 显示论文标题、作者、出版年份、出版物、添加日期、标签、已读、状态等信息
  - 自定义列表显示内容（可隐藏、重排信息列、调整列宽度）
  - 自定义列表排序
  - 批量设置已读/未读、删除
  - 拷贝论文信息
  - 删除论文的PDF文件以释放空间

### 论文阅读器

- PDF 导航器
  - 切换导航器模式
    - PDF 大纲
    - PDF 缩略图
    - 书签
    - 隐藏
  - 根据当前页面更新导航器的高亮
  - 通过导航器快速跳转至指定页面
- PDF 阅读器
  - 矢量渲染
  - 文本选择
  - 切换阅读模式
    - 单页
    - 单页连续
    - 双页
    - 双页连续
  - 缩放
  - 链接跳转
- 标注
  - **实时同步**
  - 多种标注类型
    - 高亮
    - 下划线
    - 【仅限iPad】使用手指或 Apple Pencil 绘制标注
  - 切换标注颜色
- 笔记
  - **实时同步**
  - 自动解决冲突
  - 富文本（使用 Markdown 格式）
  - 调整字体大小
- 搜索
  - 搜索 PDF
  - 自定义搜索选项（是否区分大小写）
  - 显示搜索结果列表
  - 在 PDF 中高亮搜索结果
  - 通过回车键跳转到下一条搜索结果
- 书签
- 论文划词划句翻译
  - 自动检测语言
  - 自动删除 PDF 换行
- 阅读计时器

### AI 功能

- **AI 辅助阅读**
  - 论文解析、翻译、总结、重写
  - 聊天中引用论文内容
  - 自由聊天
  - 最多可保留最近的 10 条对话作为上下文

### 用户

- 注册登录
- 自定义头像

### 设置

- 显示服务器状态
- 查看本地文件所占空间
- 清理本地文件
- 清除所有数据

### 系统适配

- 遵循 Apple 设计风格
- 列表右键/长按菜单
- 调整侧边栏大小、隐藏侧边栏
- 通过 macOS 菜单栏和快捷键完成常用操作
- 通过拖放添加论文及 PDF 文件
- 在 iPadOS 上支持在同窗口、新窗口中打开论文阅读器
- 在 iPadOS 上使用 PencilKit 支持用 Apple Pencil 绘制标注
- 在 visionOS 上使用 Ornament 摆放论文详细信息
- 支持通过 Spotlight 搜索项目、论文
- 支持通过系统共享表单导入 PDF 文件
- 通过 URL Scheme 启动
- 深色模式
- 使用 SwiftData 进行数据持久化
- 多语言
  - 英文
  - 简体中文

### 其他

- 耗时的操作使用异步，并显示进度条/活动指示器
- 控件出现/消失时播放过渡动画
