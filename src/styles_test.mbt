// 样式模块测试

///|
test "默认样式测试" {
  let style_config = style_to_config(default_style())
  let pb = new_with_style(100, default_style())

  // 验证默认样式配置
  assert_eq(style_config.fill, '█')
  assert_eq(style_config.empty, ' ')
  let rendered = pb.render()
  assert_eq(rendered.contains("["), true)
  assert_eq(rendered.contains("]"), true)
}

///|
test "Block样式测试" {
  let style_config = style_to_config(block_style())
  let pb = new_with_style(100, block_style())

  // 验证Block样式配置
  assert_eq(style_config.fill, '█')
  assert_eq(style_config.empty, '░')
  let rendered = pb.render()
  assert_eq(rendered.length() > 0, true)
}

///|
test "Arrow样式测试" {
  let style_config = style_to_config(arrow_style())
  let pb = new_with_style(50, arrow_style())

  // 验证Arrow样式配置
  assert_eq(style_config.fill, '>')
  assert_eq(style_config.empty, '-')
  let rendered = pb.render()
  assert_eq(rendered.length() > 0, true)
}

///|
test "Dots样式测试" {
  let style_config = style_to_config(dots_style())
  let pb = new_with_style(20, dots_style())

  // 验证Dots样式配置
  assert_eq(style_config.fill, '●')
  assert_eq(style_config.empty, '○')
  let rendered = pb.render()
  assert_eq(rendered.length() > 0, true)
}

///|
test "Hash样式测试" {
  let style_config = style_to_config(hash_style())
  let pb = new_with_style(10, hash_style())

  // 验证Hash样式配置
  assert_eq(style_config.fill, '#')
  assert_eq(style_config.empty, '-')
  let rendered = pb.render()
  assert_eq(rendered.length() > 0, true)
}

///|
test "样式进度条更新测试" {
  let pb1 = new_with_style(100, block_style())
  let pb2 = pb1.update(75)
  let percentage = pb2.percentage()
  assert_eq(percentage, 75.0)
  let rendered = pb2.render()
  assert_eq(rendered.contains("["), true)
  assert_eq(rendered.contains("]"), true)
}
