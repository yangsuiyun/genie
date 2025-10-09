import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

// 白噪音类型枚举
enum WhiteNoiseType {
  rain,
  ocean,
  forest,
  thunder,
  wind,
  fire,
  cafe,
  fan,
  silence,
}

// 白噪音服务
class WhiteNoiseService {
  static final WhiteNoiseService _instance = WhiteNoiseService._internal();
  factory WhiteNoiseService() => _instance;
  WhiteNoiseService._internal();

  bool _isPlaying = false;
  WhiteNoiseType _currentType = WhiteNoiseType.rain;
  double _volume = 0.5;
  Timer? _audioTimer;
  final List<VoidCallback> _listeners = [];

  // Getters
  bool get isPlaying => _isPlaying;
  WhiteNoiseType get currentType => _currentType;
  double get volume => _volume;

  String get currentTypeName {
    switch (_currentType) {
      case WhiteNoiseType.rain:
        return '雨声';
      case WhiteNoiseType.ocean:
        return '海浪';
      case WhiteNoiseType.forest:
        return '森林';
      case WhiteNoiseType.thunder:
        return '雷声';
      case WhiteNoiseType.wind:
        return '风声';
      case WhiteNoiseType.fire:
        return '篝火';
      case WhiteNoiseType.cafe:
        return '咖啡厅';
      case WhiteNoiseType.fan:
        return '风扇';
      case WhiteNoiseType.silence:
        return '静音';
    }
  }

  String get currentTypeEmoji {
    switch (_currentType) {
      case WhiteNoiseType.rain:
        return '🌧️';
      case WhiteNoiseType.ocean:
        return '🌊';
      case WhiteNoiseType.forest:
        return '🌲';
      case WhiteNoiseType.thunder:
        return '⚡';
      case WhiteNoiseType.wind:
        return '💨';
      case WhiteNoiseType.fire:
        return '🔥';
      case WhiteNoiseType.cafe:
        return '☕';
      case WhiteNoiseType.fan:
        return '🌀';
      case WhiteNoiseType.silence:
        return '🔇';
    }
  }

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }

  // 播放白噪音
  void play(WhiteNoiseType type) {
    _currentType = type;
    _isPlaying = true;
    _startAudioSimulation();
    _notifyListeners();
  }

  // 停止播放
  void stop() {
    _isPlaying = false;
    _audioTimer?.cancel();
    _audioTimer = null;
    _notifyListeners();
  }

  // 暂停/恢复
  void toggle() {
    if (_isPlaying) {
      stop();
    } else {
      play(_currentType);
    }
  }

  // 设置音量
  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
    _notifyListeners();
  }

  // 切换白噪音类型
  void switchType(WhiteNoiseType type) {
    bool wasPlaying = _isPlaying;
    if (_isPlaying) {
      stop();
    }
    _currentType = type;
    if (wasPlaying) {
      play(type);
    }
    _notifyListeners();
  }

  // 模拟音频播放（实际应用中会使用真实的音频库）
  void _startAudioSimulation() {
    _audioTimer?.cancel();
    _audioTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isPlaying) {
        timer.cancel();
        return;
      }
      
      // 模拟音频播放效果
      _simulateAudioEffect();
    });
  }

  void _simulateAudioEffect() {
    // 这里可以添加音频效果模拟
    // 实际应用中会使用 flutter_sound 或 audioplayers 等库
    if (kDebugMode) {
      print('Playing ${currentTypeName} at volume $_volume');
    }
  }

  // 获取所有可用的白噪音类型
  List<WhiteNoiseType> get availableTypes => WhiteNoiseType.values;

  // 获取白噪音类型信息
  Map<WhiteNoiseType, Map<String, dynamic>> get typeInfo => {
    WhiteNoiseType.rain: {
      'name': '雨声',
      'emoji': '🌧️',
      'description': '轻柔的雨声，帮助放松和专注',
      'duration': '持续',
    },
    WhiteNoiseType.ocean: {
      'name': '海浪',
      'emoji': '🌊',
      'description': '海浪拍岸的声音，带来宁静感',
      'duration': '持续',
    },
    WhiteNoiseType.forest: {
      'name': '森林',
      'emoji': '🌲',
      'description': '森林中的自然声音，鸟鸣和风声',
      'duration': '持续',
    },
    WhiteNoiseType.thunder: {
      'name': '雷声',
      'emoji': '⚡',
      'description': '远方的雷声，营造氛围感',
      'duration': '间歇',
    },
    WhiteNoiseType.wind: {
      'name': '风声',
      'emoji': '💨',
      'description': '轻柔的风声，适合冥想',
      'duration': '持续',
    },
    WhiteNoiseType.fire: {
      'name': '篝火',
      'emoji': '🔥',
      'description': '篝火燃烧的声音，温暖舒适',
      'duration': '持续',
    },
    WhiteNoiseType.cafe: {
      'name': '咖啡厅',
      'emoji': '☕',
      'description': '咖啡厅的环境音，适合工作',
      'duration': '持续',
    },
    WhiteNoiseType.fan: {
      'name': '风扇',
      'emoji': '🌀',
      'description': '风扇转动的声音，白噪音效果',
      'duration': '持续',
    },
    WhiteNoiseType.silence: {
      'name': '静音',
      'emoji': '🔇',
      'description': '完全静音，适合需要安静的环境',
      'duration': '持续',
    },
  };

  void dispose() {
    _audioTimer?.cancel();
    _listeners.clear();
  }
}

