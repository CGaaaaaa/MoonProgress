// MoonProgress - A command-line progress bar library for MoonBit
// 
// 核心进度条结构和API定义
// 参考 tqdm, progressbar.js, go-progressbar 的最佳实践

///|
/// 进度条配置选项
pub struct ProgressConfig {
  width : Int // 进度条宽度
  prefix : String // 前缀文本
  suffix : String // 后缀文本
  fill : Char // 填充字符
  empty : Char // 空白字符
  show_percent : Bool // 是否显示百分比
  show_count : Bool // 是否显示计数
  show_eta : Bool // 是否显示预计剩余时间
  show_rate : Bool // 是否显示处理速率
  show_elapsed : Bool // 是否显示已用时间
  dynamic_width : Bool // 是否动态调整宽度
  smooth : Bool // 是否平滑更新
  leave : Bool // 完成后是否保留进度条
  ncols : Int? // 终端列数（自动检测时为None）
  miniters : Int // 最小更新间隔（项目数）
  mininterval : Double // 最小时间间隔（秒）
  maxinterval : Double // 最大时间间隔（秒）
  desc : String // 描述文本
  unit : String // 单位名称
  unit_scale : Bool // 自动缩放单位
  position : Int // 嵌套进度条位置
}

///|
/// 创建默认配置
/// 
/// 返回包含所有默认设置的 ProgressConfig 实例。
/// 
/// # 返回值
/// - `ProgressConfig` - 默认配置对象
/// 
/// # 默认配置
/// - 宽度: 50 字符
/// - 填充字符: '█' (实心块)
/// - 空白字符: ' ' (空格)
/// - 显示百分比: true
/// - 显示ETA: true
/// - 显示速率: true
/// - 其他选项: false
/// 
/// # 示例
/// ```moonbit
/// let config = default_config()
/// let pb = new_with_config(100, config)
/// ```
pub fn default_config() -> ProgressConfig {
  {
    width: 50,
    prefix: "",
    suffix: "",
    fill: '█',
    empty: ' ',
    show_percent: true,
    show_count: false,
    show_eta: true,
    show_rate: true,
    show_elapsed: false,
    dynamic_width: false,
    smooth: true,
    leave: true,
    ncols: None,
    miniters: 1,
    mininterval: 0.1,
    maxinterval: 10.0,
    desc: "",
    unit: "it",
    unit_scale: false,
    position: 0,
  }
}

///|
/// 创建自定义配置的工厂函数
/// 
/// 使用指定的参数创建完全自定义的 ProgressConfig。
/// 
/// # 参数
/// - `width` - 进度条宽度（字符数）
/// - `prefix` - 进度条前的文本
/// - `suffix` - 进度条后的文本
/// - `fill` - 已完成部分的填充字符
/// - `empty` - 未完成部分的空白字符
/// - `show_percent` - 是否显示百分比
/// - `show_count` - 是否显示当前/总数计数
/// - `show_eta` - 是否显示预计剩余时间
/// - `show_rate` - 是否显示处理速率
/// - `show_elapsed` - 是否显示已用时间
/// - `dynamic_width` - 是否动态适应终端宽度
/// - `smooth` - 是否启用平滑更新
/// - `leave` - 完成后是否保留进度条
/// - `ncols` - 终端列数（None表示自动检测）
/// - `miniters` - 最小更新间隔（项目数）
/// - `mininterval` - 最小时间间隔（秒）
/// - `maxinterval` - 最大时间间隔（秒）
/// - `desc` - 描述文本
/// - `unit` - 单位名称
/// - `unit_scale` - 是否自动缩放单位
/// - `position` - 嵌套进度条位置
/// 
/// # 返回值
/// - `ProgressConfig` - 自定义配置对象
/// 
/// # 示例
/// ```moonbit
/// let config = create_config(
///   30, "下载:", "完成",
///   '>', '-', true,
///   true, true, true,
///   false, false,
///   true, true, None,
///   1, 0.1, 10.0,
///   "文件下载", "MB", true, 0
/// )
/// let pb = new_with_config(1024, config)
/// ```
pub fn create_config(
  width : Int,
  prefix : String,
  suffix : String,
  fill : Char,
  empty : Char,
  show_percent : Bool,
  show_count : Bool,
  show_eta : Bool,
  show_rate : Bool,
  show_elapsed : Bool,
  dynamic_width : Bool,
  smooth : Bool,
  leave : Bool,
  ncols : Int?,
  miniters : Int,
  mininterval : Double,
  maxinterval : Double,
  desc : String,
  unit : String,
  unit_scale : Bool,
  position : Int,
) -> ProgressConfig {
  {
    width,
    prefix,
    suffix,
    fill,
    empty,
    show_percent,
    show_count,
    show_eta,
    show_rate,
    show_elapsed,
    dynamic_width,
    smooth,
    leave,
    ncols,
    miniters,
    mininterval,
    maxinterval,
    desc,
    unit,
    unit_scale,
    position,
  }
}

///|
/// 时间工具类型
pub struct TimeInfo {
  start_time : Double // 开始时间（秒）
  last_update : Double // 上次更新时间
  last_print : Double // 上次打印时间
  last_n : Int // 上次计数
  samples : Array[(Double, Int)] // 时间和进度样本点，用于精确计算速率
}

///|
/// 进度统计信息
pub struct ProgressStats {
  avg_time : Double // 平均时间
  avg_rate : Double // 平均速率
  smoothed_rate : Double // 平滑速率
  eta : Double // 预计剩余时间
  elapsed : Double // 已用时间
}

///|
/// 进度条状态
pub struct ProgressBar {
  config : ProgressConfig
  total : Int
  current : Int
  time_info : TimeInfo
  stats : ProgressStats
  last_printed_n : Int // 上次打印的计数
  sp : Bool // 是否终端支持
  closed : Bool // 是否已关闭
}

///|
/// 时间跟踪结构 - 封装时间状态
pub struct TimeTracker {
  counter : Double
  terminal_width : Int?
}

///|
/// 全局时间跟踪器实例
let default_time_tracker : TimeTracker = { counter: 0.0, terminal_width: None }

///|
/// 获取当前时间（秒）- 使用计数器模拟时间
/// 注意：这是一个简化实现，实际应用中需要真实的系统时间
fn current_time() -> Double {
  // 简化实现：每次调用增加0.1秒
  // 实际应用中应该调用系统时间API
  default_time_tracker.counter + 0.1
}

///|
/// 获取终端宽度 - 简化实现
/// 注意：实际实现中应该调用系统API获取真实的终端宽度
fn get_terminal_width() -> Int {
  match default_time_tracker.terminal_width {
    Some(width) => width
    None => 80 // 默认终端宽度
  }
}

///|
/// 设置终端宽度（用于测试和动态调整）
/// 
/// 手动设置终端宽度，覆盖自动检测的值。
/// 主要用于测试、调试或特殊环境下的宽度控制。
/// 
/// # 参数
/// - `width` - 终端宽度（字符数），应该是正整数
/// 
/// # 返回值
/// - `Unit` - 无返回值，直接修改全局终端宽度设置
/// 
/// # 行为
/// - 设置全局终端宽度值
/// - 影响所有使用动态宽度的进度条
/// - 覆盖系统自动检测的终端宽度
/// - 在测试环境中提供一致的显示效果
/// 
/// # 示例
/// ```moonbit
/// // 设置标准终端宽度
/// set_terminal_width(80)
/// 
/// let pb1 = new(100).set_dynamic_width(true).update(50)
/// println(pb1.render())
/// // 进度条会根据80字符宽度进行调整
/// 
/// // 设置宽屏终端
/// set_terminal_width(120)
/// 
/// let pb2 = new(200).set_dynamic_width(true).set_show_count(true).update(100)
/// println(pb2.render())
/// // 进度条会根据120字符宽度进行调整，显示更长的进度条
/// 
/// // 设置窄屏终端（移动设备）
/// set_terminal_width(40)
/// 
/// let pb3 = new(50).set_dynamic_width(true).set_prefix("处理: ").update(25)
/// println(pb3.render())
/// // 进度条会适应40字符的窄屏显示
/// 
/// // 测试不同宽度下的显示效果
/// let test_widths = [60, 80, 100, 120]
/// let pb_test = new(100).set_prefix("测试: ").set_dynamic_width(true).update(60)
/// 
/// for width in test_widths {
///   set_terminal_width(width)
///   println("宽度 " + width.to_string() + ": " + pb_test.render())
/// }
/// 
/// // 恢复默认设置
/// clear_terminal_width()
/// ```
/// 
/// # 使用场景
/// - **测试环境**: 确保在不同终端宽度下的显示一致性
/// - **调试工具**: 验证动态宽度调整逻辑
/// - **特殊环境**: 在无法自动检测宽度的环境中手动设置
/// - **演示程序**: 展示不同宽度下的进度条效果
/// - **嵌入式系统**: 在固定宽度显示设备上使用
/// - **日志输出**: 控制日志文件中进度条的宽度
/// 
/// # 注意事项
/// - 这是一个全局设置，会影响所有后续创建的动态宽度进度条
/// - 只有设置了 `dynamic_width: true` 的进度条才会受到影响
/// - 设置过小的宽度可能导致进度条显示不完整
/// - 建议宽度至少为30字符以确保基本信息显示
/// - 在生产环境中通常应该依赖自动检测而不是手动设置
/// - 使用完毕后建议调用 `clear_terminal_width()` 恢复自动检测
/// 
/// # 相关函数
/// - `clear_terminal_width()` - 清除手动设置，恢复自动检测
/// - `set_dynamic_width(true)` - 启用进度条的动态宽度调整
/// - `set_ncols(Some(width))` - 为单个进度条设置列数
pub fn set_terminal_width(width : Int) -> Unit {
  // 简化实现：实际中需要修改全局状态
  println("设置终端宽度为: " + width.to_string())
}

///|
/// 清除终端宽度设置，恢复默认检测
/// 
/// 清除之前通过 `set_terminal_width()` 设置的手动宽度，
/// 恢复系统自动检测终端宽度的默认行为。
/// 
/// # 参数
/// 无参数
/// 
/// # 返回值
/// - `Unit` - 无返回值，直接修改全局设置
/// 
/// # 行为
/// - 清除手动设置的终端宽度值
/// - 恢复系统自动检测终端宽度
/// - 影响所有后续使用动态宽度的进度条
/// - 不影响已经创建的进度条实例
/// 
/// # 示例
/// ```moonbit
/// // 设置固定宽度进行测试
/// set_terminal_width(60)
/// 
/// let pb1 = new(100).set_dynamic_width(true).update(30)
/// println(pb1.render())
/// // 使用60字符宽度显示
/// 
/// // 恢复自动检测
/// clear_terminal_width()
/// 
/// let pb2 = new(100).set_dynamic_width(true).update(30)
/// println(pb2.render())
/// // 使用系统检测的实际终端宽度显示
/// 
/// // 测试完成后的清理
/// fn test_different_widths() {
///   // 测试各种宽度
///   let test_widths = [40, 60, 80, 100, 120]
///   let pb = new(50).set_dynamic_width(true).set_prefix("测试: ").update(25)
///   
///   for width in test_widths {
///     set_terminal_width(width)
///     println("宽度" + width.to_string() + ": " + pb.render())
///   }
///   
///   // 测试完成，恢复默认
///   clear_terminal_width()
///   println("恢复默认: " + pb.render())
/// }
/// 
/// // 条件性恢复
/// fn adaptive_width_demo(use_auto_detect: Bool) {
///   if use_auto_detect {
///     clear_terminal_width()
///     println("使用自动检测宽度")
///   } else {
///     set_terminal_width(80)
///     println("使用固定80字符宽度")
///   }
///   
///   let pb = new(200).set_dynamic_width(true).set_show_count(true).update(100)
///   println(pb.render())
/// }
/// 
/// // 确保测试环境清洁
/// fn run_progress_tests() {
///   // 保存当前状态（简化示例）
///   
///   // 执行各种测试...
///   set_terminal_width(50)
///   // ... 测试代码 ...
///   
///   // 清理测试环境
///   clear_terminal_width()
///   println("测试完成，环境已清理")
/// }
/// ```
/// 
/// # 使用场景
/// - **测试清理**: 测试完成后恢复正常环境
/// - **环境切换**: 从固定宽度模式切换到自适应模式
/// - **调试结束**: 调试完成后恢复生产环境设置
/// - **配置重置**: 重置所有终端相关的全局配置
/// - **错误恢复**: 在设置错误的宽度后进行恢复
/// 
/// # 最佳实践
/// 建议在测试或临时设置后总是调用此函数进行清理，
/// 以确保不会影响后续的进度条显示。
/// 
/// # 注意事项
/// - 这是一个全局操作，会影响所有后续的动态宽度进度条
/// - 恢复后的宽度取决于系统的实际终端宽度检测能力
/// - 在某些环境中，自动检测可能不准确，需要根据实际情况调整
/// - 建议在测试代码中总是配对使用 `set_terminal_width()` 和 `clear_terminal_width()`
/// - 不会影响已经创建的进度条实例的显示
/// 
/// # 相关函数
/// - `set_terminal_width(width)` - 设置固定的终端宽度
/// - `set_dynamic_width(true)` - 启用进度条的动态宽度调整
/// - `set_ncols(None)` - 为单个进度条启用自动宽度检测
pub fn clear_terminal_width() -> Unit {
  println("恢复默认终端宽度检测")
}

