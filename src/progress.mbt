// MoonProgress - A command-line progress bar library for MoonBit
// 
// 核心进度条结构和API定义
// 参考 tqdm, progressbar.js, go-progressbar 的最佳实践

///| 进度条配置选项
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

///| 默认配置
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

///| 创建自定义配置的工厂函数
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

///| 时间工具类型
pub struct TimeInfo {
  start_time : Double // 开始时间（秒）
  last_update : Double // 上次更新时间
  last_print : Double // 上次打印时间
  last_n : Int // 上次计数
  samples : Array[(Double, Int)] // 时间和进度样本点，用于精确计算速率
}

///| 进度统计信息
pub struct ProgressStats {
  avg_time : Double // 平均时间
  avg_rate : Double // 平均速率
  smoothed_rate : Double // 平滑速率
  eta : Double // 预计剩余时间
  elapsed : Double // 已用时间
}

///| 进度条状态
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

///| 时间跟踪结构 - 封装时间状态
pub struct TimeTracker {
  counter : Double
  terminal_width : Int?
}

///| 全局时间跟踪器实例
let default_time_tracker : TimeTracker = { counter: 0.0, terminal_width: None }

///| 获取当前时间（秒）- 使用计数器模拟时间
/// 注意：这是一个简化实现，实际应用中需要真实的系统时间
fn current_time() -> Double {
  // 简化实现：每次调用增加0.1秒
  // 实际应用中应该调用系统时间API
  default_time_tracker.counter + 0.1
}

///| 获取终端宽度 - 简化实现
/// 注意：实际实现中应该调用系统API获取真实的终端宽度
fn get_terminal_width() -> Int {
  match default_time_tracker.terminal_width {
    Some(width) => width
    None => 80 // 默认终端宽度
  }
}

///| 设置终端宽度（用于测试和动态调整）
pub fn set_terminal_width(width : Int) -> Unit {
  // 简化实现：实际中需要修改全局状态
  println("设置终端宽度为: " + width.to_string())
}

///| 清除终端宽度设置，恢复默认检测
pub fn clear_terminal_width() -> Unit {
  println("恢复默认终端宽度检测")
}

///| 创建初始时间信息
fn init_time_info() -> TimeInfo {
  let now = current_time()
  { start_time: now, last_update: now, last_print: now, last_n: 0, samples: [] }
}

///| 创建初始统计信息
fn init_stats() -> ProgressStats {
  { avg_time: 0.0, avg_rate: 0.0, smoothed_rate: 0.0, eta: 0.0, elapsed: 0.0 }
}

///| 创建新的进度条
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

///| 使用自定义配置创建进度条
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

///| 计算统计信息 - 增强版本
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

///| 更新进度（高级版本）
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

///| 增加进度
pub fn increment(self : ProgressBar) -> ProgressBar {
  self.update(self.current + 1)
}

///| 增加指定数量的进度
pub fn increment_by(self : ProgressBar, amount : Int) -> ProgressBar {
  self.update(self.current + amount)
}

///| 重置进度条
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

///| 关闭进度条
pub fn close(self : ProgressBar) -> ProgressBar {
  { ..self, closed: true }
}

///| 设置总数
pub fn set_total(self : ProgressBar, new_total : Int) -> ProgressBar {
  { ..self, total: new_total }
}

///| 格式化时间（秒转换为人类可读格式）
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

///| 格式化速率
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

///| 计算进度百分比
pub fn percentage(self : ProgressBar) -> Double {
  if self.total <= 0 {
    0.0
  } else {
    Double::from_int(self.current) / Double::from_int(self.total) * 100.0
  }
}

///| 获取动态宽度
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

///| 渲染进度条为字符串（高级版本）
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

///| 智能打印进度条
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

///| 智能打印（带状态更新）
pub fn print_with_update(self : ProgressBar) -> ProgressBar {
  let updated_time_info = { ..self.time_info, last_print: current_time() }
  let result = { ..self, time_info: updated_time_info }
  result.print_progress()
  result
}

///| 完成进度条
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

///| 设置进度条宽度
pub fn set_width(self : ProgressBar, width : Int) -> ProgressBar {
  { ..self, config: { ..self.config, width, } }
}

