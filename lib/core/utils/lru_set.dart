import 'dart:collection';

/// LRU(Least Recently Used) Set 구현.
/// - [maximumSize]: 캐시 최대 크기.
/// - [T]: 요소 타입.
class LruSet<T> {
  final int maximumSize;
  final LinkedHashSet<T> _set;
  
  LruSet({required this.maximumSize}) : _set = LinkedHashSet<T>();
  
  /// 요소 존재 여부 확인.
  bool contains(T item) => _set.contains(item);
  
  /// 요소 추가. 최대 크기 초과 시 가장 오래된 요소 제거.
  void add(T item) {
    if (_set.contains(item)) {
      _set.remove(item);
    }
    _set.add(item);
    while (_set.length > maximumSize) {
      _set.remove(_set.first);
    }
  }
  
  /// 캐시 비우기.
  void clear() => _set.clear();
  
  /// 현재 요소 수.
  int get length => _set.length;
  
  /// 요소 반복자.
  Iterator<T> get iterator => _set.iterator;
  
  /// 비어있는지 확인
  bool get isEmpty => _set.isEmpty;
  
  /// 비어있지 않은지 확인
  bool get isNotEmpty => _set.isNotEmpty;
  
  /// 요소 제거
  void remove(T item) => _set.remove(item);
}