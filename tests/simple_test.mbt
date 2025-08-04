// 简化的测试

///|
test "创建基本进度条" {
  let pb = @src.new(100)
  let rendered = pb.render()
  assert_eq(rendered.length() > 0, true)
  assert_eq(rendered.contains("["), true)
  assert_eq(rendered.contains("]"), true)
}

///|
test "进度更新" {
  let pb1 = @src.new(100)
  let pb2 = pb1.update(50)
  let percentage = pb2.percentage()
  assert_eq(percentage, 50.0)
}

///|
test "配置链式调用" {
  let pb = @src.new(50)
    .set_prefix("测试")
    .set_suffix("items")
    .set_show_percent(true)
  let rendered = pb.render()
  assert_eq(rendered.contains("测试"), true)
  assert_eq(rendered.contains("items"), true)
}
