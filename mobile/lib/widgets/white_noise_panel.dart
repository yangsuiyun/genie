import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/white_noise_service.dart';

// 白噪音控制面板
class WhiteNoisePanel extends ConsumerStatefulWidget {
  const WhiteNoisePanel({super.key});

  @override
  ConsumerState<WhiteNoisePanel> createState() => _WhiteNoisePanelState();
}

class _WhiteNoisePanelState extends ConsumerState<WhiteNoisePanel> {
  final WhiteNoiseService _whiteNoiseService = WhiteNoiseService();

  @override
  void initState() {
    super.initState();
    _whiteNoiseService.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _whiteNoiseService.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题
          Row(
            children: [
              const Icon(Icons.music_note, color: Colors.white),
              const SizedBox(width: 8),
              const Text(
                '白噪音',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // 当前播放状态
          if (_whiteNoiseService.isPlaying) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Text(
                    _whiteNoiseService.currentTypeEmoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _whiteNoiseService.currentTypeName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '正在播放',
                          style: TextStyle(
                            color: Colors.green.shade300,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.stop, color: Colors.red),
                    onPressed: _whiteNoiseService.stop,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          
          // 音量控制
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '音量',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.volume_down, color: Colors.white70),
                  Expanded(
                    child: Slider(
                      value: _whiteNoiseService.volume,
                      onChanged: (value) {
                        _whiteNoiseService.setVolume(value);
                      },
                      activeColor: Colors.red,
                      inactiveColor: Colors.white24,
                    ),
                  ),
                  const Icon(Icons.volume_up, color: Colors.white70),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // 白噪音类型选择
          const Text(
            '选择音效',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          
          // 音效网格
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: _whiteNoiseService.availableTypes.length,
            itemBuilder: (context, index) {
              final type = _whiteNoiseService.availableTypes[index];
              final isSelected = _whiteNoiseService.currentType == type;
              final typeInfo = _whiteNoiseService.typeInfo[type]!;
              
              return GestureDetector(
                onTap: () {
                  if (_whiteNoiseService.isPlaying) {
                    _whiteNoiseService.switchType(type);
                  } else {
                    _whiteNoiseService.play(type);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected 
                      ? Colors.red.withOpacity(0.3)
                      : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected 
                        ? Colors.red.withOpacity(0.5)
                        : Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        typeInfo['emoji']!,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        typeInfo['name']!,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 20),
          
          // 控制按钮
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _whiteNoiseService.toggle,
                  icon: Icon(
                    _whiteNoiseService.isPlaying ? Icons.pause : Icons.play_arrow,
                  ),
                  label: Text(
                    _whiteNoiseService.isPlaying ? '暂停' : '播放',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _whiteNoiseService.isPlaying 
                      ? Colors.orange 
                      : Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _whiteNoiseService.stop,
                  icon: const Icon(Icons.stop),
                  label: const Text('停止'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

