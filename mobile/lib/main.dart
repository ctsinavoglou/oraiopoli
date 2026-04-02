import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: OraiopliApp()));
}

/// Allows mouse drag scrolling on web (horizontal lists, PageView, etc.)
class _AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}

class OraiopliApp extends ConsumerWidget {
  const OraiopliApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    final app = MaterialApp.router(
      title: 'Oraiopoli',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      scrollBehavior: _AppScrollBehavior(),
      routerConfig: router,
    );

    if (!kIsWeb) return app;
    return _DevicePreviewShell(child: app);
  }
}

// ── Device definitions ──
class _DeviceInfo {
  final String name;
  final double width;
  final double height;
  final double bezelRadius;
  final IconData icon;

  const _DeviceInfo(this.name, this.width, this.height, this.bezelRadius, this.icon);
}

const _devices = [
  // Apple iPhones
  _DeviceInfo('iPhone 16 Pro Max', 440, 956,  55, Icons.phone_iphone),
  _DeviceInfo('iPhone 16 Pro',     402, 874,  55, Icons.phone_iphone),
  _DeviceInfo('iPhone 16',         393, 852,  47, Icons.phone_iphone),
  _DeviceInfo('iPhone 15',         393, 852,  47, Icons.phone_iphone),
  _DeviceInfo('iPhone 14',         390, 844,  47, Icons.phone_iphone),
  _DeviceInfo('iPhone SE',         375, 667,  20, Icons.phone_iphone),
  // Android phones
  _DeviceInfo('Pixel 9 Pro',       412, 915,  35, Icons.phone_android),
  _DeviceInfo('Pixel 8',           412, 915,  35, Icons.phone_android),
  _DeviceInfo('Samsung S25 Ultra', 412, 915,  35, Icons.phone_android),
  _DeviceInfo('Samsung S24',       360, 780,  35, Icons.phone_android),
  _DeviceInfo('Samsung A55',       384, 854,  35, Icons.phone_android),
  _DeviceInfo('OnePlus 12',        412, 915,  35, Icons.phone_android),
  _DeviceInfo('Xiaomi 14',         393, 873,  35, Icons.phone_android),
  // Tablets
  _DeviceInfo('iPad Mini',         744, 1133, 20, Icons.tablet_mac),
  _DeviceInfo('iPad Air',          820, 1180, 20, Icons.tablet_mac),
  _DeviceInfo('iPad Pro 11"',      834, 1194, 20, Icons.tablet_mac),
  _DeviceInfo('iPad Pro 13"',     1024, 1366, 20, Icons.tablet_mac),
  _DeviceInfo('Galaxy Tab S9',     800, 1280, 16, Icons.tablet_android),
  _DeviceInfo('Pixel Tablet',      800, 1280, 16, Icons.tablet_android),
];

// ── Shell that wraps the app in a phone frame on web ──
class _DevicePreviewShell extends StatefulWidget {
  final Widget child;
  const _DevicePreviewShell({required this.child});

  @override
  State<_DevicePreviewShell> createState() => _DevicePreviewShellState();
}

class _DevicePreviewShellState extends State<_DevicePreviewShell> {
  int _selected = 0;
  bool _showFrame = true;

  @override
  Widget build(BuildContext context) {
    final device = _devices[_selected];
    final screenSize = MediaQuery.of(context).size;

    // If browser is narrow, just show the app normally
    if (screenSize.width < 500) return widget.child;

    final maxH = screenSize.height - 40;
    final scale = (device.height + 40 > maxH) ? maxH / (device.height + 40) : 1.0;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(useMaterial3: true),
      home: Scaffold(
        backgroundColor: const Color(0xFF1a1a2e),
        body: Row(
          children: [
            // ── Phone frame (center) ──
            Expanded(
              child: Center(
                child: Transform.scale(
                  scale: scale,
                  child: _showFrame
                      ? _PhoneFrame(device: device, child: widget.child)
                      : SizedBox(width: device.width, height: device.height, child: widget.child),
                ),
              ),
            ),

            // ── Device picker (right panel) ──
            Container(
              width: 200,
              decoration: const BoxDecoration(
                color: Color(0xFF16213e),
                border: Border(left: BorderSide(color: Color(0xFF0f3460), width: 1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 20, 16, 4),
                    child: Text('DEVICES', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                  ),
                  const Divider(color: Colors.white12, height: 1),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _devices.length,
                      itemBuilder: (_, i) {
                        final d = _devices[i];
                        final active = i == _selected;
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => setState(() => _selected = i),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              color: active ? Colors.white.withValues(alpha: 0.08) : null,
                              child: Row(
                                children: [
                                  Icon(d.icon, size: 18, color: active ? Colors.cyanAccent : Colors.white38),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(d.name, style: TextStyle(color: active ? Colors.white : Colors.white70, fontSize: 13, fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
                                        Text('${d.width.toInt()} × ${d.height.toInt()}', style: const TextStyle(color: Colors.white30, fontSize: 10)),
                                      ],
                                    ),
                                  ),
                                  if (active)
                                    const Icon(Icons.check_circle, size: 16, color: Colors.cyanAccent),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(color: Colors.white12, height: 1),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Text('Frame', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        const Spacer(),
                        SizedBox(
                          height: 24,
                          child: Switch(
                            value: _showFrame,
                            onChanged: (v) => setState(() => _showFrame = v),
                            activeColor: Colors.cyanAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── The phone bezel frame ──
class _PhoneFrame extends StatelessWidget {
  final _DeviceInfo device;
  final Widget child;
  const _PhoneFrame({required this.device, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: device.width + 24,
      height: device.height + 40,
      decoration: BoxDecoration(
        color: const Color(0xFF2d2d2d),
        borderRadius: BorderRadius.circular(device.bezelRadius + 8),
        border: Border.all(color: const Color(0xFF444444), width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 30, spreadRadius: 5),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(device.bezelRadius),
        child: SizedBox(
          width: device.width,
          height: device.height,
          child: MediaQuery(
            data: MediaQueryData(size: Size(device.width, device.height)),
            child: child,
          ),
        ),
      ),
    );
  }
}