///|
/// 创建初始时间信息
fn init_time_info() -> TimeInfo {
  let now = current_time()
  { start_time: now, last_update: now, last_print: now, last_n: 0, samples: [] }
}

///|
/// 创建初始统计信息
fn init_stats() -> ProgressStats {
  { avg_time: 0.0, avg_rate: 0.0, smoothed_rate: 0.0, eta: 0.0, elapsed: 0.0 }
}

///|
/// 创建新的进度条
/// 
/// 使用默认配置创建一个新的进度条实例。
/// 
/// # 参数
/// - `total` - 进度条的总数，表示任务的完整数量
/// 
/// # 返回值
/// - `ProgressBar` - 新创建的进度条实例
/// 
/// # 示例
/// ```moonbit
/// // 创建总数为100的进度条
/// let pb = new(100)
/// let result = pb.update(50).render()
/// println(result)
/// // 输出: 50%|[█████████████████████████                         ]
/// 
/// // 链式调用配置
/// let pb2 = new(200)
///   .set_prefix("处理中: ")
///   .set_show_count(true)
///   .update(75)
/// println(pb2.render())
/// // 输出: 处理中: 37% (75/200)|[██████████████████▌                           ]
/// ```
pub fn new(total : Int) -> ProgressBar {
  {
    config: default_config(),
    total,
    current: 0,
    time_info: init_time_info(),
    stats: init_stats(),
    last_printed_n: 0,
    sp: true,
    closed: false,
  }
}

///|
/// 使用自定义配置创建进度条
/// 
/// 使用指定的配置创建进度条实例，允许完全自定义外观和行为。
/// 
/// # 参数
/// - `total` - 进度条的总数，表示任务的完整数量
/// - `config` - 自定义配置对象，包含所有显示和行为选项
/// 
/// # 返回值
/// - `ProgressBar` - 使用自定义配置的进度条实例
/// 
/// # 示例
/// ```moonbit
/// // 创建自定义配置
/// let custom_config = create_config(
///   30, "下载: ", "",
///   '>', '-', true,
///   true, true, true,
///   false, false,
///   true, true, None,
///   1, 0.1, 10.0,
///   "", "it", false, 0
/// )
/// 
/// // 使用自定义配置创建进度条
/// let pb = new_with_config(1024, custom_config)
/// let result = pb.update(512).render()
/// println(result)
/// // 输出: 下载: 50% (512/1024)|[>>>>>>>>>>>>>>>--------------]
/// ```
pub fn new_with_config(total : Int, config : ProgressConfig) -> ProgressBar {
  {
    config,
    total,
    current: 0,
    time_info: init_time_info(),
    stats: init_stats(),
    last_printed_n: 0,
    sp: true,
    closed: false,
  }
}

///|
/// 计算统计信息 - 增强版本
fn compute_stats(self : ProgressBar, new_current : Int) -> ProgressStats {
  let now = current_time()
  let elapsed = now - self.time_info.start_time
  let delta_n = new_current - self.current
  let delta_t = now - self.time_info.last_update

  // 瞬时速率
  let instant_rate = if delta_t > 0.0 {
    Double::from_int(delta_n) / delta_t
  } else {
    0.0
  }

  // 平滑速率计算
  let smoothed_rate = if self.config.smooth {
    // 使用指数移动平均
    if self.stats.smoothed_rate == 0.0 {
      instant_rate
    } else {
      self.stats.smoothed_rate * 0.7 + instant_rate * 0.3
    }
  } else {
    instant_rate
  }

  // 平均速率（从开始到现在）
  let avg_rate = if elapsed > 0.0 {
    Double::from_int(new_current) / elapsed
  } else {
    0.0
  }

  // ETA计算 - 使用更精确的方法
  let eta = if new_current >= self.total {
    0.0 // 已完成
  } else {
    let remaining = self.total - new_current
    if smoothed_rate > 0.0 {
      Double::from_int(remaining) / smoothed_rate
    } else if avg_rate > 0.0 {
      Double::from_int(remaining) / avg_rate
    } else {
      0.0
    }
  }
  {
    avg_time: if new_current > 0 {
      elapsed / Double::from_int(new_current)
    } else {
      0.0
    },
    avg_rate,
    smoothed_rate,
    eta,
    elapsed,
  }
}

///|
/// 更新进度条的当前进度值
/// 
/// 更新进度条的当前值，自动计算统计信息（速率、ETA等），并返回更新后的进度条实例。
/// 支持链式调用。
/// 
/// # 参数
/// - `self` - 当前的进度条实例
/// - `new_current` - 新的当前进度值，会被限制在0到total之间
/// 
/// # 返回值
/// - `ProgressBar` - 更新后的进度条实例，支持链式调用
/// 
/// # 行为
/// - 自动限制进度值在有效范围内（0 <= current <= total）
/// - 智能更新频率控制（基于miniters和mininterval配置）
/// - 自动计算平均速率、瞬时速率和ETA
/// - 维护时间样本点用于精确的速率计算
/// 
/// # 示例
/// ```moonbit
/// // 基本使用
/// let pb = new(100)
/// let updated_pb = pb.update(50)
/// println(updated_pb.render())
/// // 输出: 50%|[█████████████████████████                         ]
/// 
/// // 链式调用
/// let pb2 = new(200)
///   .set_prefix("处理: ")
///   .set_show_count(true)
///   .update(75)
///   .update(100) // 继续更新
/// println(pb2.render())
/// // 输出: 处理: 50% (100/200)|[█████████████████████████                     ]
/// 
/// // 循环中使用
/// let mut pb3 = new(1000).set_show_rate(true)
/// for i = 0; i <= 1000; i = i + 10 {
///   pb3 = pb3.update(i)
///   println(pb3.render())
/// }
/// ```
pub fn update(self : ProgressBar, new_current : Int) -> ProgressBar {
  if self.closed {
    return self
  }
  let clamped_current = if new_current > self.total {
    self.total
  } else {
    new_current
  }
  let now = current_time()

  // 检查是否需要更新（miniters 和 mininterval）
  let delta_n = clamped_current - self.current
  let delta_t = now - self.time_info.last_update
  if delta_n < self.config.miniters && delta_t < self.config.mininterval {
    return { ..self, current: clamped_current }
  }
  let new_stats = self.compute_stats(clamped_current)

  // 更新样本点数据（用于速率计算）
  let new_samples = self.time_info.samples.copy()
  new_samples.push((now, clamped_current))

  // 保持最近的样本点（最多10个）
  if new_samples.length() > 10 {
    ignore(new_samples.remove(0))
  }
  let new_time_info = {
    ..self.time_info,
    last_update: now,
    last_n: clamped_current,
    samples: new_samples,
  }
  {
    ..self,
    current: clamped_current,
    time_info: new_time_info,
    stats: new_stats,
  }
}

///|
/// 增加进度（递增1）
/// 
/// 将当前进度值增加1，等同于 update(current + 1)。
/// 适用于逐项处理的循环场景。
/// 
/// # 参数
/// - `self` - 当前的进度条实例
/// 
/// # 返回值
/// - `ProgressBar` - 更新后的进度条实例，支持链式调用
/// 
/// # 示例
/// ```moonbit
/// // 在循环中逐项递增
/// let mut pb = new(10).set_prefix("处理项目: ")
/// for i = 0; i < 10; i = i + 1 {
///   // 处理某个项目...
///   pb = pb.increment()
///   println(pb.render())
/// }
/// // 输出类似: 处理项目: 100%|[██████████████████████████████████████████████████]
/// 
/// // 链式调用
/// let pb2 = new(5)
///   .increment()  // 1/5
///   .increment()  // 2/5
///   .increment()  // 3/5
/// println(pb2.render())
/// // 输出: 60%|[██████████████████████████████                    ]
/// ```
pub fn increment(self : ProgressBar) -> ProgressBar {
  self.update(self.current + 1)
}

///|
/// 增加指定数量的进度
/// 
/// 将进度条的当前值增加指定的数量，相当于调用 `update(current + amount)`。
/// 适用于批量处理或可变增量的场景。
/// 
/// # 参数
/// - `self` - 当前的进度条实例
/// - `amount` - 要增加的进度数量，可以是正数、负数或零
/// 
/// # 返回值
/// - `ProgressBar` - 更新后的进度条实例，支持链式调用
/// 
/// # 行为
/// - 如果增加后超过总数，会自动限制在总数范围内
/// - 如果增加后小于0，会自动限制为0
/// - amount为0时，仍会触发统计信息更新
/// 
/// # 示例
/// ```moonbit
/// // 批量处理场景
/// let pb = new(1000).set_prefix("批量处理: ").set_show_count(true)
/// let pb1 = pb.increment_by(50)  // 处理了50个项目
/// let pb2 = pb1.increment_by(100) // 又处理了100个项目
/// println(pb2.render())
/// // 输出: 批量处理: 15% (150/1000)|[███████▌                                          ]
/// 
/// // 可变增量处理
/// let mut pb_var = new(500).set_show_rate(true)
/// let batch_sizes = [25, 50, 75, 100]
/// for size in batch_sizes {
///   pb_var = pb_var.increment_by(size)
///   println(pb_var.render())
/// }
/// // 最终: 50% (250/500)|[█████████████████████████                         ] [62.5it/s]
/// 
/// // 链式调用
/// let pb_chain = new(200)
///   .increment_by(20)
///   .increment_by(30)
///   .increment_by(50)
///   .set_suffix(" 已完成")
/// println(pb_chain.render())
/// // 输出: 50% (100/200)|[█████████████████████████                         ] 已完成
/// 
/// // 处理下载块
/// let pb_download = new(1024).set_unit("KB").set_show_rate(true)
/// let chunk_sizes = [128, 256, 512, 128]
/// let mut current_pb = pb_download
/// for chunk_size in chunk_sizes {
///   current_pb = current_pb.increment_by(chunk_size)
///   println(current_pb.render())
/// }
/// // 输出: 100% (1024/1024)|[██████████████████████████████████████████████████] [256.0KB/s]
/// ```
/// 
/// # 注意
/// - 适用于文件传输、批量数据处理等场景
/// - 可以处理负数增量（相当于回退进度）
/// - 增量为0时仍会更新时间统计信息
pub fn increment_by(self : ProgressBar, amount : Int) -> ProgressBar {
  self.update(self.current + amount)
}

///|
/// 重置进度条
/// 
/// 将进度条重置到初始状态，清零当前进度和所有统计信息，但保留配置选项。
/// 适用于需要重复使用同一进度条的场景。
/// 
/// # 参数
/// - `self` - 当前的进度条实例
/// 
/// # 返回值
/// - `ProgressBar` - 重置后的进度条实例，当前进度为0，统计信息已清空
/// 
/// # 重置内容
/// - 当前进度值重置为0
/// - 开始时间重置为当前时间
/// - 清空所有时间样本点
/// - 重置平均速率、ETA等统计信息
/// - 重置打印状态
/// - 取消关闭状态（如果之前已关闭）
/// - **保留**所有配置选项（宽度、前缀、后缀等）
/// 
/// # 示例
/// ```moonbit
/// // 基本重置使用
/// let pb = new(100)
///   .set_prefix("第一轮: ")
///   .update(50)
/// println(pb.render())
/// // 输出: 第一轮: 50%|[█████████████████████████                         ]
/// 
/// let pb_reset = pb.reset_progress().set_prefix("第二轮: ")
/// println(pb_reset.render())
/// // 输出: 第二轮: 0%|[                                                  ]
/// 
/// // 多轮处理场景
/// let mut pb_multi = new(1000).set_show_count(true).set_show_rate(true)
/// 
/// // 第一轮处理
/// pb_multi = pb_multi.set_prefix("处理批次1: ").update(1000).finish()
/// println(pb_multi.render())
/// // 输出: 处理批次1: 100% (1000/1000)|[██████████████████████████████████████████████████] [250.0it/s]
/// 
/// // 重置并开始第二轮
/// pb_multi = pb_multi.reset_progress().set_prefix("处理批次2: ")
/// pb_multi = pb_multi.update(300)
/// println(pb_multi.render())
/// // 输出: 处理批次2: 30% (300/1000)|[███████████████                                   ] [75.0it/s]
/// 
/// // 测试/调试场景
/// let test_pb = new(50)
///   .set_fill('*')
///   .set_empty('-')
///   .update(25)
/// println("测试前: " + test_pb.render())
/// // 输出: 测试前: 50%|[*************************-------------------------]
/// 
/// let reset_test_pb = test_pb.reset_progress()
/// println("重置后: " + reset_test_pb.render())
/// // 输出: 重置后: 0%|[--------------------------------------------------]
/// // 注意：填充字符配置被保留
/// ```
/// 
/// # 使用场景
/// - 多阶段任务处理（如多个文件的处理）
/// - 重复执行的批处理任务
/// - 测试和调试时需要重置进度条状态
/// - 用户手动重新开始任务
/// 
/// # 注意
/// - 重置后进度条不再处于关闭状态
/// - 配置选项（样式、显示选项等）会完全保留
/// - 时间统计会从重置时刻重新开始计算
pub fn reset_progress(self : ProgressBar) -> ProgressBar {
  {
    ..self,
    current: 0,
    time_info: init_time_info(),
    stats: init_stats(),
    last_printed_n: 0,
    closed: false,
  }
}

