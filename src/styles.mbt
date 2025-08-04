// 简洁实用的进度条样式
// 专注于黑白字符样式，提供最实用的几种选择

/// 进度条样式枚举 - 简洁实用的5种样式
pub enum ProgressStyle {
  Default       // █ 和空格 - 经典实心样式
  Block         // █ 和 ░ - 实心和浅色块对比
  Arrow         // > 和 - - 箭头指向样式  
  Dots          // ● 和 ○ - 圆点样式
  Hash          // # 和 - - ASCII兼容样式
}

// 样式工厂函数
pub fn default_style() -> ProgressStyle { Default }
pub fn block_style() -> ProgressStyle { Block }
pub fn arrow_style() -> ProgressStyle { Arrow }
pub fn dots_style() -> ProgressStyle { Dots }
pub fn hash_style() -> ProgressStyle { Hash }

/// 根据样式创建配置
pub fn style_to_config(style : ProgressStyle) -> ProgressConfig {
  match style {
    Default => default_config()
    Block => { 
      ..default_config(), 
      fill: '█', 
      empty: '░' 
    }
    Arrow => { 
      ..default_config(), 
      fill: '>', 
      empty: '-' 
    }
    Dots => { 
      ..default_config(), 
      fill: '●', 
      empty: '○' 
    }
    Hash => {
      ..default_config(),
      fill: '#',
      empty: '-'
    }
  }
}

/// 使用样式创建进度条
pub fn new_with_style(total : Int, style : ProgressStyle) -> ProgressBar {
  new_with_config(total, style_to_config(style))
}