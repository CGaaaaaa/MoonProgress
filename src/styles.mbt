// 简洁实用的进度条样式
// 专注于黑白字符样式，提供最实用的几种选择

///| 进度条样式枚举 - 简洁实用的5种样式
pub enum ProgressStyle {
  Default // █ 和空格 - 经典实心样式
  Block // █ 和 ░ - 实心和浅色块对比
  Arrow // > 和 - - 箭头指向样式  
  Dots // ● 和 ○ - 圆点样式
  Hash // # 和 - - ASCII兼容样式
}

// 样式工厂函数

/// 获取默认样式
/// 
/// 返回经典的实心块样式，使用 '█' 作为填充字符，空格作为空白字符。
/// 这是最常用的进度条样式，在大多数终端中都能正确显示。
/// 
/// # 返回值
/// - `ProgressStyle` - Default样式枚举值
/// 
/// # 示例
/// ```moonbit
/// let style = default_style()
/// let pb = new_with_style(100, style).update(50)
/// println(pb.render())
/// // 输出: 50%|[█████████████████████████                         ]
/// ```
pub fn default_style() -> ProgressStyle {
  Default
}

/// 获取块对比样式
/// 
/// 返回使用实心块和浅色块对比的样式，填充字符为 '█'，空白字符为 '░'。
/// 提供更好的视觉对比度，适合需要清晰区分已完成和未完成部分的场景。
/// 
/// # 返回值
/// - `ProgressStyle` - Block样式枚举值
/// 
/// # 示例
/// ```moonbit
/// let style = block_style()
/// let pb = new_with_style(100, style).update(30)
/// println(pb.render())
/// // 输出: 30%|[███████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░]
/// ```
pub fn block_style() -> ProgressStyle {
  Block
}

/// 获取箭头样式
/// 
/// 返回箭头指向样式，使用 '>' 作为填充字符，'-' 作为空白字符。
/// 创造出向右移动的视觉效果，适合表示数据流动或传输进度。
/// 
/// # 返回值
/// - `ProgressStyle` - Arrow样式枚举值
/// 
/// # 示例
/// ```moonbit
/// let style = arrow_style()
/// let pb = new_with_style(100, style).update(40)
/// println(pb.render())
/// // 输出: 40%|[>>>>>>>>>>>>>>>>>>>>------------------------------]
/// ```
pub fn arrow_style() -> ProgressStyle {
  Arrow
}

/// 获取圆点样式
/// 
/// 返回圆点样式，使用实心圆点 '●' 和空心圆点 '○' 的组合。
/// 提供优雅的外观，适合需要精致显示效果的应用场景。
/// 
/// # 返回值
/// - `ProgressStyle` - Dots样式枚举值
/// 
/// # 示例
/// ```moonbit
/// let style = dots_style()
/// let pb = new_with_style(100, style).update(60)
/// println(pb.render())
/// // 输出: 60%|[██████████████████████████████○○○○○○○○○○○○○○○○○○○○]
/// ```
pub fn dots_style() -> ProgressStyle {
  Dots
}

/// 获取ASCII兼容样式
/// 
/// 返回纯ASCII字符样式，使用 '#' 作为填充字符，'-' 作为空白字符。
/// 确保在所有终端和字符编码环境中都能正确显示，最大兼容性。
/// 
/// # 返回值
/// - `ProgressStyle` - Hash样式枚举值
/// 
/// # 示例
/// ```moonbit
/// let style = hash_style()
/// let pb = new_with_style(100, style).update(70)
/// println(pb.render())
/// // 输出: 70%|[#############################---------------]
/// ```
pub fn hash_style() -> ProgressStyle {
  Hash
}

/// 根据样式创建配置
/// 
/// 将样式枚举转换为对应的 ProgressConfig 配置对象。
/// 每种样式都有预设的填充和空白字符组合。
/// 
/// # 参数
/// - `style` - 要转换的样式枚举值
/// 
/// # 返回值
/// - `ProgressConfig` - 对应样式的配置对象
/// 
/// # 样式映射
/// - `Default`: 填充='█', 空白=' '
/// - `Block`: 填充='█', 空白='░'
/// - `Arrow`: 填充='>', 空白='-'
/// - `Dots`: 填充='●', 空白='○'
/// - `Hash`: 填充='#', 空白='-'
/// 
/// # 示例
/// ```moonbit
/// // 直接使用样式配置
/// let config = style_to_config(arrow_style())
/// let pb = new_with_config(100, config).update(35)
/// println(pb.render())
/// // 输出: 35%|[>>>>>>>>>>>>>>>>>---------------------------------]
/// 
/// // 在样式基础上进一步自定义
/// let custom_config = style_to_config(dots_style())
/// let pb2 = new_with_config(200, custom_config)
///   .set_prefix("加载: ")
///   .set_show_count(true)
///   .update(80)
/// println(pb2.render())
/// // 输出: 加载: 40% (80/200)|[████████████████████○○○○○○○○○○○○○○○○○○○○○○○○○○○○○○]
/// ```
pub fn style_to_config(style : ProgressStyle) -> ProgressConfig {
  match style {
    Default => default_config()
    Block => { ..default_config(), fill: '█', empty: '░' }
    Arrow => { ..default_config(), fill: '>', empty: '-' }
    Dots => { ..default_config(), fill: '●', empty: '○' }
    Hash => { ..default_config(), fill: '#', empty: '-' }
  }
}

/// 使用指定样式创建进度条
/// 
/// 直接使用样式枚举创建进度条，是 new_with_config(total, style_to_config(style)) 的便捷方法。
/// 
/// # 参数
/// - `total` - 进度条的总数
/// - `style` - 要使用的样式枚举值
/// 
/// # 返回值
/// - `ProgressBar` - 使用指定样式的进度条实例
/// 
/// # 示例
/// ```moonbit
/// // 创建不同样式的进度条
/// let pb1 = new_with_style(100, default_style()).update(25)
/// println(pb1.render())
/// // 输出: 25%|[████████████▌                                     ]
/// 
/// let pb2 = new_with_style(100, arrow_style()).update(50)
/// println(pb2.render())
/// // 输出: 50%|[>>>>>>>>>>>>>>>>>>>>>>>>>-------------------------]
/// 
/// let pb3 = new_with_style(100, hash_style()).update(75)
/// println(pb3.render())
/// // 输出: 75%|[#####################################-------------]
/// 
/// // 结合其他配置使用
/// let pb4 = new_with_style(200, dots_style())
///   .set_prefix("同步: ")
///   .set_show_rate(true)
///   .update(120)
/// println(pb4.render())
/// // 输出: 同步: 60%|[██████████████████████████████○○○○○○○○○○○○○○○○○○○○] [45.2it/s]
/// ```
pub fn new_with_style(total : Int, style : ProgressStyle) -> ProgressBar {
  new_with_config(total, style_to_config(style))
}
