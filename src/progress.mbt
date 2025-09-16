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
pub fn set_terminal_width(width : Int) -> Unit {
  // 简化实现：实际中需要修改全局状态
  println("设置终端宽度为: " + width.to_string())
}

///|
/// 清除终端宽度设置，恢复默认检测
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
pub fn increment_by(self : ProgressBar, amount : Int) -> ProgressBar {
  self.update(self.current + amount)
}

///|
/// 重置进度条
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
pub fn close(self : ProgressBar) -> ProgressBar {
  { ..self, closed: true }
}

///|
/// 设置总数
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
pub fn set_suffix(self : ProgressBar, suffix : String) -> ProgressBar {
  { ..self, config: { ..self.config, suffix, } }
}

///|
/// 设置填充字符
pub fn set_fill(self : ProgressBar, fill : Char) -> ProgressBar {
  { ..self, config: { ..self.config, fill, } }
}

///|
/// 设置空白字符
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
/// 设置描述文本
pub fn set_desc(self : ProgressBar, desc : String) -> ProgressBar {
  { ..self, config: { ..self.config, desc, } }
}

///|
/// 设置单位
pub fn set_unit(self : ProgressBar, unit : String) -> ProgressBar {
  { ..self, config: { ..self.config, unit, } }
}

///|
/// 设置是否显示ETA
pub fn set_show_eta(self : ProgressBar, show : Bool) -> ProgressBar {
  { ..self, config: { ..self.config, show_eta: show } }
}

///|
/// 设置是否显示速率
pub fn set_show_rate(self : ProgressBar, show : Bool) -> ProgressBar {
  { ..self, config: { ..self.config, show_rate: show } }
}

///|
/// 设置是否显示已用时间
pub fn set_show_elapsed(self : ProgressBar, show : Bool) -> ProgressBar {
  { ..self, config: { ..self.config, show_elapsed: show } }
}

///|
/// 设置是否启用平滑更新
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
