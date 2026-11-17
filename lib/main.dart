import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const KirGptApp());

class KirGptApp extends StatelessWidget {
  const KirGptApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'KirGpt',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: true),
        home: const LightScreen(),
      );
}

class LightScreen extends StatefulWidget {
  const LightScreen({super.key});

  @override
  State<LightScreen> createState() => _LightScreenState();
}

class _LightScreenState extends State<LightScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _native = MethodChannel('com.kirgpt.app/device');
  static const _colors = <String, Color>{
    'Kırmızı': Color(0xFFFF0000),
    'Mavi': Color(0xFF075BFF),
    'Yeşil': Color(0xFF00C853),
    'Mor': Color(0xFF9C27B0),
    'Turuncu': Color(0xFFFF6D00),
    'Beyaz': Color(0xFFFFFFFF),
  };

  late AnimationController _controller;
  String _colorName = 'Kırmızı';
  double _rampSeconds = 15;
  double _minimumBrightness = 20;
  double _maximumBrightness = 100;
  double _holdSeconds = 4;
  bool _smoothTransition = true;
  bool _peakVibration = false;
  bool _isSettingsOpen = false;
  double _previousPhase = 0;
  double _lastAppliedBrightness = -1;
  bool _wasPaused = false;

  double get _cycleSeconds => (_rampSeconds * 2) + _holdSeconds;
  Color get _activeColor => _colors[_colorName]!;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (_cycleSeconds * 1000).round()),
    )..addListener(_updateLight);
    _start();
  }

  Future<void> _start() async {
    try {
      await _native.invokeMethod('keepScreenOn', true);
      await _native.invokeMethod('immersiveMode');
    } catch (_) {}
    _controller.repeat();
    _updateLight();
  }

  double _curve(double value) {
    if (!_smoothTransition) return value;
    // Smoothstep: yumuşak başlangıç ve bitiş.
    return value * value * (3 - 2 * value);
  }

  void _updateLight() {
    if (!mounted) return;
    final elapsed = _controller.value * _cycleSeconds;
    final phase = elapsed % _cycleSeconds;
    double level;
    if (phase < _rampSeconds) {
      level = _curve(phase / _rampSeconds);
    } else if (phase < _rampSeconds + _holdSeconds) {
      level = 1;
    } else {
      final down = (phase - _rampSeconds - _holdSeconds) / _rampSeconds;
      level = 1 - _curve(down.clamp(0.0, 1.0));
    }
    final brightness = (_minimumBrightness +
            (_maximumBrightness - _minimumBrightness) * level) /
        100;
    if ((brightness - _lastAppliedBrightness).abs() >= 0.008) {
      _lastAppliedBrightness = brightness;
      _native.invokeMethod('setBrightness', brightness).catchError((_) {});
    }
    if (_peakVibration && _previousPhase < _rampSeconds &&
        phase >= _rampSeconds) {
      _native.invokeMethod('vibratePeak').catchError((_) {});
    }
    _previousPhase = phase;
  }

  void _applySettings() {
    final newDuration = Duration(milliseconds: (_cycleSeconds * 1000).round());
    final wasRunning = _controller.isAnimating;
    _controller.duration = newDuration;
    if (wasRunning) _controller
      ..stop()
      ..repeat();
    _lastAppliedBrightness = -1;
    _updateLight();
  }

  Future<void> _openSettings() async {
    if (_isSettingsOpen) return;
    setState(() => _isSettingsOpen = true);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF202020),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, refreshSheet) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                22, 20, 22, 20 + MediaQuery.of(context).viewInsets.bottom),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Expanded(
                      child: Text('KirGpt Ayarları',
                          style: TextStyle(
                              fontSize: 21, fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  const Text('Ekran rengi', style: TextStyle(fontSize: 15)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 9,
                    runSpacing: 9,
                    children: _colors.entries.map((entry) {
                      final selected = _colorName == entry.key;
                      return InkWell(
                        onTap: () {
                          setState(() => _colorName = entry.key);
                          refreshSheet(() {});
                        },
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 9),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: selected ? Colors.white : Colors.white24,
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            CircleAvatar(radius: 8, backgroundColor: entry.value),
                            const SizedBox(width: 7),
                            Text(entry.key),
                          ]),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 22),
                  _sliderSetting(
                    title: 'Parlaklık değişim süresi',
                    value: _rampSeconds,
                    min: 5,
                    max: 60,
                    suffix: 'sn',
                    onChanged: (value) => setState(() => _rampSeconds = value),
                    refresh: refreshSheet,
                  ),
                  _sliderSetting(
                    title: 'En yüksek parlaklıkta bekleme',
                    value: _holdSeconds,
                    min: 0,
                    max: 15,
                    suffix: 'sn',
                    onChanged: (value) => setState(() => _holdSeconds = value),
                    refresh: refreshSheet,
                  ),
                  const Divider(height: 26, color: Colors.white24),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Yumuşak parlaklık geçişi'),
                    subtitle: const Text('Işık daha doğal şekilde yükselip azalır'),
                    value: _smoothTransition,
                    onChanged: (value) => setState(() => _smoothTransition = value),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Zirvede kısa titreşim'),
                    subtitle: const Text('En yüksek parlaklığa ulaşıldığında titreşim verir'),
                    value: _peakVibration,
                    onChanged: (value) => setState(() => _peakVibration = value),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        _applySettings();
                        Navigator.pop(sheetContext);
                      },
                      child: const Text('Uygula'),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Ayarları tekrar açmak için ekrana iki kez hızlıca dokunun.',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (mounted) setState(() => _isSettingsOpen = false);
  }

  Widget _sliderSetting({
    required String title,
    required double value,
    required double min,
    required double max,
    required String suffix,
    required ValueChanged<double> onChanged,
    required StateSetter refresh,
  }) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(title, style: const TextStyle(fontSize: 15))),
            Text('${value.round()} $suffix',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ]),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: (max - min).round(),
            onChanged: (next) {
              onChanged(next);
              refresh(() {});
            },
          ),
        ],
      );

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _wasPaused = _controller.isAnimating;
      _controller.stop();
    } else if (state == AppLifecycleState.resumed && _wasPaused) {
      _controller.repeat();
      _wasPaused = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_updateLight);
    _controller.dispose();
    _native.invokeMethod('resetBrightness').catchError((_) {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _activeColor,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onDoubleTap: _openSettings,
          child: SizedBox.expand(
            child: ColoredBox(color: _activeColor),
          ),
        ),
      );
}