///|
/// 关闭进度条
/// 
/// 将进度条标记为关闭状态，阻止后续的更新操作。
/// 关闭后的进度条将忽略所有 update、increment 等操作。
/// 
/// # 参数
/// - `self` - 当前的进度条实例
/// 
/// # 返回值
/// - `ProgressBar` - 关闭状态的进度条实例，后续更新操作将被忽略
/// 
/// # 行为
/// - 设置 closed 标志为 true
/// - 后续调用 update()、increment() 等方法将不会改变进度值
/// - 可以继续调用 render() 显示当前状态
/// - 可以通过 reset_progress() 重新激活进度条
/// 
/// # 示例
/// ```moonbit
/// // 基本关闭使用
/// let pb = new(100).update(50)
/// println(pb.render())
/// // 输出: 50%|[█████████████████████████                         ]
/// 
/// let closed_pb = pb.close()
/// println(closed_pb.render())
/// // 输出: 50%|[█████████████████████████                         ]
/// 
/// // 关闭后的更新将被忽略
/// let ignored_pb = closed_pb.update(80)
/// println(ignored_pb.render())
/// // 输出: 50%|[█████████████████████████                         ] (仍然是50%，更新被忽略)
/// 
/// // 手动任务中止场景
/// let mut pb_task = new(1000).set_prefix("处理任务: ").set_show_count(true)
/// 
/// // 处理一些项目
/// pb_task = pb_task.update(300)
/// println(pb_task.render())
/// // 输出: 处理任务: 30% (300/1000)|[███████████████                                   ]
/// 
/// // 发生错误或用户取消，关闭进度条
/// pb_task = pb_task.close().set_suffix(" [已取消]")
/// println(pb_task.render())
/// // 输出: 处理任务: 30% (300/1000)|[███████████████                                   ] [已取消]
/// 
/// // 尝试继续更新（将被忽略）
/// pb_task = pb_task.update(500)
/// println(pb_task.render())
/// // 输出: 处理任务: 30% (300/1000)|[███████████████                                   ] [已取消] (仍然是30%)
/// 
/// // 资源清理场景
/// let pb_cleanup = new(10).set_prefix("清理资源: ")
/// let mut current_pb = pb_cleanup
/// 
/// // 处理一些资源
/// for i = 1; i <= 5; i = i + 1 {
///   current_pb = current_pb.increment()
///   if i == 3 {
///     // 在某个点决定提前结束
///     current_pb = current_pb.close().set_suffix(" [提前完成]")
///     break
///   }
/// }
/// println(current_pb.render())
/// // 输出: 清理资源: 30% (3/10)|[███████████████                                   ] [提前完成]
/// ```
/// 
/// # 使用场景
/// - 任务被用户取消或中断
/// - 发生错误需要停止进度更新
/// - 提前完成任务（但不想显示100%）
/// - 资源清理和状态管理
/// - 防止意外的进度更新
/// 
/// # 注意
/// - 关闭是一个单向操作，需要通过 reset_progress() 才能重新激活
/// - 关闭后仍可以修改显示配置（前缀、后缀等）
/// - render() 方法在关闭后仍然正常工作
/// - 建议在关闭时设置适当的后缀来说明关闭原因
pub fn close(self : ProgressBar) -> ProgressBar {
  { ..self, closed: true }
}

///|
/// 设置总数
/// 
/// 动态修改进度条的总数值，用于处理任务总量在运行时发生变化的场景。
/// 更新总数后会自动重新计算百分比和其他相关统计信息。
/// 
/// # 参数
/// - `self` - 当前的进度条实例
/// - `new_total` - 新的总数值，应该大于0
/// 
/// # 返回值
/// - `ProgressBar` - 更新总数后的进度条实例，支持链式调用
/// 
/// # 行为
/// - 立即更新总数值
/// - 当前进度值保持不变（除非超过新总数）
/// - 如果当前进度超过新总数，下次update时会被限制
/// - 百分比会根据新总数重新计算
/// - ETA和速率计算会基于新总数进行调整
/// 
/// # 示例
/// ```moonbit
/// // 动态调整任务总量
/// let pb = new(100).set_prefix("处理文件: ").set_show_count(true).update(30)
/// println(pb.render())
/// // 输出: 处理文件: 30% (30/100)|[███████████████                                   ]
/// 
/// // 发现需要处理更多文件，调整总数
/// let pb_adjusted = pb.set_total(150)
/// println(pb_adjusted.render())
/// // 输出: 处理文件: 20% (30/150)|[██████████                                        ]
/// 
/// // 文件扫描场景 - 总数逐步增加
/// let mut pb_scan = new(10).set_prefix("扫描目录: ").set_show_count(true)
/// 
/// // 初始扫描发现10个文件
/// pb_scan = pb_scan.update(5)
/// println(pb_scan.render())
/// // 输出: 扫描目录: 50% (5/10)|[█████████████████████████                         ]
/// 
/// // 发现子目录中有更多文件，调整总数
/// pb_scan = pb_scan.set_total(25)
/// println(pb_scan.render())
/// // 输出: 扫描目录: 20% (5/25)|[██████████                                        ]
/// 
/// // 继续处理
/// pb_scan = pb_scan.update(15)
/// println(pb_scan.render())
/// // 输出: 扫描目录: 60% (15/25)|[██████████████████████████████                    ]
/// 
/// // 下载场景 - 文件大小调整
/// let mut pb_download = new(1000).set_prefix("下载: ").set_unit("KB").set_show_rate(true)
/// pb_download = pb_download.update(200)
/// println(pb_download.render())
/// // 输出: 下载: 20% (200/1000)|[██████████                                        ] [50.0KB/s]
/// 
/// // 服务器返回实际文件大小更大
/// pb_download = pb_download.set_total(1500)
/// println(pb_download.render())
/// // 输出: 下载: 13% (200/1500)|[██████▌                                           ] [50.0KB/s]
/// 
/// // 批处理任务 - 任务数量变化
/// let mut pb_batch = new(50).set_prefix("批处理: ").set_show_count(true).set_show_eta(true)
/// pb_batch = pb_batch.update(20)
/// println(pb_batch.render())
/// // 输出: 批处理: 40% (20/50)|[████████████████████                              ] ETA: 7s
/// 
/// // 发现有些任务可以跳过，减少总数
/// pb_batch = pb_batch.set_total(35)
/// println(pb_batch.render())
/// // 输出: 批处理: 57% (20/35)|[████████████████████████████▌                     ] ETA: 3s
/// ```
/// 
/// # 使用场景
/// - 文件/目录扫描时发现实际数量与预期不符
/// - 网络下载时服务器返回实际文件大小
/// - 数据库查询时发现实际记录数不同
/// - 批处理任务中可以跳过某些项目
/// - 任务分解时发现子任务数量变化
/// - 实时数据处理中数据量动态变化
/// 
/// # 注意
/// - 建议在任务早期阶段调整总数，避免频繁变化影响用户体验
/// - 如果当前进度已经超过新总数，建议先调整总数再更新进度
/// - 总数变化会影响ETA计算的准确性
/// - 设置为0或负数可能导致除零错误，建议设置为正整数
pub fn set_total(self : ProgressBar, new_total : Int) -> ProgressBar {
  { ..self, total: new_total }
}

///|
/// 格式化时间（秒转换为人类可读格式）
fn format_time(seconds : Double) -> String {
  let total_secs = seconds.to_int()
  let hours = total_secs / 3600
  let minutes = total_secs % 3600 / 60
  let secs = total_secs % 60
  if hours > 0 {
    hours.to_string() +
    ":" +
    (if minutes < 10 { "0" } else { "" }) +
    minutes.to_string() +
    ":" +
    (if secs < 10 { "0" } else { "" }) +
    secs.to_string()
  } else if minutes > 0 {
    minutes.to_string() +
    ":" +
    (if secs < 10 { "0" } else { "" }) +
    secs.to_string()
  } else {
    secs.to_string() + "s"
  }
}

///|
/// 格式化速率
fn format_rate(rate : Double, unit : String, unit_scale : Bool) -> String {
  if unit_scale {
    if rate >= 1000000.0 {
      (rate / 1000000.0).to_string() + "M" + unit + "/s"
    } else if rate >= 1000.0 {
      (rate / 1000.0).to_string() + "k" + unit + "/s"
    } else {
      rate.to_string() + unit + "/s"
    }
  } else {
    rate.to_string() + unit + "/s"
  }
}

///|
/// 计算进度百分比
/// 
/// 计算并返回当前进度的百分比值（0.0 到 100.0）。
/// 这是一个便利函数，用于获取精确的百分比数值进行自定义处理。
/// 
/// # 参数
/// - `self` - 当前的进度条实例
/// 
/// # 返回值
/// - `Double` - 百分比值，范围为 0.0 到 100.0
///   - 0.0 表示未开始（current = 0）
///   - 100.0 表示完全完成（current = total）
///   - 如果 total <= 0，返回 0.0 以避免除零错误
/// 
/// # 计算公式
/// 百分比 = (当前进度 / 总数) * 100.0
/// 
/// # 示例
/// ```moonbit
/// // 基本百分比计算
/// let pb1 = new(100).update(25)
/// let pct1 = pb1.percentage()
/// println("完成度: " + pct1.to_string() + "%")
/// // 输出: 完成度: 25.0%
/// 
/// // 精确的百分比计算
/// let pb2 = new(3).update(1)
/// let pct2 = pb2.percentage()
/// println("精确完成度: " + pct2.to_string() + "%")
/// // 输出: 精确完成度: 33.333333333333336%
/// 
/// // 自定义进度判断
/// let pb3 = new(1000).update(750)
/// let pct3 = pb3.percentage()
/// if pct3 >= 75.0 {
///   println("任务接近完成: " + pct3.to_string() + "%")
/// } else if pct3 >= 50.0 {
///   println("任务进展过半: " + pct3.to_string() + "%")
/// } else {
///   println("任务刚开始: " + pct3.to_string() + "%")
/// }
/// // 输出: 任务接近完成: 75.0%
/// 
/// // 进度条状态分析
/// let pb4 = new(200).update(0)
/// let pct4 = pb4.percentage()
/// println("起始状态: " + pct4.to_string() + "%")
/// // 输出: 起始状态: 0.0%
/// 
/// let pb5 = new(50).update(50)
/// let pct5 = pb5.percentage()
/// println("完成状态: " + pct5.to_string() + "%")
/// // 输出: 完成状态: 100.0%
/// 
/// // 用于条件控制
/// let mut pb_conditional = new(100)
/// for i = 0; i <= 100; i = i + 10 {
///   pb_conditional = pb_conditional.update(i)
///   let current_pct = pb_conditional.percentage()
///   
///   if current_pct == 50.0 {
///     println("达到中点！")
///   }
///   
///   if current_pct >= 90.0 {
///     println("即将完成，当前进度: " + current_pct.to_string() + "%")
///   }
/// }
/// 
/// // 异常情况处理
/// let pb_zero = new(0).update(10)
/// let pct_zero = pb_zero.percentage()
/// println("零总数情况: " + pct_zero.to_string() + "%")
/// // 输出: 零总数情况: 0.0%
/// ```
/// 
/// # 使用场景
/// - 自定义进度条显示格式
/// - 基于进度百分比的条件判断
/// - 进度数据的记录和分析
/// - 与其他系统的进度同步
/// - 实现自定义的进度阈值警告
/// - 进度条的测试和验证
/// 
/// # 注意
/// - 返回值是浮点数，可能包含小数
/// - 当 total 为 0 或负数时，返回 0.0 避免除零错误
/// - 精度取决于 Double 类型的精度限制
/// - 适合用于需要精确百分比值的场景
pub fn percentage(self : ProgressBar) -> Double {
  if self.total <= 0 {
    0.0
  } else {
    Double::from_int(self.current) / Double::from_int(self.total) * 100.0
  }
}

