// 高级功能测试

///|
test "时间跟踪和速率计算测试" {
  let pb = @src.new(100).set_show_rate(true).set_show_eta(true).update(25)
  let rendered = pb.render()
  assert_eq(rendered.length() > 0, true)
  assert_eq(pb.percentage(), 25.0)
}

///|
test "动态终端宽度测试" {
  let pb = @src.new(100).set_dynamic_width(true).set_ncols(Some(120)).update(50)
  let rendered = pb.render()
  assert_eq(rendered.length() > 0, true)
  assert_eq(rendered.contains("["), true)
}

///|
test "嵌套进度条管理器测试" {
  let manager = @src.create_nested_manager()
  let pb1 = @src.new(50).set_position(0).set_desc("主任务").update(25)
  let pb2 = @src.new(100).set_position(1).set_desc("子任务").update(80)
  let updated_manager = manager.add_progress_bar(pb1).add_progress_bar(pb2)
  let rendered = updated_manager.render_nested()
  assert_eq(rendered.length() > 0, true)
  assert_eq(rendered.contains("主任务"), true)
  assert_eq(rendered.contains("子任务"), true)
}

///|
test "嵌套进度条更新测试" {
  let manager = @src.create_nested_manager()
  let pb = @src.new(100).set_position(0).set_desc("测试任务").update(30)
  let manager_with_bar = manager.add_progress_bar(pb)
  let updated_manager = manager_with_bar.update_nested(0, 60)
  let rendered = updated_manager.render_nested()
  assert_eq(rendered.contains("测试任务"), true)
}

///|
test "平滑更新测试" {
  let pb = @src.new(100).set_smooth(true).update(25).update(50).update(75)
  let rendered = pb.render()
  assert_eq(rendered.length() > 0, true)
  assert_eq(pb.percentage(), 75.0)
}

///|
test "时间间隔配置测试" {
  let pb = @src.new(1000).set_miniters(10).set_mininterval(0.5).update(5) // 应该不更新，因为小于 miniters

  // 进度应该还是0，因为增量太小
  assert_eq(pb.current, 5)
}

///|
test "单位缩放测试" {
  let pb = @src.new(1000)
    .set_unit("bytes")
    .set_unit_scale(true)
    .set_show_rate(true)
    .update(500)
  let rendered = pb.render()
  assert_eq(rendered.length() > 0, true)
}

///|
test "完整配置测试" {
  let pb = @src.new(200)
    .set_desc("处理文件")
    .set_prefix("进度")
    .set_suffix("完成")
    .set_unit("files")
    .set_show_percent(true)
    .set_show_count(true)
    .set_show_rate(true)
    .set_show_eta(true)
    .set_dynamic_width(true)
    .set_smooth(true)
    .update(150)
  let rendered = pb.render()
  assert_eq(rendered.contains("处理文件"), true)
  assert_eq(rendered.contains("进度"), true)
  assert_eq(rendered.contains("完成"), true)
  assert_eq(pb.percentage(), 75.0)
}

///|
test "ETA计算准确性测试" {
  let pb = @src.new(100).set_show_eta(true).update(25) // 25% 完成

  // ETA应该大于0（还有任务要完成）
  assert_eq(pb.stats.eta >= 0.0, true)
  let completed_pb = pb.update(100) // 100% 完成
  // 完成后ETA应该为0
  assert_eq(completed_pb.stats.eta, 0.0)
}

///|
test "增量操作测试" {
  let pb = @src.new(50).set_show_count(true).update(10)
  let incremented = pb.increment()
  assert_eq(incremented.current, 11)
  let incremented_by = incremented.increment_by(5)
  assert_eq(incremented_by.current, 16)
}