///| 设置前缀文本
pub fn set_prefix(self : ProgressBar, prefix : String) -> ProgressBar {
  { ..self, config: { ..self.config, prefix, } }
}

///| 设置后缀文本
pub fn set_suffix(self : ProgressBar, suffix : String) -> ProgressBar {
  { ..self, config: { ..self.config, suffix, } }
}

///| 设置填充字符
pub fn set_fill(self : ProgressBar, fill : Char) -> ProgressBar {
  { ..self, config: { ..self.config, fill, } }
}

///| 设置空白字符
pub fn set_empty(self : ProgressBar, empty : Char) -> ProgressBar {
  { ..self, config: { ..self.config, empty, } }
}

///| 设置是否显示百分比
pub fn set_show_percent(self : ProgressBar, show : Bool) -> ProgressBar {
  { ..self, config: { ..self.config, show_percent: show } }
}

///| 设置是否显示计数
pub fn set_show_count(self : ProgressBar, show : Bool) -> ProgressBar {
  { ..self, config: { ..self.config, show_count: show } }
}

///| 设置描述文本
pub fn set_desc(self : ProgressBar, desc : String) -> ProgressBar {
  { ..self, config: { ..self.config, desc, } }
}

///| 设置单位
pub fn set_unit(self : ProgressBar, unit : String) -> ProgressBar {
  { ..self, config: { ..self.config, unit, } }
}

///| 设置是否显示ETA
pub fn set_show_eta(self : ProgressBar, show : Bool) -> ProgressBar {
  { ..self, config: { ..self.config, show_eta: show } }
}

///| 设置是否显示速率
pub fn set_show_rate(self : ProgressBar, show : Bool) -> ProgressBar {
  { ..self, config: { ..self.config, show_rate: show } }
}

///| 设置是否显示已用时间
pub fn set_show_elapsed(self : ProgressBar, show : Bool) -> ProgressBar {
  { ..self, config: { ..self.config, show_elapsed: show } }
}

///| 设置是否启用平滑更新
pub fn set_smooth(self : ProgressBar, smooth : Bool) -> ProgressBar {
  { ..self, config: { ..self.config, smooth, } }
}

///| 设置动态宽度
pub fn set_dynamic_width(self : ProgressBar, dynamic : Bool) -> ProgressBar {
  { ..self, config: { ..self.config, dynamic_width: dynamic } }
}

///| 设置终端列数
pub fn set_ncols(self : ProgressBar, ncols : Int?) -> ProgressBar {
  { ..self, config: { ..self.config, ncols, } }
}

///| 设置最小更新间隔（项目数）
pub fn set_miniters(self : ProgressBar, miniters : Int) -> ProgressBar {
  { ..self, config: { ..self.config, miniters, } }
}

///| 设置最小时间间隔（秒）
pub fn set_mininterval(self : ProgressBar, mininterval : Double) -> ProgressBar {
  { ..self, config: { ..self.config, mininterval, } }
}

///| 设置是否启用单位缩放
pub fn set_unit_scale(self : ProgressBar, unit_scale : Bool) -> ProgressBar {
  { ..self, config: { ..self.config, unit_scale, } }
}

///| 设置嵌套进度条位置
pub fn set_position(self : ProgressBar, position : Int) -> ProgressBar {
  { ..self, config: { ..self.config, position, } }
}

// ===== 嵌套进度条支持 =====

///| 嵌套进度条管理器
pub struct NestedProgressManager {
  bars : Array[ProgressBar] // 进度条数组，按位置排序
  max_position : Int // 最大位置
}

///| 创建嵌套进度条管理器
pub fn create_nested_manager() -> NestedProgressManager {
  { bars: [], max_position: 0 }
}

///| 添加进度条到管理器
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

///| 渲染所有嵌套进度条
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

///| 更新指定位置的进度条
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

///| 设置完成后是否保留
pub fn set_leave(self : ProgressBar, leave : Bool) -> ProgressBar {
  { ..self, config: { ..self.config, leave, } }
}

///| 链式配置方法 - 批量设置
pub fn configure(
  self : ProgressBar,
  f : (ProgressBar) -> ProgressBar,
) -> ProgressBar {
  f(self)
}
