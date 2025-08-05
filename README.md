# MoonProgress

🌙 **MoonProgress** - 专为 MoonBit 语言设计的简洁实用命令行进度条库

[![MoonBit](https://img.shields.io/badge/MoonBit-Latest-blue)](https://moonbitlang.com)
[![License](https://img.shields.io/badge/License-Apache--2.0-green)](LICENSE)

## ✨ 特性

- 🎯 **简洁实用** - 专注核心功能，5种精选样式，零冗余
- ⚡ **高性能** - 优化的渲染算法，最小化性能开销
- 🔧 **灵活配置** - 支持链式配置，自定义所有显示参数
- 📊 **智能显示** - ETA预估、速率显示、计数器、百分比
- 🌐 **兼容性强** - 纯ASCII/Unicode字符，兼容所有终端
- 🎯 **易于集成** - 简洁的API设计，零依赖，开箱即用
- ⏱️ **智能时间跟踪** - 实时速率计算、精确ETA预估、平滑更新
- 📏 **动态宽度适配** - 自动检测终端宽度，智能调整进度条长度
- 🔗 **嵌套进度条** - 支持多层级进度条管理，完美处理复杂任务

## 🚀 快速开始

### 安装和配置

1. **添加依赖**：在你的项目的 `moon.pkg.json` 中添加：
```json
{
  "import": [
    "CGaaaaaa/MoonProgress/src"
  ]
}
```

2. **导入使用**：在你的 MoonBit 代码中：
```moonbit
// 创建进度条
let pb = @CGaaaaaa/MoonProgress.new(100)
let result = pb.update(50).render()
println(result)
```

### 基本使用方法

#### 1. 最简单的用法
```moonbit
// 创建总数为100的进度条，当前进度50
let pb = @CGaaaaaa/MoonProgress.new(100).update(50)
println(pb.render())
// 输出: 50%|[█████████████████████████                         ]
```

#### 2. 带描述和百分比
```moonbit
let pb = @CGaaaaaa/MoonProgress.new(100)
  .update(75)
  .set_desc("下载文件")
  .set_show_percent(true)
println(pb.render())
// 输出: 下载文件: 75%|[█████████████████████████████████████             ]
```

#### 3. 显示计数
```moonbit
let pb = @CGaaaaaa/MoonProgress.new(100)
  .update(30)
  .set_desc("处理")
  .set_show_count(true)
  .set_show_percent(true)
println(pb.render())
// 输出: 处理: 30%|[███████████████                                   ] 30/100
```

#### 4. 自定义样式
```moonbit
let pb = @CGaaaaaa/MoonProgress.new(50)
  .update(30)
  .set_fill('#')          // 设置填充字符
  .set_empty('-')         // 设置空白字符
  .set_show_percent(true)
println(pb.render())
// 输出: 60%|[##############################--------------------]
```

#### 5. 设置宽度
```moonbit
let pb = @CGaaaaaa/MoonProgress.new(50)
  .update(30)
  .set_width(20)          // 设置进度条宽度为20
  .set_show_percent(true)
println(pb.render())
// 输出: 60%|[████████████        ]
```

#### 6. 前缀和后缀
```moonbit
let pb = @CGaaaaaa/MoonProgress.new(50)
  .update(30)
  .set_prefix("开始")     // 设置前缀
  .set_suffix("结束")     // 设置后缀
  .set_show_percent(true)
println(pb.render())
// 输出: 开始 60%|[██████████████████████████████                    ] 结束
```

### 在循环中使用

```moonbit
let pb = @CGaaaaaa/MoonProgress.new(100).set_desc("处理").set_show_percent(true)

for i = 0; i <= 100; i = i + 10 {
  let rendered = pb.update(i).render()
  println(rendered)
  // 在实际应用中，这里可以添加你的业务逻辑
}
```

输出效果：
```
处理: 0%|[                                                  ] 
处理: 10%|[█████                                             ] 
处理: 20%|[██████████                                        ] 
...
处理: 100%|[██████████████████████████████████████████████████] 
```

## 📊 样式选择

提供5种实用样式：**Default**（█）、**Block**（█░）、**Arrow**（>-）、**Dots**（●○）、**Hash**（#-）

## 🔧 配置选项

### 核心布尔配置

```moonbit
let config = @CGaaaaaa/MoonProgress.create_config(
  50,      // 宽度
  "开始",   // 前缀  
  "结束",   // 后缀
  '█',     // 填充字符
  ' ',     // 空白字符
  true,    // 显示百分比
  true,    // 显示计数
  true,    // 显示ETA
  true,    // 显示速率
  false,   // 显示已用时间
  true,    // 动态宽度
  true,    // 平滑更新
  // ... 其他参数
)
```

### 创建方式

```moonbit
// 基本创建
let pb = @CGaaaaaa/MoonProgress.new(100)

// 使用样式创建
let pb = @CGaaaaaa/MoonProgress.new_with_style(100, @CGaaaaaa/MoonProgress.Block)

// 使用自定义配置创建
let pb = @CGaaaaaa/MoonProgress.new_with_config(100, config)
```

### 链式配置

```moonbit
let pb = @CGaaaaaa/MoonProgress.new(100)
  .set_desc("处理文件")           // 设置描述文字
  .set_unit("MB")                // 设置单位
  .set_prefix("进度")            // 设置前缀
  .set_suffix("已完成")          // 设置后缀
  .set_show_percent(true)        // 显示百分比
  .set_show_count(true)          // 显示计数
  .set_show_rate(true)           // 显示速率
  .set_width(50)                 // 设置进度条宽度
  .update(75)                    // 更新进度
```

### 可用方法

#### 创建方法
- `new(total: Int) -> ProgressBar` - 创建基本进度条
- `new_with_style(total: Int, style: ProgressStyle) -> ProgressBar` - 使用指定样式创建

#### 常用配置选项（支持链式调用）

| 方法 | 说明 | 示例 |
|------|------|------|
| `set_desc(desc)` | 设置描述文本 | `.set_desc("下载")` |
| `set_show_percent(bool)` | 显示百分比 | `.set_show_percent(true)` |
| `set_show_count(bool)` | 显示计数 | `.set_show_count(true)` |
| `set_show_rate(bool)` | 显示速率 | `.set_show_rate(true)` |
| `set_show_eta(bool)` | 显示ETA | `.set_show_eta(true)` |
| `set_unit(unit)` | 设置单位 | `.set_unit("MB")` |
| `set_width(width)` | 设置进度条宽度 | `.set_width(30)` |
| `set_prefix(text)` | 设置前缀 | `.set_prefix("开始")` |
| `set_suffix(text)` | 设置后缀 | `.set_suffix("完成")` |

#### 更新和渲染
- `update(current: Int) -> ProgressBar` - 更新当前进度
- `render() -> String` - 渲染为字符串
- `percentage() -> Double` - 获取百分比

#### 高级功能方法
- `increment() -> ProgressBar` - 增加1个进度
- `increment_by(amount: Int) -> ProgressBar` - 增加指定数量的进度
- `reset_progress() -> ProgressBar` - 重置进度条
- `close() -> ProgressBar` - 关闭进度条
- `set_total(new_total: Int) -> ProgressBar` - 设置新的总数
- `set_dynamic_width(dynamic: Bool) -> ProgressBar` - 设置动态宽度
- `set_ncols(ncols: Option[Int]) -> ProgressBar` - 设置终端列数
- `set_miniters(miniters: Int) -> ProgressBar` - 设置最小更新间隔
- `set_mininterval(mininterval: Double) -> ProgressBar` - 设置最小时间间隔
- `set_unit_scale(unit_scale: Bool) -> ProgressBar` - 设置单位缩放
- `set_position(position: Int) -> ProgressBar` - 设置嵌套位置

## 📖 使用场景

### 文件下载
```moonbit
let pb = @CGaaaaaa/MoonProgress.new_with_style(file_size, @CGaaaaaa/MoonProgress.Block)
  .set_desc("下载")
  .set_unit("MB")
  .set_show_percent(true)
  .set_show_rate(true)

// 在下载循环中
for downloaded in download_chunks {
  let updated = pb.update(downloaded)
  println(updated.render())
}
```

### 数据处理
```moonbit
let pb = @CGaaaaaa/MoonProgress.new_with_style(total_records, @CGaaaaaa/MoonProgress.Arrow)
  .set_desc("处理数据")
  .set_unit("records")
  .set_show_count(true)
  .set_show_eta(true)

for i in 0..total_records {
  // 处理数据...
  if i % 100 == 0 {  // 每100条记录更新一次
    let updated = pb.update(i)
    println(updated.render())
  }
}
```

### 测试执行
```moonbit  
let pb = @CGaaaaaa/MoonProgress.new_with_style(test_count, @CGaaaaaa/MoonProgress.Dots)
  .set_desc("运行测试")
  .set_prefix("测试进度")
  .set_show_percent(true)

for test in tests {
  // 运行测试...
  let updated = pb.update(completed_tests)
  println(updated.render())
  completed_tests = completed_tests + 1
}
```

## 🚀 高级功能

### 智能时间跟踪和ETA预估

```moonbit
let pb = @MoonProgress.new(1000)
  .set_desc("数据处理")
  .set_show_rate(true)    // 显示处理速率
  .set_show_eta(true)     // 显示预计剩余时间
  .set_smooth(true)       // 启用平滑更新

// 在处理循环中
for i in 0..1000 {
  // 处理数据...
  let updated = pb.update(i)
  println(updated.render())  // 实时显示: 速率 + ETA
}
```

### 动态终端宽度适配

```moonbit
let pb = @CGaaaaaa/MoonProgress.new(100)
  .set_desc("自适应进度条")
  .set_dynamic_width(true)  // 启用动态宽度
  .set_ncols(None)          // 自动检测终端宽度
  .set_show_percent(true)
  .set_show_count(true)
  .update(50)

// 进度条会根据终端宽度自动调整长度
println(pb.render())
```

### 嵌套进度条管理

```moonbit
// 创建嵌套进度条管理器
let manager = @CGaaaaaa/MoonProgress.create_nested_manager()

// 主任务进度条
let main_task = @CGaaaaaa/MoonProgress.new(5)
  .set_position(0)
  .set_desc("主任务: 处理文件批次")
  .set_show_percent(true)
  .update(3)

// 子任务进度条
let sub_task1 = @CGaaaaaa/MoonProgress.new(100)
  .set_position(1)
  .set_desc("  └─ 处理文件1")
  .set_show_percent(true)
  .update(100)  // 已完成

let sub_task2 = @CGaaaaaa/MoonProgress.new(100)
  .set_position(2)
  .set_desc("  └─ 处理文件2")
  .set_show_percent(true)
  .update(45)   // 进行中

// 添加到管理器并渲染
let nested = manager
  .add_progress_bar(main_task)
  .add_progress_bar(sub_task1)
  .add_progress_bar(sub_task2)

println(nested.render_nested())
// 输出:
// 主任务: 处理文件批次: 60%|[██████████████████████████████        ] 3/5
//   └─ 处理文件1: 100%|[██████████████████████████████████████████] 100/100
//   └─ 处理文件2: 45%|[██████████████████████                    ] 45/100
```

### 增量操作和精确控制

```moonbit
let mut pb = @CGaaaaaa/MoonProgress.new(100)
  .set_desc("增量处理")
  .set_show_count(true)
  .set_miniters(5)        // 最小更新间隔：5个项目
  .set_mininterval(0.1)   // 最小时间间隔：0.1秒

// 增量操作
pb = pb.increment()           // +1
pb = pb.increment_by(10)      // +10
pb = pb.update(50)            // 直接设置为50

// 批量处理时的智能更新
for item in large_dataset {
  // 处理项目...
  pb = pb.increment()
  
  // 只有满足间隔条件时才会真正更新显示
  println(pb.render())
}
```

## 🎯 设计理念

MoonProgress 秉承"**简洁而不简单**"的设计理念：

- ✅ **专注核心功能** - 只提供最实用的进度条功能
- ✅ **精选样式** - 5种经过精心挑选的样式，覆盖所有常见需求
- ✅ **兼容优先** - 使用标准ASCII/Unicode字符，确保广泛兼容性
- ✅ **性能优化** - 最小化资源消耗，适合各种场景
- ✅ **易于使用** - 链式API设计，直观易懂

相比其他复杂的进度条库，MoonProgress专注于提供：
- 🎯 足够而不过度的功能
- 🚀 出色的性能表现  
- 🔧 简洁的API设计
- 📖 清晰的文档说明

## 📝 许可证

本项目采用 Apache-2.0 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

---

**让命令行程序更加友好！** 🌙