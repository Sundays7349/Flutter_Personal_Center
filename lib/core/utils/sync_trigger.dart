/// 数据变更同步触发器
///
/// 所有数据库写操作（增/删/改）在更新"数据库最后修改时间"后会调用
/// [notifyDataChanged]，由应用层注册的 [onDataChanged] 回调来触发
/// 一次防抖的云端同步，实现"数据变更后自动同步"。
class SyncTrigger {
  /// 数据变更回调（由应用层注册）
  static void Function()? onDataChanged;

  /// 通知发生了数据变更
  static void notifyDataChanged() {
    onDataChanged?.call();
  }
}
