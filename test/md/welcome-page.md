# 🎓 嵌入式智控协会

<div class="feature-badges">
  <span class="badge new">新功能 v2.1</span>
  <span class="badge mobile-optimized">移动端优化</span>
</div>

## 🚀 快速开始
<div class="quick-start-grid">
  <div class="step-card">
    <i class="icon">📚</i>
    <h3>打开目录</h3>
    <p>点击右下角悬浮按钮浏览课程体系</p>
  </div>
  
  <div class="step-card">
    <i class="icon">🔍</i>
    <h3>智能搜索</h3>
    <p>输入关键词快速定位内容</p>
  </div>
</div>

## 🌟 核心功能
```mermaid
graph TD
  A[编程基础] --> B(C语言)
  A --> C(Python)
  D[硬件知识] --> E(电路基础)
  D --> F(MCU架构)
  G[开发实战] --> H(STM32)
  G --> I(OpenCV)
  click B "javascript:loadCourse('C语言')"
```

## 🛠 技术架构
| 模块       | 技术栈                | 版本     |
|------------|----------------------|----------|
| 前端框架   | HTML5/CSS3/ES6       | 2023标准 |
| 解析引擎   | Marked.js + Prism    | v5.0.2   |
| 可视化     | Mermaid              | v9.1.3   |
| 交互系统   | 原生JavaScript       | ES2022   |

<div class="mobile-features">
  <div class="feature-tag">
    <i class="material-icons">touch_app</i>
    <span>手势操作支持</span>
  </div>
  <div class="feature-tag">
    <i class="material-icons">animation</i>
    <span>60fps流畅动画</span>
  </div>
</div>

## 📖 操作指南（全平台通用）

<div class="operation-manual">

### 🧭 基本导航
<div class="step-cards">
  <div class="step-card">
    <i class="icon">📂</i>
    <h4>目录访问</h4>
    <ul>
      <li>PC端：侧边栏常驻</li>
      <li>移动端：右下角悬浮按钮</li>
    </ul>
  </div>
</div>

### ✨ 核心交互
<div class="feature-list">
  <div class="feature-item">
    <i class="icon">👆</i>
    <div>
      <strong>内容选择</strong>
      <p>单击条目查看详情<br>双击章节标题快速定位</p>
    </div>
  </div>
  
  <div class="feature-item">
    <i class="icon">🖱️</i>
    <div>
      <strong>快捷操作</strong>
      <p>长按目录项 2秒 添加书签<br>右键/长按图表可导出图片</p>
    </div>
  </div>
</div>

### 📱 设备适配
| 操作类型 | 移动端交互       | PC端交互        |
|----------|------------------|-----------------|
| 缩放     | 双指捏合         | Ctrl+鼠标滚轮   |
| 滚动     | 单指滑动         | 鼠标滚轮        |
| 返回     | 底部导航按钮     | 浏览器返回按钮  |

### 🔍 搜索技巧
```mermaid
flowchart TD
  A[启动搜索] --> B{精确搜索?}
  B -->|是| C["使用引号包裹关键词"]
  B -->|否| D["输入自然语言描述"]
  C --> E[查看高亮结果]
  D --> E
```

</div>

> ✅ 注意事项：<br>
> 1. 首次使用建议完成5分钟引导教程<br>
> 2. 手势操作需保持触控区域清洁<br>
> 3. 复杂图表操作建议横屏使用

> 📍 使用贴士：长按目录项可添加书签，双击章节快速定位 