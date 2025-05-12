// core/utils/lru_map.dart
import 'dart:collection';

/// LRU(Least Recently Used) 캐시 구현한 Map
class LruMap<K, V> {
  final int maximumSize;
  final LinkedHashMap<K, V> _map;
  
  LruMap({required this.maximumSize}) : _map = LinkedHashMap<K, V>();
  
  V? operator [](K key) {
    final value = _map[key];
    if (value != null) {
      // LRU 동작: 접근된 항목을 가장 최근으로 이동
      _map.remove(key);
      _map[key] = value;
    }
    return value;
  }
  
  void operator []=(K key, V value) {
    if (_map.containsKey(key)) {
      _map.remove(key);
    } else if (_map.length >= maximumSize) {
      _map.remove(_map.keys.first);
    }
    _map[key] = value;
  }
  
  bool containsKey(K key) => _map.containsKey(key);
  
  V? remove(K key) => _map.remove(key);
  
  void clear() => _map.clear();
  
  int get length => _map.length;
  
  Iterable<K> get keys => _map.keys;
  
  Iterable<V> get values => _map.values;
  
  Iterable<MapEntry<K, V>> get entries => _map.entries;
  
  V putIfAbsent(K key, V Function() ifAbsent) {
    if (containsKey(key)) {
      return this[key]!;
    }
    
    final value = ifAbsent();
    this[key] = value;
    return value;
  }
}