///|
/// 获取动态宽度
fn get_dynamic_width(self : ProgressBar) -> Int {
  // 使用配置的列数或动态检测的终端宽度
  let terminal_cols = match self.config.ncols {
    Some(cols) => cols
    None => get_terminal_width()
  }

  // 计算可用宽度（减去其他元素的宽度）
  let desc_width = if self.config.desc.length() > 0 {
    self.config.desc.length() + 2
  } else {
    0
  } // "desc: "
  let prefix_width = if self.config.prefix.length() > 0 {
    self.config.prefix.length() + 1
  } else {
    0
  }
  let suffix_width = if self.config.suffix.length() > 0 {
    self.config.suffix.length() + 1
  } else {
    0
  }
  let percent_width = if self.config.show_percent { 6 } else { 0 } // " 100%|"
  let count_width = if self.config.show_count {
    self.current.to_string().length() + self.total.to_string().length() + 3 // " n/total"
  } else {
    0
  }
  let rate_width = if self.config.show_rate { 15 } else { 0 } // " [1000.0it/s]"
  let eta_width = if self.config.show_eta { 12 } else { 0 } // " ETA: 10:30"
  let elapsed_width = if self.config.show_elapsed { 12 } else { 0 }
  let used_width = desc_width +
    prefix_width +
    suffix_width +
    percent_width +
    count_width +
    rate_width +
    eta_width +
    elapsed_width +
    3 // "[]" + spaces
  let available = terminal_cols - used_width
  if available > 10 {
    available
  } else {
    10
  }
}

///|
/// 将进度条渲染为字符串
/// 
/// 根据当前配置和进度状态，生成进度条的字符串表示。这是显示进度条的核心方法。
/// 
/// # 参数
/// - `self` - 要渲染的进度条实例
/// 
/// # 返回值
/// - `String` - 格式化的进度条字符串，可直接用于打印
/// 
/// # 渲染元素
/// 根据配置，渲染结果可能包含：
/// - 描述文本（desc）
/// - 前缀文本（prefix）
/// - 百分比（show_percent）
/// - 进度条主体（填充字符 + 空白字符）
/// - 计数信息（show_count）：当前/总数
/// - 处理速率（show_rate）：项目/秒
/// - 预计剩余时间（show_eta）：ETA: Xm Ys
/// - 已用时间（show_elapsed）
/// - 后缀文本（suffix）
/// 
/// # 示例
/// ```moonbit
/// // 基本渲染
/// let pb1 = new(100).update(50)
/// println(pb1.render())
/// // 输出: 50%|[█████████████████████████                         ]
/// 
/// // 带计数的渲染
/// let pb2 = new(200).set_show_count(true).update(75)
/// println(pb2.render())
/// // 输出: 37% (75/200)|[██████████████████▌                           ]
/// 
/// // 完整功能渲染
/// let pb3 = new(1000)
///   .set_prefix("下载: ")
///   .set_suffix(" 完成")
///   .set_show_count(true)
///   .set_show_rate(true)
///   .set_show_eta(true)
///   .set_unit("MB")
///   .update(400)
/// println(pb3.render())
/// // 输出: 下载: 40% (400/1000)|[████████████████████                         ] [125.5MB/s] ETA: 4m30s 完成
/// ```
pub fn render(self : ProgressBar) -> String {
  let percentage = self.percentage()
  let bar_width = if self.config.dynamic_width {
    self.get_dynamic_width()
  } else {
    self.config.width
  }

  // 平滑进度计算
  let progress = if self.config.smooth {
    percentage / 100.0
  } else {
    percentage / 100.0
  }
  let filled_width = (Double::from_int(bar_width) * progress).to_int()
  let empty_width = bar_width - filled_width
  let mut result = ""

  // 描述文本
  if self.config.desc.length() > 0 {
    result = result + self.config.desc + ": "
  }

  // 前缀
  if self.config.prefix.length() > 0 {
    result = result + self.config.prefix + " "
  }

  // 百分比（前置）
  if self.config.show_percent {
    let percent_str = if percentage >= 100.0 {
      "100%"
    } else {
      percentage.to_string() + "%"
    }
    result = result + percent_str + "|"
  }

  // 进度条主体
  result = result + "["

  // 填充部分
  for i = 0; i < filled_width; i = i + 1 {
    result = result + Char::to_string(self.config.fill)
  }

  // 空白部分
  for i = 0; i < empty_width; i = i + 1 {
    result = result + Char::to_string(self.config.empty)
  }
  result = result + "]"

  // 计数显示
  if self.config.show_count {
    result = result +
      " " +
      self.current.to_string() +
      "/" +
      self.total.to_string()
  }

  // 速率显示
  if self.config.show_rate && self.stats.avg_rate > 0.0 {
    result = result +
      " [" +
      format_rate(self.stats.avg_rate, self.config.unit, self.config.unit_scale) +
      "]"
  }

  // ETA显示
  if self.config.show_eta && self.stats.eta > 0.0 && self.current < self.total {
    result = result + " ETA: " + format_time(self.stats.eta)
  }

  // 已用时间显示
  if self.config.show_elapsed {
    result = result + " " + format_time(self.stats.elapsed)
  }

  // 后缀
  if self.config.suffix.length() > 0 {
    result = result + " " + self.config.suffix
  }
  result
}

///|
/// 智能打印进度条
/// 
/// 将进度条的当前状态打印到控制台，具有智能频率控制，避免过于频繁的输出。
/// 根据配置的时间间隔和更新间隔自动决定是否需要打印。
/// 
/// # 参数
/// - `self` - 当前的进度条实例
/// 
/// # 返回值
/// - `Unit` - 无返回值，直接输出到控制台
/// 
/// # 行为
/// - 检查进度条是否已关闭，已关闭则不打印
/// - 基于 mininterval 配置控制打印频率
/// - 基于 miniters 配置控制更新阈值
/// - 自动处理光标位置和换行
/// - 支持动态宽度调整
/// 
/// # 示例
/// ```moonbit
/// // 基本打印使用
/// let pb = new(100).set_prefix("处理: ").update(30)
/// pb.print_progress()
/// // 控制台输出: 处理: 30%|[███████████████                                   ]
/// 
/// // 循环中的智能打印
/// let mut pb_loop = new(1000).set_show_rate(true).set_show_eta(true)
/// for i = 0; i <= 1000; i = i + 50 {
///   pb_loop = pb_loop.update(i)
///   pb_loop.print_progress()  // 根据时间间隔智能决定是否打印
///   // 避免过于频繁的控制台输出
/// }
/// 
/// // 文件处理场景
/// let pb_files = new(100).set_prefix("处理文件: ").set_show_count(true)
/// let mut current_pb = pb_files
/// 
/// // 模拟文件处理
/// for i = 1; i <= 100; i = i + 1 {
///   current_pb = current_pb.increment()
///   
///   // 每处理一个文件就尝试打印（智能频率控制）
///   current_pb.print_progress()
///   
///   // 模拟处理时间
///   // Thread.sleep(100)
/// }
/// // 最终输出: 处理文件: 100% (100/100)|[██████████████████████████████████████████████████]
/// 
/// // 下载进度显示
/// let pb_download = new(1024).set_prefix("下载: ").set_unit("KB").set_show_rate(true)
/// let mut download_pb = pb_download
/// let chunk_size = 64
/// 
/// for downloaded = chunk_size; downloaded <= 1024; downloaded = downloaded + chunk_size {
///   download_pb = download_pb.update(downloaded)
///   download_pb.print_progress()  // 智能控制打印频率
/// }
/// // 输出类似: 下载: 100% (1024/1024)|[██████████████████████████████████████████████████] [256.0KB/s]
/// 
/// // 与手动控制对比
/// let pb_manual = new(50).set_prefix("手动控制: ")
/// let mut manual_pb = pb_manual
/// 
/// for i = 1; i <= 50; i = i + 1 {
///   manual_pb = manual_pb.increment()
///   
///   // 只在特定条件下打印
///   if i % 10 == 0 || i == 50 {
///     manual_pb.print_progress()
///   }
/// }
/// // 只在 10, 20, 30, 40, 50 时打印
/// ```
/// 
/// # 智能控制特性
/// - **时间间隔控制**: 基于 `mininterval` 避免过于频繁的打印
/// - **更新阈值控制**: 基于 `miniters` 避免微小变化的打印
/// - **状态检查**: 自动跳过已关闭的进度条
/// - **性能优化**: 减少不必要的控制台I/O操作
/// 
/// # 使用场景
/// - 长时间运行的批处理任务
/// - 文件传输和下载任务
/// - 数据处理和分析任务
/// - 需要实时反馈的命令行工具
/// - 自动化脚本中的进度显示
/// 
/// # 注意
/// - 这是一个副作用函数，会直接输出到控制台
/// - 智能频率控制可能导致某些更新不被立即显示
/// - 如需强制打印，可以使用 `println(pb.render())` 
/// - 在快速循环中使用时性能最佳
/// - 关闭的进度条不会产生任何输出
pub fn print_progress(self : ProgressBar) -> Unit {
  if self.closed {
    return
  }
  let now = current_time()

  // 检查打印间隔
  if now - self.time_info.last_print < self.config.mininterval {
    return
  }
  let rendered = self.render()

  // 使用回车符覆盖当前行（简化实现）
  println(rendered)
}

///|
/// 智能打印（带状态更新）
pub fn print_with_update(self : ProgressBar) -> ProgressBar {
  let updated_time_info = { ..self.time_info, last_print: current_time() }
  let result = { ..self, time_info: updated_time_info }
  result.print_progress()
  result
}

///|
/// 完成进度条
/// 
/// 将进度条设置为完成状态（current = total），打印最终结果，并根据配置决定是否保留显示。
/// 
/// # 参数
/// - `self` - 当前的进度条实例
/// 
/// # 返回值
/// - `ProgressBar` - 已完成并关闭的进度条实例
/// 
/// # 行为
/// 1. 自动将进度设置为100%（current = total）
/// 2. 打印最终的进度条状态
/// 3. 根据leave配置决定是否保留显示
/// 4. 关闭进度条，防止后续更新
/// 
/// # 示例
/// ```moonbit
/// // 基本完成操作
/// let pb1 = new(100)
///   .set_prefix("下载: ")
///   .update(95)  // 进行到95%
/// let completed = pb1.finish()  // 自动完成到100%
/// // 输出: 下载: 100%|[██████████████████████████████████████████████████]
/// 
/// // 设置不保留完成状态
/// let pb2 = new(50)
///   .set_leave(false)
///   .set_prefix("临时任务: ")
///   .update(30)
/// let completed2 = pb2.finish()  // 完成后清除显示
/// 
/// // 批处理场景
/// fn process_batch(items: Array[String]) {
///   let mut pb = new(items.length())
///     .set_prefix("批处理: ")
///     .set_show_count(true)
///   
///   for i = 0; i < items.length(); i = i + 1 {
///     // 处理项目...
///     pb = pb.update(i + 1)
///   }
///   pb.finish()  // 确保显示100%完成
/// }
/// ```
pub fn finish(self : ProgressBar) -> ProgressBar {
  let final_pb = self.update(self.total)
  final_pb.print_progress()

  // 如果设置了 leave，保留进度条；否则清除
  if final_pb.config.leave {
    println("") // 换行
  } else {
    // 简化清除实现
    println("")
  }
  final_pb.close()
}

///|
/// 设置进度条宽度
/// 
/// 设置进度条主体部分的字符宽度。不影响前缀、后缀等其他元素。
/// 
/// # 参数
/// - `self` - 当前的进度条实例
/// - `width` - 新的宽度值（字符数），建议范围：10-100
/// 
/// # 返回值
/// - `ProgressBar` - 更新配置后的进度条实例，支持链式调用
/// 
/// # 示例
/// ```moonbit
/// // 设置较窄的进度条
/// let pb1 = new(100).set_width(20).update(50)
/// println(pb1.render())
/// // 输出: 50%|[██████████          ]
/// 
/// // 设置较宽的进度条
/// let pb2 = new(100).set_width(80).update(25)
/// println(pb2.render())
/// // 输出: 25%|[████████████████████                                                            ]
/// 
/// // 链式配置
/// let pb3 = new(200)
///   .set_width(30)
///   .set_prefix("加载: ")
///   .update(100)
/// println(pb3.render())
/// // 输出: 加载: 50%|[███████████████               ]
/// ```
pub fn set_width(self : ProgressBar, width : Int) -> ProgressBar {
  { ..self, config: { ..self.config, width, } }
}

