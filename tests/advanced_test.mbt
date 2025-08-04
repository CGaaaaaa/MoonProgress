// 高级功能测试

test "增量操作测试" {
  let pb1 = @src.new(100)
  let pb2 = pb1.increment()
  assert_eq(pb2.current, 1)
  
  let pb3 = pb2.increment_by(10)
  assert_eq(pb3.current, 11)
}

test "重置功能测试" {
  let pb1 = @src.new(100).update(50)
  assert_eq(pb1.current, 50)
  
  let pb2 = pb1.reset_progress()
  assert_eq(pb2.current, 0)
  assert_eq(pb2.closed, false)
}

test "关闭功能测试" {
  let pb1 = @src.new(100)
  let pb2 = pb1.close()
  assert_eq(pb2.closed, true)
  
  // 关闭后的更新应该无效
  let pb3 = pb2.update(50)
  assert_eq(pb3.current, 0)  // 不应该更新
}

test "设置总数测试" {
  let pb1 = @src.new(100)
  let pb2 = pb1.set_total(200)
  assert_eq(pb2.total, 200)
}

test "完成功能测试" {
  let pb1 = @src.new(100).update(50)
  let pb2 = pb1.finish()
  
  assert_eq(pb2.current, 100)
  assert_eq(pb2.closed, true)
}

test "自定义配置创建测试" {
  let custom_config = @src.create_config(
    30, "", "", '*', '.', false, true, true, true, false,
    false, true, true, None, 1, 0.1, 10.0, "", "it", false, 0
  )
  
  let pb = @src.new_with_config(100, custom_config)
  assert_eq(pb.config.width, 30)
  assert_eq(pb.config.fill, '*')
  assert_eq(pb.config.empty, '.')
  assert_eq(pb.config.show_percent, false)
  assert_eq(pb.config.show_count, true)
}

test "各种配置选项测试" {
  let pb = @src.new(100)
    .set_show_eta(true)
    .set_show_rate(true)
    .set_show_elapsed(true)
    .set_smooth(false)
    .set_unit("files")
    .set_unit_scale(true)
    .set_dynamic_width(true)
    .set_leave(false)
  
  assert_eq(pb.config.show_eta, true)
  assert_eq(pb.config.show_rate, true)
  assert_eq(pb.config.show_elapsed, true)
  assert_eq(pb.config.smooth, false)
  assert_eq(pb.config.unit, "files")
  assert_eq(pb.config.unit_scale, true)
  assert_eq(pb.config.dynamic_width, true)
  assert_eq(pb.config.leave, false)
}

test "时间间隔配置测试" {
  let pb = @src.new(100)
    .set_mininterval(0.5)
    .set_miniters(5)
  
  assert_eq(pb.config.mininterval, 0.5)
  assert_eq(pb.config.miniters, 5)
}

test "终端列数配置测试" {
  let pb1 = @src.new(100).set_ncols(Some(80))
  assert_eq(pb1.config.ncols, Some(80))
  
  let pb2 = pb1.set_ncols(None)
  assert_eq(pb2.config.ncols, None)
}

test "configure方法测试" {
  let pb = @src.new(100).configure(fn(p) { 
    p.set_width(25).set_prefix("进度").set_show_count(true)
  })
  
  assert_eq(pb.config.width, 25)
  assert_eq(pb.config.prefix, "进度")
  assert_eq(pb.config.show_count, true)
}