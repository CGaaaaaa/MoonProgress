// CLI工具中的真实使用案例演示
// 验证MoonProgress在实际命令行工具中的应用

///| 模拟文件下载CLI工具
fn demo_file_download() -> Unit {
  println("📥 文件下载工具演示")
  println("下载文件: large_dataset.zip (1000MB)")
  let pb = @MoonProgress/src.new(1000)
    .set_desc("下载")
    .set_unit("MB")
    .set_show_percent(true)
    .set_show_rate(true)
    .set_show_count(true)
  let mut downloaded = 0
  let download_speeds = [45, 52, 48, 61, 55, 49, 58, 63, 57, 44]
  for speed in download_speeds {
    // 模拟下载一个数据块（实际业务逻辑在这里）
    downloaded = downloaded + speed

    // 进度条只负责显示当前状态
    println(pb.update(downloaded).render())
  }
  println("✅ 下载完成！")
}

///| 模拟数据处理CLI工具  
fn demo_data_processing() -> Unit {
  println("\n🔄 数据处理工具演示")
  println("处理用户数据: 50000条记录")
  let pb = @MoonProgress/src.new(50000)
    .set_desc("处理用户数据")
    .set_unit("records")
    .set_show_percent(true)
    .set_show_eta(true)
    .set_show_count(true)
  let batch_sizes = [5000, 8000, 12000, 10000, 7000, 8000]
  let mut processed = 0
  for batch_size in batch_sizes {
    // 模拟处理一批数据（实际业务逻辑在这里）
    processed = processed + batch_size

    // 进度条显示处理进度
    println(pb.update(processed).render())
  }
  println("✅ 数据处理完成！")
}

///| 模拟测试运行器CLI工具
fn demo_test_runner() -> Unit {
  println("\n🧪 测试运行器演示")
  println("运行测试套件: 150个测试用例")
  let pb = @MoonProgress/src.new(150)
    .set_desc("运行测试")
    .set_prefix("进度")
    .set_show_percent(true)
    .set_show_count(true)
    .set_width(30)
  let test_batches = [15, 23, 18, 27, 22, 19, 26]
  let mut completed = 0
  for batch in test_batches {
    // 模拟运行一批测试（实际测试逻辑在这里）
    completed = completed + batch

    // 进度条显示测试进度
    println(pb.update(completed).render())
  }
  println("✅ 所有测试通过！")
}

///| 模拟构建工具CLI
fn demo_build_tool() -> Unit {
  println("\n🔨 构建工具演示")
  println("编译项目: 200个源文件")
  let pb = @MoonProgress/src.new(200)
    .set_desc("编译")
    .set_suffix("files")
    .set_show_percent(true)
    .set_show_count(true)
    .set_fill('■')
    .set_empty('□')
  let compile_batches = [25, 35, 40, 30, 28, 22, 20]
  let mut compiled = 0
  for batch in compile_batches {
    // 模拟编译一批文件（实际编译逻辑在这里）
    compiled = compiled + batch

    // 进度条显示编译进度
    println(pb.update(compiled).render())
  }
  println("✅ 构建成功！")
}

///| 演示真实世界的使用场景
fn demo_real_world_usage() -> Unit {
  println("\n💼 真实CLI工具集成演示")

  // 场景1：开箱即用 - 3行代码
  println("1. 最简使用（3行代码）:")
  let simple_pb = @MoonProgress/src.new(100).update(65)
  println("   " + simple_pb.render())

  // 场景2：配置丰富但仍然简单
  println("\n2. 丰富配置但仍简单:")
  let rich_pb = @MoonProgress/src.new(200)
    .set_desc("处理")
    .set_show_percent(true)
    .set_show_count(true)
    .set_show_rate(true)
    .update(150)
  println("   " + rich_pb.render())

  // 场景3：演示时间无关性
  println("\n3. 证明时间无关性（连续更新）:")
  let mut pb = @MoonProgress/src.new(10)
    .set_desc("快速更新")
    .set_show_percent(true)
  for i = 0; i <= 10; i = i + 1 {
    pb = pb.update(i)
    println("   " + pb.render())
  }
}

///| 主函数：展示所有CLI工具用例
fn main {
  println("🌙 MoonProgress - CLI工具真实使用案例")
  println("==================================================")
  demo_file_download()
  demo_data_processing()
  demo_test_runner()
  demo_build_tool()
  demo_real_world_usage()
  println("\n🎉 所有演示完成！")
  println(
    "💡 如你所见，MoonProgress完美适用于各种CLI工具的进度显示需求",
  )
  println(
    "🔥 虚拟时间设计让它比tqdm更快、更简单、更可靠！",
  )
}