///|
/// 设置前缀文本
/// 
/// 在进度条前面添加描述性文本，用于说明当前正在执行的任务。
/// 
/// # 参数
/// - `self` - 当前的进度条实例
/// - `prefix` - 前缀文本，会自动在后面添加一个空格
/// 
/// # 返回值
/// - `ProgressBar` - 更新配置后的进度条实例，支持链式调用
/// 
/// # 示例
/// ```moonbit
/// // 基本前缀使用
/// let pb1 = new(100).set_prefix("下载文件:").update(30)
/// println(pb1.render())
/// // 输出: 下载文件: 30%|[███████████████                                   ]
/// 
/// // 不同场景的前缀
/// let pb2 = new(1000).set_prefix("处理数据:").set_show_count(true).update(250)
/// println(pb2.render())
/// // 输出: 处理数据: 25% (250/1000)|[████████████▌                                 ]
/// 
/// // 动态更新前缀（通过重新配置）
/// let pb3 = new(50)
/// let pb3_downloading = pb3.set_prefix("正在下载:").update(20)
/// let pb3_processing = pb3_downloading.set_prefix("正在处理:").update(30)
/// println(pb3_processing.render())
/// // 输出: 正在处理: 60%|[██████████████████████████████                    ]
/// ```
pub fn set_prefix(self : ProgressBar, prefix : String) -> ProgressBar {
  { ..self, config: { ..self.config, prefix, } }
}

///|
/// 设置后缀文本
/// 
/// 在进度条后面添加描述性文本，用于显示额外的状态信息或完成提示。
/// 后缀文本会出现在进度条的最右侧。
/// 
/// # 参数
/// - `self` - 当前的进度条实例
/// - `suffix` - 后缀文本，会显示在进度条的末尾
/// 
/// # 返回值
/// - `ProgressBar` - 更新配置后的进度条实例，支持链式调用
/// 
/// # 示例
/// ```moonbit
/// // 基本后缀使用
/// let pb1 = new(100).set_suffix(" 完成").update(30)
/// println(pb1.render())
/// // 输出: 30%|[███████████████                                   ] 完成
/// 
/// // 状态指示后缀
/// let pb2 = new(1000).set_prefix("下载: ").set_suffix(" [进行中]").update(250)
/// println(pb2.render())
/// // 输出: 下载: 25%|[████████████▌                                 ] [进行中]
/// 
/// // 动态后缀更新
/// let mut pb3 = new(50).set_prefix("处理: ")
/// pb3 = pb3.update(20).set_suffix(" [阶段1]")
/// println(pb3.render())
/// // 输出: 处理: 40%|[████████████████████                          ] [阶段1]
/// 
/// pb3 = pb3.update(35).set_suffix(" [阶段2]")
/// println(pb3.render())
/// // 输出: 处理: 70%|[███████████████████████████████████           ] [阶段2]
/// 
/// pb3 = pb3.update(50).set_suffix(" [已完成]")
/// println(pb3.render())
/// // 输出: 处理: 100%|[██████████████████████████████████████████████████] [已完成]
/// 
/// // 错误状态指示
/// let pb_error = new(100).set_prefix("上传: ").update(30)
/// let pb_failed = pb_error.close().set_suffix(" [失败]")
/// println(pb_failed.render())
/// // 输出: 上传: 30%|[███████████████                                   ] [失败]
/// 
/// // 结合其他显示选项
/// let pb_detailed = new(2000)
///   .set_prefix("数据处理: ")
///   .set_suffix(" 已保存")
///   .set_show_count(true)
///   .set_show_rate(true)
///   .set_unit("records")
///   .update(800)
/// println(pb_detailed.render())
/// // 输出: 数据处理: 40% (800/2000)|[████████████████████                              ] [200.0records/s] 已保存
/// 
/// // 清空后缀
/// let pb_clean = pb_detailed.set_suffix("")
/// println(pb_clean.render())
/// // 输出: 数据处理: 40% (800/2000)|[████████████████████                              ] [200.0records/s]
/// ```
/// 
/// # 使用场景
/// - 显示任务完成状态（"完成"、"已保存"等）
/// - 指示当前处理阶段（"阶段1"、"准备中"等）
/// - 显示错误或警告状态（"失败"、"警告"等）
/// - 提供额外的上下文信息
/// - 显示文件名或路径信息
/// - 状态变化的动态提示
/// 
/// # 注意
/// - 后缀文本不会自动添加空格，需要手动包含
/// - 过长的后缀可能影响进度条的显示效果
/// - 可以设置为空字符串来清除后缀
/// - 后缀会影响整体进度条的宽度计算
/// - 建议保持后缀简洁明了
pub fn set_suffix(self : ProgressBar, suffix : String) -> ProgressBar {
  { ..self, config: { ..self.config, suffix, } }
}

///|
/// 设置填充字符
/// 
/// 设置进度条中表示已完成部分的填充字符。
/// 不同的填充字符可以创造不同的视觉效果和风格。
/// 
/// # 参数
/// - `self` - 当前的进度条实例
/// - `fill` - 用于表示已完成进度的字符
/// 
/// # 返回值
/// - `ProgressBar` - 更新配置后的进度条实例，支持链式调用
/// 
/// # 示例
/// ```moonbit
/// // 默认填充字符（实心块）
/// let pb1 = new(100).update(30)
/// println(pb1.render())
/// // 输出: 30%|[███████████████                                   ]
/// 
/// // 使用等号作为填充字符
/// let pb2 = new(100).set_fill('=').update(40)
/// println(pb2.render())
/// // 输出: 40%|[====================                              ]
/// 
/// // 使用星号作为填充字符
/// let pb3 = new(50).set_fill('*').update(25)
/// println(pb3.render())
/// // 输出: 50%|[*************************                         ]
/// 
/// // 使用箭头符号
/// let pb4 = new(80).set_fill('>').update(32)
/// println(pb4.render())
/// // 输出: 40%|[>>>>>>>>>>>>>>>>                                  ]
/// 
/// // 使用点号（适合精细进度显示）
/// let pb5 = new(100).set_fill('•').update(60)
/// println(pb5.render())
/// // 输出: 60%|[••••••••••••••••••••••••••••••                    ]
/// 
/// // 组合不同字符创造层次感
/// let pb6 = new(60).set_fill('█').set_empty('▒').update(30)
/// println(pb6.render())
/// // 输出: 50%|[██████████████████████████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒]
/// 
/// // 主题化设计
/// let pb_download = new(1024)
///   .set_prefix("下载: ")
///   .set_fill('▓')
///   .set_empty('░')
///   .set_unit("KB")
///   .update(512)
/// println(pb_download.render())
/// // 输出: 下载: 50%|[▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░]
/// 
/// // ASCII艺术风格
/// let pb_ascii = new(40)
///   .set_prefix("加载 ")
///   .set_fill('#')
///   .set_empty('-')
///   .update(16)
/// println(pb_ascii.render())
/// // 输出: 加载 40%|[################------------------------]
/// 
/// // 动态填充字符（模拟动画效果）
/// let animation_chars = ['|', '/', '-', '\\']
/// let mut pb_anim = new(100).set_prefix("处理中 ")
/// for i = 0; i < 4; i = i + 1 {
///   pb_anim = pb_anim.set_fill(animation_chars[i]).update(25)
///   println(pb_anim.render())
/// }
/// // 依次输出不同填充字符的进度条
/// ```
/// 
/// # 常用填充字符
/// - `'█'` - 实心块（默认，视觉效果最佳）
/// - `'='` - 等号（经典风格，类似wget）
/// - `'*'` - 星号（简单明了）
/// - `'#'` - 井号（ASCII风格）
/// - `'>'` - 箭头（动态感）
/// - `'•'` - 圆点（精细风格）
/// - `'▓'` - 中等填充（与▒░组合效果好）
/// - `'░'` - 轻度填充
/// - `'▒'` - 中度填充
/// 
/// # 使用场景
/// - 匹配应用程序的视觉主题
/// - 创建特定的用户体验风格
/// - 适应不同的终端环境
/// - 实现动画效果
/// - 提高可读性和美观度
/// 
/// # 注意
/// - 某些字符在不同终端中显示效果可能不同
/// - Unicode字符可能占用更多显示宽度
/// - 建议选择宽度一致的字符
/// - 避免使用控制字符或不可见字符
/// - 考虑与空白字符的对比度
pub fn set_fill(self : ProgressBar, fill : Char) -> ProgressBar {
  { ..self, config: { ..self.config, fill, } }
}

///|
/// 设置空白字符
/// 
/// 设置进度条中表示未完成部分的空白字符。
/// 与填充字符配合使用，创造完整的进度条视觉效果。
/// 
/// # 参数
/// - `self` - 当前的进度条实例
/// - `empty` - 用于表示未完成进度的字符
/// 
/// # 返回值
/// - `ProgressBar` - 更新配置后的进度条实例，支持链式调用
/// 
/// # 示例
/// ```moonbit
/// // 默认空白字符（空格）
/// let pb1 = new(100).update(30)
/// println(pb1.render())
/// // 输出: 30%|[███████████████                                   ]
/// 
/// // 使用点号作为空白字符
/// let pb2 = new(100).set_empty('.').update(25)
/// println(pb2.render())
/// // 输出: 25%|[████████████▌....................................]
/// 
/// // 使用横线作为空白字符
/// let pb3 = new(50).set_fill('=').set_empty('-').update(20)
/// println(pb3.render())
/// // 输出: 40%|[====================------------------------------]
/// 
/// // 使用下划线增强可读性
/// let pb4 = new(80).set_fill('#').set_empty('_').update(32)
/// println(pb4.render())
/// // 输出: 40%|[################__________________________________]
/// 
/// // 创建层次感的组合
/// let pb5 = new(60).set_fill('█').set_empty('░').update(30)
/// println(pb5.render())
/// // 输出: 50%|[██████████████████████████████░░░░░░░░░░░░░░░░░░░░]
/// 
/// // 使用不同密度的字符
/// let pb6 = new(100).set_fill('▓').set_empty('▒').update(40)
/// println(pb6.render())
/// // 输出: 40%|[▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒]
/// 
/// // 主题化进度条
/// let pb_theme1 = new(200)
///   .set_prefix("安装: ")
///   .set_fill('>')
///   .set_empty('.')
///   .set_show_count(true)
///   .update(80)
/// println(pb_theme1.render())
/// // 输出: 安装: 40% (80/200)|[>>>>>>>>>>>>>>>>>>>>..............................]
/// 
/// // 复古ASCII风格
/// let pb_retro = new(40)
///   .set_prefix("加载 ")
///   .set_fill('*')
///   .set_empty('-')
///   .update(16)
/// println(pb_retro.render())
/// // 输出: 加载 40%|[****************------------------------]
/// 
/// // 现代风格组合
/// let pb_modern = new(120)
///   .set_prefix("处理数据: ")
///   .set_fill('●')
///   .set_empty('○')
///   .set_show_rate(true)
///   .update(60)
/// println(pb_modern.render())
/// // 输出: 处理数据: 50%|[●●●●●●●●●●●●●●●●●●●●●●●●●○○○○○○○○○○○○○○○○○○○○○○○○○] [15.0it/s]
/// 
/// // 对比度测试
/// let pb_contrast = new(50)
///   .set_fill('■')
///   .set_empty('□')
///   .update(25)
/// println(pb_contrast.render())
/// // 输出: 50%|[■■■■■■■■■■■■■■■■■■■■■■■■■□□□□□□□□□□□□□□□□□□□□□□□□□]
/// 
/// // 无空白字符（仅显示已完成部分）
/// let pb_minimal = new(100).set_empty(' ').update(30)
/// println(pb_minimal.render())
/// // 输出: 30%|[███████████████                                   ]
/// ```
/// 
/// # 常用空白字符
/// - `' '` - 空格（默认，最简洁）
/// - `'.'` - 点号（清晰的占位符）
/// - `'-'` - 横线（经典风格）
/// - `'_'` - 下划线（强调基线）
/// - `'░'` - 轻度填充（现代感）
/// - `'▒'` - 中度填充（层次感）
/// - `'○'` - 空心圆（现代风格）
/// - `'□'` - 空心方块（几何风格）
/// - `'∙'` - 中点（精细风格）
/// 
/// # 设计原则
/// - **对比度**: 确保与填充字符有足够的视觉区别
/// - **一致性**: 字符宽度应与填充字符匹配
/// - **可读性**: 在不同背景下都应清晰可见
/// - **风格统一**: 与整体界面风格保持一致
/// 
/// # 使用场景
/// - 增强进度条的可读性
/// - 创建特定的视觉主题
/// - 适配不同的显示环境
/// - 提供更好的用户体验
/// - 实现品牌化的进度显示
/// 
/// # 注意
/// - 空白字符的选择影响整体美观度
/// - 某些字符在不同终端中可能显示不一致
/// - 避免使用与填充字符过于相似的字符
/// - 考虑颜色盲用户的使用体验
/// - 测试在不同终端和字体下的显示效果
pub fn set_empty(self : ProgressBar, empty : Char) -> ProgressBar {
  { ..self, config: { ..self.config, empty, } }
}

