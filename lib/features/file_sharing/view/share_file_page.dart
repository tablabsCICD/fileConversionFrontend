import 'dart:io';
import 'package:file_convertor/app/theme/app_palette.dart';
import 'package:file_convertor/app/theme/app_tokens.dart';
import 'package:file_convertor/app/theme/app_typography.dart';
import 'package:file_convertor/core/utils/file_format.dart';
import 'package:file_convertor/core/widgets/app_button.dart';
import 'package:file_convertor/core/widgets/drop_zone.dart';
import 'package:file_convertor/core/widgets/file_tile.dart';
import 'package:file_convertor/core/widgets/inline_notice.dart';
import 'package:file_convertor/features/file_sharing/services/file_server.dart';
import 'package:file_convertor/features/file_sharing/services/network_service.dart';
import 'package:file_convertor/features/history/data/activity.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ShareFilePage extends ConsumerStatefulWidget {
  const ShareFilePage({super.key});

  @override
  ConsumerState<ShareFilePage> createState() => _ShareFilePageState();
}

class _ShareFilePageState extends ConsumerState<ShareFilePage> {
  File? file;
  String? ip;
  int? port;
  int _downloads = 0;
  bool _starting = false;
  String? _error;
  final server = FileServer();

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.single.path == null) return;

    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      final picked = File(result.files.single.path!);
      final localIp = await NetworkService.getLocalIp();
      final openPort = await server.start(
        picked,
        onDownload: (count) {
          if (mounted) setState(() => _downloads = count);
        },
      );
      if (!mounted) return;
      setState(() {
        file = picked;
        ip = localIp;
        port = openPort;
        _downloads = 0;
      });
      ref
          .read(activityProvider.notifier)
          .add(
            ActivityEntry.create(
              kind: ActivityKind.sent,
              name: result.files.single.name,
              sizeBytes: result.files.single.size,
            ),
          );
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not start sharing: $e');
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  void _stop() {
    server.stop();
    setState(() {
      file = null;
      port = null;
      _downloads = 0;
    });
  }

  @override
  void dispose() {
    server.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gutter = AppSpace.gutter(MediaQuery.sizeOf(context).width);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(pinned: true, title: Text("Send File")),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              gutter,
              AppSpace.md,
              gutter,
              AppSpace.xxl,
            ),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppBreakpoints.content,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (kIsWeb)
                        const InlineNotice(
                          tone: NoticeTone.warning,
                          title: 'Sending needs the mobile or desktop app',
                          message: 'Browsers cannot host files for others.',
                        )
                      else if (file == null) ...[
                        DropZone(
                          onTap: _starting ? null : pickFile,
                          title: _starting
                              ? 'Starting…'
                              : 'Choose a file to send',
                          caption:
                              'Devices on the same Wi-Fi or hotspot can '
                              'download it',
                          actionLabel: 'Choose File',
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: AppSpace.md),
                          InlineNotice(tone: NoticeTone.danger, title: _error!),
                        ],
                      ] else ...[
                        _ShareInfo(file!, ip, port, _downloads),
                        const SizedBox(height: AppSpace.md),
                        Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                label: 'Send another',
                                icon: Icons.swap_horiz,
                                variant: AppButtonVariant.secondary,
                                onPressed: pickFile,
                                expand: true,
                              ),
                            ),
                            const SizedBox(width: AppSpace.sm),
                            Expanded(
                              child: AppButton(
                                label: 'Stop sharing',
                                icon: Icons.stop_circle_outlined,
                                variant: AppButtonVariant.ink,
                                onPressed: _stop,
                                expand: true,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareInfo extends StatelessWidget {
  final File file;
  final String? ip;
  final int? port;
  final int downloads;

  const _ShareInfo(this.file, this.ip, this.port, this.downloads);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final name = file.path.split(Platform.pathSeparator).last;
    final url = ip == null || port == null ? null : 'http://$ip:$port/';

    return Container(
      padding: const EdgeInsets.all(AppSpace.lg - 4),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: AppRadius.sheet,
        border: Border.all(color: p.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: p.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpace.xs),
              Expanded(
                child: Text(
                  'SHARING',
                  style: AppType.eyebrow.copyWith(color: p.success),
                ),
              ),
              Semantics(
                liveRegion: true,
                child: Text(
                  '$downloads ${downloads == 1 ? 'DOWNLOAD' : 'DOWNLOADS'}',
                  style: AppType.eyebrow.copyWith(color: p.inkMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          FileTile(
            name: name,
            sizeLabel: FileFormat.formatBytes(file.lengthSync()),
            caption: downloads == 0 ? 'Waiting for receiver' : 'Downloaded',
          ),
          const SizedBox(height: AppSpace.lg - 4),
          if (url == null)
            const InlineNotice(
              tone: NoticeTone.warning,
              title: 'Not connected to Wi-Fi',
              message:
                  'Join a Wi-Fi network (or turn on your hotspot and connect '
                  'the other device to it), then send again.',
            )
          else ...[
            Center(
              child: Container(
                padding: const EdgeInsets.all(AppSpace.sm),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppRadius.control,
                ),
                child: QrImageView(
                  data: url,
                  size: 176,
                  padding: EdgeInsets.zero,
                  semanticsLabel: 'QR code for $url',
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF17160F),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF17160F),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            Center(
              child: Text(
                'Scan with any phone camera to download',
                style: text.bodySmall,
              ),
            ),
            const SizedBox(height: AppSpace.lg - 4),
            Text(
              'Or, in this app on the other device, enter:',
              style: text.bodyMedium?.copyWith(color: p.inkMuted),
            ),
            const SizedBox(height: AppSpace.sm),
            _Field(label: 'IP', value: ip!),
            const SizedBox(height: AppSpace.xs),
            _Field(label: 'Port', value: '$port'),
          ],
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.sm,
      ),
      decoration: BoxDecoration(
        color: p.paper,
        borderRadius: AppRadius.control,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              label.toUpperCase(),
              style: AppType.eyebrow.copyWith(color: p.inkMuted),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: AppType.mono.copyWith(
                fontSize: 20,
                color: p.ink,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
