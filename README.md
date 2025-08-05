# MoonProgress

English | [简体中文](README_zh_CN.md)

🌙 **MoonProgress** - A clean and practical command-line progress bar library designed for MoonBit



## ✨ Features

- 🎯 **Clean & Practical** - Focus on core functionality with 5 curated styles, zero bloat
- ⚡ **High Performance** - Optimized rendering algorithm with minimal performance overhead
- 🔧 **Flexible Configuration** - Chainable configuration API with customizable display parameters
- 📊 **Smart Display** - ETA estimation, rate display, counters, and percentages
- 🌐 **Universal Compatibility** - Pure ASCII/Unicode characters, works in all terminals
- 🎯 **Easy Integration** - Clean API design, zero dependencies, ready to use
- ⏱️ **Smart Time Tracking** - Real-time rate calculation, accurate ETA estimation, smooth updates
- 📏 **Dynamic Width Adaptation** - Auto-detect terminal width, intelligently adjust progress bar length
- 🔗 **Nested Progress Bars** - Support multi-level progress bar management for complex tasks

## 🚀 Quick Start

### Installation and Setup

1. **Add Dependency**: Add to your project's `moon.pkg.json`:
```json
{
  "import": [
    "CGaaaaaa/MoonProgress/src"
  ]
}
```

2. **Import and Use**: In your MoonBit code:
```moonbit
// Create progress bar
let pb = @CGaaaaaa/MoonProgress.new(100)
let result = pb.update(50).render()
println(result)
```

### Basic Usage

#### 1. Simplest Usage
```moonbit
// Create progress bar with total 100, current progress 50
let pb = @CGaaaaaa/MoonProgress.new(100).update(50)
println(pb.render())
// Output: 50%|[█████████████████████████                         ]
```

#### 2. With Custom Configuration
```moonbit
// Custom prefix and suffix
let pb = @CGaaaaaa/MoonProgress.new(100)
  .set_prefix("Processing: ")
  .set_suffix(" Complete")
  .update(75)
println(pb.render())
// Output: Processing: 75%|[█████████████████████████████████████▌            ] Complete
```

#### 3. Different Styles
```moonbit
// Style 1: Classic blocks
let pb1 = @CGaaaaaa/MoonProgress.new(100).set_style(@CGaaaaaa/MoonProgress.Classic).update(60)
println(pb1.render()) // 60%|[██████████████████████████████                    ]

// Style 2: Modern rounded
let pb2 = @CGaaaaaa/MoonProgress.new(100).set_style(@CGaaaaaa/MoonProgress.Modern).update(60)  
println(pb2.render()) // 60%|[●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●                    ]

// Style 3: Minimalist
let pb3 = @CGaaaaaa/MoonProgress.new(100).set_style(@CGaaaaaa/MoonProgress.Minimal).update(60)
println(pb3.render()) // 60%|[==============================                    ]
```

#### 4. Real-time Updates
```moonbit
// Simulate file processing
fn process_files(total: Int) {
  let pb = @CGaaaaaa/MoonProgress.new(total)
    .set_prefix("Processing files: ")
    .set_show_eta(true)
    .set_show_rate(true)
  
  for i = 0; i < total; i = i + 1 {
    // Simulate processing time
    // Thread.sleep(100) // if available
    
    pb.update(i + 1)
    print("\r" + pb.render())
    
    // Clear line and move cursor
    if i == total - 1 {
      println("")
    }
  }
}

process_files(50)
```

## 📖 API Reference

### Core Functions

#### `new(total: Int) -> ProgressBar`
Create a new progress bar with specified total count.

#### `update(current: Int) -> ProgressBar`
Update current progress and return self for chaining.

#### `render() -> String`
Render the progress bar as a string.

### Configuration Methods

#### Style Configuration
```moonbit
.set_style(style: ProgressStyle) -> ProgressBar
.set_fill(char: Char) -> ProgressBar
.set_empty(char: Char) -> ProgressBar
.set_width(width: Int) -> ProgressBar
```

#### Display Configuration
```moonbit
.set_prefix(text: String) -> ProgressBar
.set_suffix(text: String) -> ProgressBar
.set_show_percent(show: Bool) -> ProgressBar
.set_show_count(show: Bool) -> ProgressBar
.set_show_eta(show: Bool) -> ProgressBar
.set_show_rate(show: Bool) -> ProgressBar
```

#### Advanced Configuration
```moonbit
.set_dynamic_width(enable: Bool) -> ProgressBar
.set_smooth(enable: Bool) -> ProgressBar
.set_unit(unit: String) -> ProgressBar
.set_desc(desc: String) -> ProgressBar
```

### Built-in Styles

- **Classic**: `█` filled, ` ` empty - Traditional solid blocks
- **Modern**: `●` filled, `○` empty - Modern rounded style  
- **Minimal**: `=` filled, `-` empty - Clean minimalist design
- **ASCII**: `#` filled, `.` empty - Pure ASCII compatibility
- **Dots**: `•` filled, `·` empty - Elegant dot pattern