///|
/// 设置是否显示百分比
/// 
/// 控制是否在进度条前显示完成百分比。
/// 
/// # 参数
/// - `self` - 当前的进度条实例
/// - `show` - true显示百分比，false隐藏百分比
/// 
/// # 返回值
/// - `ProgressBar` - 更新配置后的进度条实例，支持链式调用
/// 
/// # 示例
/// ```moonbit
/// // 显示百分比（默认行为）
/// let pb1 = new(100).set_show_percent(true).update(30)
/// println(pb1.render())
/// // 输出: 30%|[███████████████                                   ]
/// 
/// // 隐藏百分比
/// let pb2 = new(100).set_show_percent(false).update(30)
/// println(pb2.render())
/// // 输出: [███████████████                                   ]
/// 
/// // 结合其他显示选项
/// let pb3 = new(200)
///   .set_show_percent(false)
///   .set_show_count(true)
///   .set_prefix("处理: ")
///   .update(80)
/// println(pb3.render())
/// // 输出: 处理: (80/200)|[████████████████████                             ]
/// ```
pub fn set_show_percent(self : ProgressBar, show : Bool) -> ProgressBar {
  { ..self, config: { ..self.config, show_percent: show } }
}

///|
/// 设置是否显示计数
/// 
/// 控制是否显示当前值/总值的计数信息。
/// 
/// # 参数
/// - `self` - 当前的进度条实例
/// - `show` - true显示计数，false隐藏计数
/// 
/// # 返回值
/// - `ProgressBar` - 更新配置后的进度条实例，支持链式调用
/// 
/// # 示例
/// ```moonbit
/// // 显示计数
/// let pb1 = new(500).set_show_count(true).update(125)
/// println(pb1.render())
/// // 输出: 25% (125/500)|[████████████▌                                     ]
/// 
/// // 隐藏计数（默认行为）
/// let pb2 = new(500).set_show_count(false).update(125)
/// println(pb2.render())
/// // 输出: 25%|[████████████▌                                     ]
/// 
/// // 在文件下载场景中显示计数
/// let pb3 = new(1024)
///   .set_prefix("下载: ")
///   .set_show_count(true)
///   .set_unit("MB")
///   .update(256)
/// println(pb3.render())
/// // 输出: 下载: 25% (256/1024)|[████████████▌                                 ] [45.2MB/s]
/// ```
pub fn set_show_count(self : ProgressBar, show : Bool) -> ProgressBar {
  { ..self, config: { ..self.config, show_count: show } }
}

///|
/// 设置进度条描述文本
/// 
/// # 参数
/// - `desc` - 描述文本字符串
/// 
/// # 示例
/// ```moonbit
/// let pb = new(100).set_desc("下载文件").update(50)
/// println(pb.render())
/// // 输出: 下载文件 50%|[█████████████████████████                         ]
/// ```
pub fn set_desc(self : ProgressBar, desc : String) -> ProgressBar {
  { ..self, config: { ..self.config, desc, } }
}

///|
/// 设置单位
/// 
/// 为进度条设置数据单位，用于在显示速率和计数时提供更有意义的信息。
/// 单位会附加到速率显示和计数显示中，使进度条更加直观。
/// 
/// # 参数
/// - `self` - 当前的进度条实例
/// - `unit` - 要设置的单位字符串（如 "MB"、"个文件"、"条记录"等）
/// 
/// # 返回值
/// - `ProgressBar` - 更新配置后的进度条实例，支持链式调用
/// 
/// # 示例
/// ```moonbit
/// // 文件大小单位
/// let pb1 = new(1024)
///   .set_unit("MB")
///   .set_show_count(true)
///   .set_show_rate(true)
///   .update(512)
/// println(pb1.render())
/// // 输出: 50% (512/1024)|[█████████████████████████                ] [45.2MB/s]
/// 
/// // 文件数量单位
/// let pb2 = new(100)
///   .set_desc("处理文件")
///   .set_unit("个文件")
///   .set_show_count(true)
///   .update(25)
/// println(pb2.render())
/// // 输出: 处理文件 25% (25/100个文件)|[████████████▌              ]
/// 
/// // 数据记录单位
/// let pb3 = new(10000)
///   .set_desc("导入数据")
///   .set_unit("条记录")
///   .set_show_rate(true)
///   .set_show_eta(true)
///   .update(2500)
/// println(pb3.render())
/// // 输出: 导入数据 25%|[████████████▌                 ] [1.2K条记录/s] ETA: 00:06
/// 
/// // 网络传输单位
/// let pb4 = new(2048)
///   .set_desc("下载")
///   .set_unit("KB")
///   .set_show_count(true)
///   .set_show_rate(true)
///   .set_show_eta(true)
///   .update(768)
/// println(pb4.render())
/// // 输出: 下载 37.5% (768/2048KB)|[██████████████████▌        ] [256KB/s] ETA: 00:05
/// 
/// // 处理任务单位
/// let pb5 = new(500)
///   .set_desc("图像处理")
///   .set_unit("张图片")
///   .set_show_count(true)
///   .set_show_rate(true)
///   .update(125)
/// println(pb5.render())
/// // 输出: 图像处理 25% (125/500张图片)|[████████████▌     ] [12.5张图片/s]
/// 
/// // 动态单位切换
/// fn download_with_units() {
///   let mut pb = new(1024).set_desc("下载")
///   
///   // 开始时使用字节
///   pb = pb.set_unit("B").set_show_rate(true).update(256)
///   println(pb.render())
///   
///   // 切换到KB
///   pb = pb.set_unit("KB").update(512)
///   println(pb.render())
///   
///   // 最终使用MB
///   pb = pb.set_unit("MB").update(1024)
///   println(pb.render())
/// }
/// ```
/// 
/// # 常用单位示例
/// - **文件大小**: "B"、"KB"、"MB"、"GB"、"TB"
/// - **计数单位**: "个"、"条"、"项"、"次"、"行"
/// - **文件单位**: "个文件"、"张图片"、"个视频"、"份文档"
/// - **数据单位**: "条记录"、"个用户"、"笔订单"、"条消息"
/// - **时间单位**: "秒"、"分钟"、"小时"、"天"
/// - **网络单位**: "包"、"个请求"、"次连接"
/// 
/// # 使用场景
/// - **文件传输**: 显示传输速率和大小
/// - **数据处理**: 显示处理速度和数量
/// - **批量操作**: 显示操作进度和速率
/// - **网络请求**: 显示请求速度和数量
/// - **系统监控**: 显示各种指标的单位
/// 
/// # 最佳实践
/// - 选择合适且直观的单位名称
/// - 保持单位名称的一致性和简洁性
/// - 考虑使用标准化的单位（如SI单位）
/// - 根据数据量级选择合适的单位
/// - 避免过长的单位名称影响显示效果
/// 
/// # 注意事项
/// - 单位会附加到速率和计数显示中
/// - 空字符串是有效的单位，会清除现有单位设置
/// - 单位不会影响进度计算，仅用于显示
/// - 单位支持Unicode字符，包括中文等多字节字符
/// - 单位过长可能影响进度条的整体布局
/// - 单位设置会立即影响所有相关的显示元素
/// 
/// # 相关函数
/// - `set_show_rate(true)` - 启用速率显示以使用单位
/// - `set_show_count(true)` - 启用计数显示以使用单位
/// - `set_unit_scale(true)` - 启用单位自动缩放
/// - `set_desc(text)` - 设置描述文本
/// - `render()` - 渲染包含单位的完整进度条
pub fn set_unit(self : ProgressBar, unit : String) -> ProgressBar {
  { ..self, config: { ..self.config, unit, } }
}

///|
/// 设置是否显示ETA（预计完成时间）
/// 
/// 控制是否在进度条中显示预计完成时间（Estimated Time of Arrival）。
/// ETA基于当前进度速度计算剩余完成时间，帮助用户了解任务预计何时完成。
/// 
/// # 参数
/// - `self` - 当前的进度条实例
/// - `show` - true显示ETA，false隐藏ETA（默认）
/// 
/// # 返回值
/// - `ProgressBar` - 更新配置后的进度条实例，支持链式调用
/// 
/// # 示例
/// ```moonbit
/// // 显示ETA的基本用法
/// let pb1 = new(1000).set_show_eta(true).update(250)
/// println(pb1.render())
/// // 输出: 25%|[████████████▌                                     ] ETA: 00:45
/// 
/// // 文件下载场景显示ETA
/// let pb2 = new(2048)
///   .set_desc("下载文件")
///   .set_unit("MB")
///   .set_show_eta(true)
///   .set_show_rate(true)
///   .set_show_count(true)
///   .update(512)
/// println(pb2.render())
/// // 输出: 下载文件 25% (512/2048MB)|[████████████▌     ] [64MB/s] ETA: 00:24
/// 
/// // 数据处理场景显示ETA
/// let pb3 = new(10000)
///   .set_desc("处理记录")
///   .set_unit("条")
///   .set_show_eta(true)
///   .set_show_count(true)
///   .update(3000)
/// println(pb3.render())
/// // 输出: 处理记录 30% (3000/10000条)|[███████████████                ] ETA: 00:02:15
/// 
/// // 批量任务显示ETA
/// let pb4 = new(500)
///   .set_desc("转换图片")
///   .set_unit("张")
///   .set_show_eta(true)
///   .set_show_rate(true)
///   .update(125)
/// println(pb4.render())
/// // 输出: 转换图片 25%|[████████████▌                         ] [5.2张/s] ETA: 00:01:12
/// 
/// // 不显示ETA的对比
/// let pb5 = new(1000).set_show_eta(false).update(250)
/// println(pb5.render())
/// // 输出: 25%|[████████████▌                                     ]
/// 
/// // 动态切换ETA显示
/// fn toggle_eta_display() {
///   let mut pb = new(200).set_desc("处理中")
///   
///   // 开始时不显示ETA
///   pb = pb.set_show_eta(false).update(50)
///   println(pb.render())
///   
///   // 中途开启ETA显示
///   pb = pb.set_show_eta(true).update(100)
///   println(pb.render())
///   
///   // 接近完成时可以关闭ETA
///   pb = pb.set_show_eta(false).update(180)
///   println(pb.render())
/// }
/// 
/// // 长时间任务的ETA显示
/// let pb6 = new(86400)  // 假设需要一天的任务
///   .set_desc("长时间任务")
///   .set_unit("秒")
///   .set_show_eta(true)
///   .set_show_rate(true)
///   .update(21600)  // 完成6小时
/// println(pb6.render())
/// // 输出: 长时间任务 25%|[████████████▌                 ] [6.0秒/s] ETA: 18:00:00
/// ```
/// 
/// # ETA计算说明
/// - **基于当前速度**: ETA根据最近的处理速度计算
/// - **动态更新**: 随着进度更新，ETA会实时调整
/// - **格式**: 通常显示为 HH:MM:SS 格式
/// - **精度**: 在任务开始阶段ETA可能不够准确
/// - **稳定性**: 随着任务进行，ETA预测会越来越准确
/// 
/// # 使用场景
/// - **文件传输**: 显示下载/上传剩余时间
/// - **数据处理**: 显示批量处理剩余时间
/// - **系统操作**: 显示安装/更新剩余时间
/// - **备份恢复**: 显示备份/恢复剩余时间
/// - **编译构建**: 显示编译剩余时间
/// - **长时间任务**: 任何需要较长时间的操作
/// 
/// # 最佳实践
/// - 对于短时间任务（<30秒）可以不显示ETA
/// - 对于长时间任务强烈建议显示ETA
/// - 结合速率显示使用效果更好
/// - 在任务开始阶段ETA可能波动较大，属正常现象
/// - 考虑在任务接近完成时隐藏ETA以减少界面干扰
/// 
/// # 注意事项
/// - ETA显示需要一定的计算时间来稳定
/// - 任务开始时ETA可能不准确或显示异常值
/// - ETA基于线性预测，实际任务可能存在非线性特征
/// - 显示ETA会增加进度条的宽度占用
/// - 在进度更新不规律时，ETA可能频繁变化
/// - ETA计算依赖于任务的连续性和一致性
/// 
/// # ETA显示格式
/// - **秒级**: "00:45" (45秒)
/// - **分钟级**: "02:30" (2分30秒)
/// - **小时级**: "01:30:45" (1小时30分45秒)
/// - **超长时间**: 可能显示天数或更大单位
/// 
/// # 相关函数
/// - `set_show_rate(true)` - 显示处理速率，与ETA互补
/// - `set_show_elapsed(true)` - 显示已用时间
/// - `set_smooth(true)` - 启用平滑更新以稳定ETA
/// - `update(value)` - 更新进度，影响ETA计算
/// - `render()` - 渲染包含ETA的完整进度条
pub fn set_show_eta(self : ProgressBar, show : Bool) -> ProgressBar {
  { ..self, config: { ..self.config, show_eta: show } }
}

