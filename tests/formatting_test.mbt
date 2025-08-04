// 格式化功能测试

test "百分比计算测试" {
  let pb1 = @src.new(100)
  let pb2 = pb1.update(50)
  assert_eq(pb2.percentage(), 50.0)
  
  let pb3 = pb1.update(100)
  assert_eq(pb3.percentage(), 100.0)
  
  let pb4 = pb1.update(0)
  assert_eq(pb4.percentage(), 0.0)
}

test "边界情况测试 - 零总数" {
  let pb = @src.new(0)
  assert_eq(pb.percentage(), 0.0)
  
  let rendered = pb.render()
  assert_eq(rendered.length() > 0, true)
}

test "边界情况测试 - 超过总数" {
  let pb1 = @src.new(100)
  let pb2 = pb1.update(150)  // 超过总数
  
  // 应该被限制在总数内
  assert_eq(pb2.current, 100)
  assert_eq(pb2.percentage(), 100.0)
}

test "配置选项测试 - 显示百分比" {
  let pb = @src.new(100)
    .set_show_percent(true)
    .update(50)
  
  let rendered = pb.render()
  assert_eq(rendered.contains("%"), true)
}

test "配置选项测试 - 显示计数" {
  let pb = @src.new(100)
    .set_show_count(true)
    .update(50)
  
  let rendered = pb.render()
  assert_eq(rendered.contains("50/100"), true)
}

test "配置选项测试 - 前缀后缀" {
  let pb = @src.new(100)
    .set_prefix("进度")
    .set_suffix("完成")
    .update(50)
  
  let rendered = pb.render()
  assert_eq(rendered.contains("进度"), true)
  assert_eq(rendered.contains("完成"), true)
}

test "配置选项测试 - 描述文本" {
  let pb = @src.new(100)
    .set_desc("处理文件")
    .update(25)
  
  let rendered = pb.render()
  assert_eq(rendered.contains("处理文件"), true)
}

test "配置选项测试 - 自定义字符" {
  let pb = @src.new(100)
    .set_fill('*')
    .set_empty('.')
    .update(50)
  
  let rendered = pb.render()
  assert_eq(rendered.contains("*"), true)
  assert_eq(rendered.contains("."), true)
}

test "链式配置测试" {
  let pb = @src.new(100)
    .set_width(30)
    .set_prefix("测试")
    .set_suffix("items")
    .set_show_percent(true)
    .set_show_count(true)
    .set_desc("任务")
    .update(60)
  
  let rendered = pb.render()
  assert_eq(rendered.contains("任务"), true)
  assert_eq(rendered.contains("测试"), true)
  assert_eq(rendered.contains("items"), true)
  assert_eq(rendered.contains("60/100"), true)
  assert_eq(rendered.contains("%"), true)
}