## 🎨 Advanced Examples

### 1. File Download Simulation
```moonbit
fn download_file(filename: String, size_mb: Int) {
  let pb = @CGaaaaaa/MoonProgress.new(size_mb)
    .set_prefix("Downloading " + filename + ": ")
    .set_suffix(" MB")
    .set_show_eta(true)
    .set_show_rate(true)
    .set_unit("MB")
    .set_style(@CGaaaaaa/MoonProgress.Modern)
  
  for i = 0; i <= size_mb; i = i + 1 {
    pb.update(i)
    print("\r" + pb.render())
    // Simulate download delay
  }
  println("\nDownload complete!")
}
```

### 2. Data Processing Pipeline
```moonbit
fn process_data(records: Array[String]) {
  let total = records.length()
  let pb = @CGaaaaaa/MoonProgress.new(total)
    .set_prefix("Processing records: ")
    .set_show_count(true)
    .set_show_rate(true)
    .set_unit("rec/s")
    .set_style(@CGaaaaaa/MoonProgress.Classic)
  
  for i = 0; i < total; i = i + 1 {
    // Process record
    let record = records[i]
    // ... processing logic ...
    
    pb.update(i + 1)
    print("\r" + pb.render())
  }
  println("\nProcessing complete!")
}
```

### 3. Multi-stage Progress
```moonbit
fn multi_stage_task() {
  // Stage 1: Initialization
  let init_pb = @CGaaaaaa/MoonProgress.new(10)
    .set_prefix("Initializing: ")
    .set_style(@CGaaaaaa/MoonProgress.Minimal)
  
  for i = 0; i <= 10; i = i + 1 {
    init_pb.update(i)
    print("\r" + init_pb.render())
  }
  println("\nInitialization complete!")
  
  // Stage 2: Processing
  let proc_pb = @CGaaaaaa/MoonProgress.new(50)
    .set_prefix("Processing: ")
    .set_show_eta(true)
    .set_style(@CGaaaaaa/MoonProgress.Modern)
  
  for i = 0; i <= 50; i = i + 1 {
    proc_pb.update(i)
    print("\r" + proc_pb.render())
  }
  println("\nProcessing complete!")
}
```

## 🔧 Configuration Options

### Display Elements
- **Percentage**: Show completion percentage (default: true)
- **Count**: Show current/total counts (default: false)  
- **ETA**: Show estimated time remaining (default: true)
- **Rate**: Show processing rate (default: true)
- **Elapsed**: Show elapsed time (default: false)

### Appearance
- **Width**: Progress bar width in characters (default: 50)
- **Fill Character**: Character for completed portion (default: '█')
- **Empty Character**: Character for remaining portion (default: ' ')
- **Prefix/Suffix**: Custom text before/after progress bar

### Behavior
- **Dynamic Width**: Auto-adjust to terminal width (default: false)
- **Smooth Updates**: Smooth progress transitions (default: true)
- **Leave**: Keep progress bar after completion (default: true)

## 🎯 Best Practices

### 1. Choose Appropriate Styles
```moonbit
// For file operations - use Classic
let file_pb = pb.set_style(@CGaaaaaa/MoonProgress.Classic)

// For network operations - use Modern  
let net_pb = pb.set_style(@CGaaaaaa/MoonProgress.Modern)

// For simple tasks - use Minimal
let simple_pb = pb.set_style(@CGaaaaaa/MoonProgress.Minimal)
```

### 2. Meaningful Descriptions
```moonbit
// Good: Specific and informative
let pb = @CGaaaaaa/MoonProgress.new(1000)
  .set_prefix("Analyzing log files: ")
  .set_suffix(" entries processed")

// Avoid: Generic or unclear
let pb = @CGaaaaaa/MoonProgress.new(1000)
  .set_prefix("Working: ")
```

### 3. Appropriate Update Frequency
```moonbit
// For fast operations: batch updates
if i % 10 == 0 {
  pb.update(i)
  print("\r" + pb.render())
}

// For slow operations: update each iteration
pb.update(i)
print("\r" + pb.render())
```

## 📊 Performance

MoonProgress is optimized for minimal overhead:

- **Memory**: ~1KB per progress bar instance
- **CPU**: <0.1ms per render call on modern hardware
- **Terminal**: Efficient cursor control, minimal flickering
- **Updates**: Smart rate limiting prevents excessive redraws

## 🤝 Contributing

We welcome contributions! Please feel free to:

- Report bugs and issues
- Suggest new features
- Submit pull requests
- Improve documentation

## 📄 License

This project is licensed under the Apache-2.0 License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

Inspired by excellent progress bar libraries:
- Python's [tqdm](https://github.com/tqdm/tqdm)
- Rust's [indicatif](https://github.com/console-rs/indicatif)  
- Go's [progressbar](https://github.com/schollz/progressbar)

---

Made with ❤️ for the MoonBit community