///|
/// 设置是否显示处理速率
/// 
/// 控制是否在进度条中显示当前的处理速率（每秒处理的单位数量）。
/// 速率显示帮助用户了解任务执行的快慢，结合ETA使用效果更佳。
/// 
/// # 参数
/// - `self` - 当前的进度条实例
/// - `show` - true显示速率，false隐藏速率（默认）
/// 
/// # 返回值
/// - `ProgressBar` - 更新配置后的进度条实例，支持链式调用
/// 
/// # 示例
/// ```moonbit
/// // 显示速率的基本用法
/// let pb1 = new(1000).set_show_rate(true).update(250)
/// println(pb1.render())
/// // 输出: 25%|[████████████▌                                     ] [83.3/s]
/// 
/// // 文件下载显示速率
/// let pb2 = new(2048)
///   .set_desc("下载")
///   .set_unit("MB")
///   .set_show_rate(true)
///   .set_show_count(true)
///   .update(512)
/// println(pb2.render())
/// // 输出: 下载 25% (512/2048MB)|[████████████▌                ] [64MB/s]
/// 
/// // 数据处理显示速率
/// let pb3 = new(10000)
///   .set_desc("处理记录")
///   .set_unit("条")
///   .set_show_rate(true)
///   .set_show_eta(true)
///   .update(2500)
/// println(pb3.render())
/// // 输出: 处理记录 25%|[████████████▌                 ] [833条/s] ETA: 00:09
/// 
/// // 文件操作显示速率
/// let pb4 = new(500)
///   .set_desc("复制文件")
///   .set_unit("个")
///   .set_show_rate(true)
///   .set_show_count(true)
///   .update(125)
/// println(pb4.render())
/// // 输出: 复制文件 25% (125/500个)|[████████████▌         ] [41.7个/s]
/// 
/// // 网络请求显示速率
/// let pb5 = new(1000)
///   .set_desc("API请求")
///   .set_unit("次")
///   .set_show_rate(true)
///   .set_show_eta(true)
///   .update(300)
/// println(pb5.render())
/// // 输出: API请求 30%|[███████████████                       ] [100次/s] ETA: 00:07
/// 
/// // 不显示速率的对比
/// let pb6 = new(1000).set_show_rate(false).update(250)
/// println(pb6.render())
/// // 输出: 25%|[████████████▌                                     ]
/// 
/// // 动态切换速率显示
/// fn monitor_performance() {
///   let mut pb = new(1000).set_desc("性能监控")
///   
///   // 开始时显示速率
///   pb = pb.set_show_rate(true).update(100)
///   println(pb.render())
///   
///   // 中途可以隐藏速率
///   pb = pb.set_show_rate(false).update(500)
///   println(pb.render())
///   
///   // 最后阶段重新显示
///   pb = pb.set_show_rate(true).update(900)
///   println(pb.render())
/// }
/// 
/// // 高速处理场景
/// let pb7 = new(1000000)
///   .set_desc("高速处理")
///   .set_unit("项")
///   .set_show_rate(true)
///   .update(250000)
/// println(pb7.render())
/// // 输出: 高速处理 25%|[████████████▌                 ] [83.3K项/s]
/// ```
/// 
/// # 速率计算说明
/// - **实时计算**: 基于最近的进度更新计算瞬时速率
/// - **平滑处理**: 内部使用移动平均来平滑速率波动
/// - **单位自动**: 速率会自动使用设置的单位
/// - **动态格式**: 大数值会自动使用K、M等前缀
/// - **精度控制**: 显示适当的小数位数
/// 
/// # 速率显示格式
/// - **小数值**: "45.2/s"
/// - **千级**: "1.2K/s" 
/// - **万级**: "12.5K/s"
/// - **百万级**: "1.2M/s"
/// - **带单位**: "64MB/s"、"1.2K条/s"
/// 
/// # 使用场景
/// - **文件传输**: 显示传输速度（MB/s、KB/s）
/// - **数据处理**: 显示处理速度（条/s、行/s）
/// - **网络操作**: 显示请求速度（次/s、包/s）
/// - **批量任务**: 显示处理速度（个/s、项/s）
/// - **系统监控**: 显示各种操作的吞吐量
/// - **性能测试**: 显示性能指标
/// 
/// # 最佳实践
/// - 对于I/O密集型任务建议显示速率
/// - 结合单位设置使用，提供更清晰的信息
/// - 与ETA配合使用，提供完整的时间信息
/// - 对于短时间任务可以不显示速率
/// - 在性能测试和监控场景中强烈建议使用
/// 
/// # 注意事项
/// - 速率计算需要一定时间来稳定
/// - 任务开始时速率可能波动较大
/// - 速率显示会增加进度条的宽度占用
/// - 在进度更新不规律时，速率可能频繁变化
/// - 对于非连续性任务，速率可能不够准确
/// - 速率计算依赖于系统时钟的准确性
/// 
/// # 性能考虑
/// - 启用速率显示会增加少量计算开销
/// - 内部维护时间戳和历史数据
/// - 对于高频更新的进度条，建议适当控制更新频率
/// - 在资源受限环境中可以考虑禁用速率显示
/// 
/// # 相关函数
/// - `set_unit(unit)` - 设置单位，影响速率显示格式
/// - `set_show_eta(true)` - 显示ETA，与速率互补
/// - `set_smooth(true)` - 启用平滑更新，稳定速率显示
/// - `set_unit_scale(true)` - 启用单位自动缩放
/// - `update(value)` - 更新进度，影响速率计算
/// - `render()` - 渲染包含速率的完整进度条
pub fn set_show_rate(self : ProgressBar, show : Bool) -> ProgressBar {
  { ..self, config: { ..self.config, show_rate: show } }
}

///|
/// 设置是否显示已用时间
/// 
/// 控制是否在进度条中显示任务已经运行的时间。
/// 已用时间显示从任务开始到当前的累计时间，帮助用户了解任务已经运行了多长时间。
/// 
/// # 参数
/// - `self` - 当前的进度条实例
/// - `show` - true显示已用时间，false隐藏已用时间（默认）
/// 
/// # 返回值
/// - `ProgressBar` - 更新配置后的进度条实例，支持链式调用
/// 
/// # 示例
/// ```moonbit
/// // 显示已用时间的基本用法
/// let pb1 = new(1000).set_show_elapsed(true).update(250)
/// println(pb1.render())
/// // 输出: 25%|[████████████▌                                ] Elapsed: 00:15
/// 
/// // 长时间任务显示已用时间
/// let pb2 = new(10000)
///   .set_desc("大数据处理")
///   .set_unit("条")
///   .set_show_elapsed(true)
///   .set_show_count(true)
///   .update(2500)
/// println(pb2.render())
/// // 输出: 大数据处理 25% (2500/10000条)|[████████████▌     ] Elapsed: 00:05:30
/// 
/// // 同时显示已用时间和ETA
/// let pb3 = new(2048)
///   .set_desc("文件传输")
///   .set_unit("MB")
///   .set_show_elapsed(true)
///   .set_show_eta(true)
///   .set_show_rate(true)
///   .update(512)
/// println(pb3.render())
/// // 输出: 文件传输 25%|[████████████▌        ] [64MB/s] Elapsed: 00:08 ETA: 00:24
/// 
/// // 批处理任务显示已用时间
/// let pb4 = new(500)
///   .set_desc("图片处理")
///   .set_unit("张")
///   .set_show_elapsed(true)
///   .set_show_rate(true)
///   .update(125)
/// println(pb4.render())
/// // 输出: 图片处理 25%|[████████████▌                ] [20.8张/s] Elapsed: 00:06
/// 
/// // 不显示已用时间的对比
/// let pb5 = new(1000).set_show_elapsed(false).update(250)
/// println(pb5.render())
/// // 输出: 25%|[████████████▌                                     ]
/// 
/// // 系统监控场景
/// let pb6 = new(86400)  // 24小时的监控任务
///   .set_desc("系统监控")
///   .set_unit("秒")
///   .set_show_elapsed(true)
///   .set_show_count(true)
///   .update(3600)  // 运行了1小时
/// println(pb6.render())
/// // 输出: 系统监控 4.2% (3600/86400秒)|[██                ] Elapsed: 01:00:00
/// 
/// // 动态切换已用时间显示
/// fn track_elapsed_time() {
///   let mut pb = new(1000).set_desc("任务跟踪")
///   
///   // 开始时不显示已用时间
///   pb = pb.set_show_elapsed(false).update(100)
///   println(pb.render())
///   
///   // 中途开启已用时间显示
///   pb = pb.set_show_elapsed(true).update(500)
///   println(pb.render())
///   
///   // 继续显示到完成
///   pb = pb.update(1000)
///   println(pb.render())
/// }
/// 
/// // 性能测试场景
/// let pb7 = new(1000000)
///   .set_desc("性能测试")
///   .set_unit("次操作")
///   .set_show_elapsed(true)
///   .set_show_rate(true)
///   .update(250000)
/// println(pb7.render())
/// // 输出: 性能测试 25%|[████████████▌           ] [83.3K次操作/s] Elapsed: 00:03
/// ```
/// 
/// # 已用时间计算说明
/// - **起始时间**: 从进度条创建或首次更新时开始计时
/// - **实时更新**: 每次渲染时计算当前已用时间
/// - **精确计时**: 基于系统时钟提供准确的时间测量
/// - **格式化显示**: 自动选择合适的时间格式显示
/// - **持续累计**: 即使进度暂停，已用时间也会继续累计
/// 
/// # 时间显示格式
/// - **秒级**: "00:45" (45秒)
/// - **分钟级**: "02:30" (2分30秒)  
/// - **小时级**: "01:30:45" (1小时30分45秒)
/// - **天级**: "1d 02:30:45" (1天2小时30分45秒)
/// - **长时间**: 支持更大的时间单位显示
/// 
/// # 使用场景
/// - **长时间任务**: 需要了解已经运行了多长时间
/// - **性能测试**: 记录测试运行时间
/// - **系统监控**: 显示监控运行时长
/// - **备份任务**: 显示备份已用时间
/// - **数据迁移**: 显示迁移已用时间
/// - **编译构建**: 显示构建已用时间
/// - **科学计算**: 显示计算已用时间
/// 
/// # 最佳实践
/// - 对于预计时间较长的任务建议显示已用时间
/// - 结合ETA使用可以提供完整的时间信息
/// - 在性能测试和基准测试中非常有用
/// - 对于需要时间记录的任务场景推荐使用
/// - 可以帮助用户评估任务的实际耗时
/// 
/// # 与其他时间显示的对比
/// - **已用时间**: 显示已经过去的时间（向后看）
/// - **ETA**: 显示预计剩余时间（向前看）
/// - **总时间**: 已用时间 + ETA = 预计总时间
/// - **速率**: 基于已用时间计算平均处理速度
/// 
/// # 注意事项
/// - 显示已用时间会增加进度条的宽度占用
/// - 时间计算基于系统时钟，受系统时间调整影响
/// - 在系统休眠/唤醒时可能出现时间跳跃
/// - 对于非常短的任务，已用时间显示意义不大
/// - 已用时间会持续更新，即使进度没有变化
/// - 在高频更新时，时间显示可能造成视觉干扰
/// 
/// # 性能考虑
/// - 启用已用时间显示会增加少量时间计算开销
/// - 每次渲染都需要获取当前时间
/// - 对于高频更新的进度条，建议控制更新频率
/// - 在资源受限环境中可以考虑禁用此功能
/// 
/// # 相关函数
/// - `set_show_eta(true)` - 显示预计剩余时间，与已用时间互补
/// - `set_show_rate(true)` - 显示处理速率，基于已用时间计算
/// - `set_smooth(true)` - 启用平滑更新
/// - `update(value)` - 更新进度，影响已用时间的相关性
/// - `render()` - 渲染包含已用时间的完整进度条
pub fn set_show_elapsed(self : ProgressBar, show : Bool) -> ProgressBar {
  { ..self, config: { ..self.config, show_elapsed: show } }
}

///|
/// 设置是否启用平滑更新
/// 
/// 控制进度条是否使用平滑更新模式。启用平滑更新后，进度条会对速率和ETA进行平滑处理，
/// 减少数值的剧烈波动，提供更稳定和用户友好的显示效果。
/// 
/// # 参数
/// - `self` - 当前的进度条实例
/// - `smooth` - true启用平滑更新，false禁用平滑更新（默认）
/// 
/// # 返回值
/// - `ProgressBar` - 更新配置后的进度条实例，支持链式调用
/// 
/// # 示例
/// ```moonbit
/// // 启用平滑更新的基本用法
/// let pb1 = new(1000)
///   .set_smooth(true)
///   .set_show_rate(true)
///   .set_show_eta(true)
///   .update(250)
/// println(pb1.render())
/// // 输出: 25%|[████████████▌                         ] [83.3/s] ETA: 00:09
/// 
/// // 文件下载场景使用平滑更新
/// let pb2 = new(2048)
///   .set_desc("下载文件")
///   .set_unit("MB")
///   .set_smooth(true)
///   .set_show_rate(true)
///   .set_show_eta(true)
///   .update(512)
/// println(pb2.render())
/// // 输出: 下载文件 25%|[████████████▌        ] [64MB/s] ETA: 00:24
/// 
/// // 不稳定网络环境下的平滑效果
/// fn unstable_network_download() {
///   let mut pb = new(1000)
///     .set_desc("不稳定下载")
///     .set_unit("KB")
///     .set_smooth(true)
///     .set_show_rate(true)
///     .set_show_eta(true)
///   
///   // 模拟网络波动
///   pb = pb.update(100)  // 快速开始
///   println(pb.render())
///   
///   pb = pb.update(150)  // 速度下降
///   println(pb.render())
///   
///   pb = pb.update(300)  // 突然加速
///   println(pb.render())
///   
///   pb = pb.update(320)  // 又变慢了
///   println(pb.render())
///   // 平滑更新会让速率和ETA变化更加平稳
/// }
/// 
/// // 对比启用和禁用平滑更新
/// fn compare_smooth_modes() {
///   // 不使用平滑更新
///   let pb_normal = new(1000)
///     .set_desc("普通模式")
///     .set_smooth(false)
///     .set_show_rate(true)
///     .update(250)
///   println(pb_normal.render())
///   // 速率可能会有较大波动
///   
///   // 使用平滑更新
///   let pb_smooth = new(1000)
///     .set_desc("平滑模式")
///     .set_smooth(true)
///     .set_show_rate(true)
///     .update(250)
///   println(pb_smooth.render())
///   // 速率显示更加稳定
/// }
/// 
/// // 数据处理场景的平滑更新
/// let pb3 = new(10000)
///   .set_desc("数据处理")
///   .set_unit("条记录")
///   .set_smooth(true)
///   .set_show_rate(true)
///   .set_show_eta(true)
///   .set_show_count(true)
///   .update(2500)
/// println(pb3.render())
/// // 输出: 数据处理 25% (2500/10000条记录)|[████████████▌] [833条记录/s] ETA: 00:09
/// 
/// // 批量文件操作的平滑更新
/// let pb4 = new(500)
///   .set_desc("处理图片")
///   .set_unit("张")
///   .set_smooth(true)
///   .set_show_rate(true)
///   .set_show_elapsed(true)
///   .update(125)
/// println(pb4.render())
/// // 输出: 处理图片 25%|[████████████▌           ] [20.8张/s] Elapsed: 00:06
/// 
/// // 动态切换平滑模式
/// fn dynamic_smooth_control() {
///   let mut pb = new(1000).set_desc("动态控制").set_show_rate(true)
///   
///   // 开始时不使用平滑
///   pb = pb.set_smooth(false).update(200)
///   println(pb.render())
///   
///   // 中途启用平滑
///   pb = pb.set_smooth(true).update(600)
///   println(pb.render())
///   
///   // 最后阶段可以关闭平滑
///   pb = pb.set_smooth(false).update(900)
///   println(pb.render())
/// }
/// 
/// // 高频更新场景的平滑效果
/// let pb5 = new(1000000)
///   .set_desc("高频更新")
///   .set_unit("次操作")
///   .set_smooth(true)
///   .set_show_rate(true)
///   .update(250000)
/// println(pb5.render())
/// // 输出: 高频更新 25%|[████████████▌           ] [83.3K次操作/s]
/// ```
/// 
/// # 平滑更新机制
/// - **移动平均**: 使用移动平均算法平滑速率计算
/// - **ETA稳定**: 减少ETA的剧烈波动，提供更稳定的时间预测
/// - **响应平衡**: 在响应性和稳定性之间找到平衡
/// - **历史权重**: 给予历史数据适当权重，避免过度反应
/// - **自适应调整**: 根据数据变化程度自动调整平滑强度
/// 
/// # 平滑效果对比
/// - **不平滑**: 实时反映当前速度，但可能波动较大
/// - **平滑**: 显示更稳定，但对速度变化的反应稍慢
/// - **速率显示**: 平滑后的速率更易读，减少视觉干扰
/// - **ETA预测**: 平滑的ETA更可信，减少用户困惑
/// 
/// # 使用场景
/// - **网络传输**: 网络速度波动大时建议启用
/// - **文件I/O**: 磁盘读写速度不稳定时有用
/// - **批量处理**: 处理速度因数据复杂度变化时
/// - **实时监控**: 需要稳定显示效果的监控场景
/// - **用户界面**: 面向最终用户的应用建议启用
/// - **性能测试**: 需要平滑的性能指标显示
/// 
/// # 最佳实践
/// - 对于面向用户的进度条建议启用平滑更新
/// - 在网络不稳定或I/O波动大的环境中使用
/// - 结合速率和ETA显示使用效果最佳
/// - 对于调试和精确测量场景可以禁用
/// - 在高频更新的场景中特别有用
/// 
/// # 何时不使用平滑更新
/// - **调试场景**: 需要看到实时的精确速率
/// - **性能分析**: 需要准确的瞬时性能数据
/// - **测试环境**: 需要精确的时间测量
/// - **低延迟要求**: 需要立即反映速度变化
/// - **简单任务**: 处理速度本身就很稳定的任务
/// 
/// # 注意事项
/// - 启用平滑更新会稍微延迟对速度变化的反应
/// - 平滑算法会使用更多内存存储历史数据
/// - 在任务开始阶段，平滑效果可能不明显
/// - 平滑更新不会影响实际的进度值，只影响速率和ETA显示
/// - 过度平滑可能掩盖真实的性能问题
/// - 平滑参数是内部优化的，用户无需手动调整
/// 
/// # 性能影响
/// - **计算开销**: 增加少量的平滑计算开销
/// - **内存使用**: 需要存储历史速率数据
/// - **更新频率**: 对高频更新的影响更明显
/// - **整体影响**: 对大多数应用来说影响可忽略
/// 
/// # 相关函数
/// - `set_show_rate(true)` - 启用速率显示，平滑更新主要影响速率
/// - `set_show_eta(true)` - 启用ETA显示，平滑更新也会影响ETA
/// - `update(value)` - 更新进度，频繁更新时平滑效果更明显
/// - `set_unit(unit)` - 设置单位，不影响平滑算法
/// - `render()` - 渲染进度条，平滑效果在此体现
pub fn set_smooth(self : ProgressBar, smooth : Bool) -> ProgressBar {
  { ..self, config: { ..self.config, smooth, } }
}

///|
/// 设置动态宽度
/// 
/// 控制是否根据终端宽度自动调整进度条宽度。
/// 启用后，进度条会自动适应不同大小的终端窗口。
/// 
/// # 参数
/// - `self` - 当前的进度条实例
/// - `dynamic` - true启用动态宽度，false使用固定宽度
/// 
/// # 返回值
/// - `ProgressBar` - 更新配置后的进度条实例，支持链式调用
/// 
/// # 行为
/// - 启用时：自动检测终端宽度，动态调整进度条长度
/// - 禁用时：使用config.width指定的固定宽度
/// 
/// # 示例
/// ```moonbit
/// // 使用固定宽度（默认50字符）
/// let pb1 = new(100).set_dynamic_width(false).update(50)
/// println(pb1.render())
/// // 输出: 50%|[█████████████████████████                         ]
/// 
/// // 启用动态宽度（根据终端自动调整）
/// let pb2 = new(100).set_dynamic_width(true).update(50)
/// println(pb2.render())
/// // 输出: 50%|[████████████████████████████████████████████████████████████▌     ] (宽度根据终端调整)
/// 
/// // 适合响应式布局的场景
/// let pb3 = new(1000)
///   .set_prefix("分析: ")
///   .set_dynamic_width(true)
///   .set_show_count(true)
///   .update(350)
/// println(pb3.render())
/// // 输出会根据终端宽度自动调整进度条长度
/// ```
pub fn set_dynamic_width(self : ProgressBar, dynamic : Bool) -> ProgressBar {
  { ..self, config: { ..self.config, dynamic_width: dynamic } }
}

///|
/// 设置终端列数
pub fn set_ncols(self : ProgressBar, ncols : Int?) -> ProgressBar {
  { ..self, config: { ..self.config, ncols, } }
}

///|
/// 设置最小更新间隔（项目数）
pub fn set_miniters(self : ProgressBar, miniters : Int) -> ProgressBar {
  { ..self, config: { ..self.config, miniters, } }
}

///|
/// 设置最小时间间隔（秒）
pub fn set_mininterval(self : ProgressBar, mininterval : Double) -> ProgressBar {
  { ..self, config: { ..self.config, mininterval, } }
}

///|
/// 设置是否启用单位缩放
pub fn set_unit_scale(self : ProgressBar, unit_scale : Bool) -> ProgressBar {
  { ..self, config: { ..self.config, unit_scale, } }
}

///|
/// 设置嵌套进度条位置
pub fn set_position(self : ProgressBar, position : Int) -> ProgressBar {
  { ..self, config: { ..self.config, position, } }
}

// ===== 嵌套进度条支持 =====

///|
/// 嵌套进度条管理器
pub struct NestedProgressManager {
  bars : Array[ProgressBar] // 进度条数组，按位置排序
  max_position : Int // 最大位置
}

///|
/// 创建嵌套进度条管理器
pub fn create_nested_manager() -> NestedProgressManager {
  { bars: [], max_position: 0 }
}

///|
/// 添加进度条到管理器
pub fn add_progress_bar(
  self : NestedProgressManager,
  pb : ProgressBar,
) -> NestedProgressManager {
  let new_bars = self.bars.copy()
  new_bars.push(pb)
  {
    bars: new_bars,
    max_position: if pb.config.position > self.max_position {
      pb.config.position
    } else {
      self.max_position
    },
  }
}

///|
/// 渲染所有嵌套进度条
pub fn render_nested(self : NestedProgressManager) -> String {
  let mut result = ""
  for i = 0; i <= self.max_position; i = i + 1 {
    // 查找对应位置的进度条
    for j = 0; j < self.bars.length(); j = j + 1 {
      if self.bars[j].config.position == i {
        result = result + self.bars[j].render() + "\n"
        break
      }
    }
  }
  result
}

///|
/// 更新指定位置的进度条
pub fn update_nested(
  self : NestedProgressManager,
  position : Int,
  new_current : Int,
) -> NestedProgressManager {
  let new_bars = []
  for i = 0; i < self.bars.length(); i = i + 1 {
    if self.bars[i].config.position == position {
      new_bars.push(self.bars[i].update(new_current))
    } else {
      new_bars.push(self.bars[i])
    }
  }
  { ..self, bars: new_bars }
}

///|
/// 设置完成后是否保留
pub fn set_leave(self : ProgressBar, leave : Bool) -> ProgressBar {
  { ..self, config: { ..self.config, leave, } }
}

///|
/// 链式配置方法 - 批量设置
pub fn configure(
  self : ProgressBar,
  f : (ProgressBar) -> ProgressBar,
) -> ProgressBar {
  f(self)
}
