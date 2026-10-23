import 'package:file_convertor/app/theme/app_palette.dart';
import 'package:file_convertor/app/theme/app_tokens.dart';
import 'dart:io';

import 'package:file_convertor/core/services/file_actions.dart';
import 'package:file_convertor/core/utils/file_format.dart';
import 'package:file_convertor/core/widgets/app_button.dart';
import 'package:file_convertor/core/widgets/custom_text_form_field.dart';
import 'package:file_convertor/core/widgets/file_tile.dart';
import 'package:file_convertor/core/widgets/inline_notice.dart';
import 'package:file_convertor/core/widgets/progress_track.dart';
import 'package:file_convertor/features/file_sharing/services/file_client.dart';
import 'package:file_convertor/features/history/data/activity.dart';
import 'package:file_convertor/features/storage/storage_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReceiveFilePage extends ConsumerStatefulWidget {
  const ReceiveFilePage({super.key});

  @override
  ConsumerState<ReceiveFilePage> createState() => _ReceiveFilePageState();
}

class _ReceiveFilePageState extends ConsumerState<ReceiveFilePage> {
  final ipCtrl = TextEditingController();
  final portCtrl = TextEditingController();
  String status = "";
  NoticeTone _tone = NoticeTone.info;
  bool _receiving = false;
  double? _progress;
  File? _received;

  @override
  void dispose() {
    ipCtrl.dispose();
    portCtrl.dispose();
    super.dispose();
  }

  Future<void> receive() async {
    final port = int.tryParse(portCtrl.text.trim());
    if (ipCtrl.text.trim().isEmpty || port == null) {
      setState(() {
        _tone = NoticeTone.warning;
        status = "Enter the sender's IP address and port number.";
      });
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _receiving = true;
      _progress = null;
      _received = null;
      status = "";
    });
    try {
      final file = await FileClient.download(
        ipCtrl.text.trim(),
        port,
        onProgress: (v) {
          if (mounted) setState(() => _progress = v);
        },
      );
      if (!mounted) return;
      final size = await file.length();
      setState(() {
        _received = file;
        _tone = NoticeTone.success;
        status = "File received successfully";
      });
      ref
          .read(activityProvider.notifier)
          .add(
            ActivityEntry.create(
              kind: ActivityKind.received,
              name: file.uri.pathSegments.last,
              sizeBytes: size,
              path: file.path,
            ),
          );
      ref.invalidate(storageSnapshotProvider);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _tone = NoticeTone.danger;
        status =
            "Couldn't reach the sender. Check that both devices are on the "
            "same network and the details are correct.";
      });
    } finally {
      if (mounted) setState(() => _receiving = false);
    }
  }

  Future<void> _open(File file) async {
    final error = await FileActions.open(file.path);
    if (error != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gutter = AppSpace.gutter(MediaQuery.sizeOf(context).width);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(pinned: true, title: Text("Receive File")),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Connect to sender',
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: AppSpace.xs - 2),
                      Text(
                        'Enter the address shown on the sending device.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: context.palette.inkMuted,
                        ),
                      ),
                      const SizedBox(height: AppSpace.lg),
                      CustomTextFormField(
                        controller: ipCtrl,
                        labelText: 'Sender IP',
                        hintText: "192.168.1.24",
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.next,
                        prefix: const Icon(Icons.lan_outlined),
                      ),
                      const SizedBox(height: AppSpace.md),
                      CustomTextFormField(
                        labelText: 'Port',
                        hintText: "8080",
                        controller: portCtrl,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        prefix: const Icon(Icons.numbers),
                      ),
                      const SizedBox(height: AppSpace.lg),
                      AppButton(
                        label: _receiving ? "Receiving…" : "Receive",
                        icon: Icons.south_west,
                        onPressed: receive,
                        isLoading: _receiving,
                        size: AppButtonSize.large,
                        expand: true,
                      ),
                      if (_receiving) ...[
                        const SizedBox(height: AppSpace.md),
                        ProgressTrack(label: 'Receiving', value: _progress),
                      ],
                      if (status.isNotEmpty) ...[
                        const SizedBox(height: AppSpace.md),
                        InlineNotice(title: status, tone: _tone),
                      ],
                      if (_received case final file?) ...[
                        const SizedBox(height: AppSpace.md),
                        FileTile(
                          name: file.uri.pathSegments.last,
                          sizeLabel: FileFormat.formatBytes(file.lengthSync()),
                          caption: 'Saved in Received',
                          highlighted: true,
                          onTap: () => _open(file),
                        ),
                        const SizedBox(height: AppSpace.sm),
                        Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                label: 'Open',
                                icon: Icons.open_in_new,
                                onPressed: () => _open(file),
                                expand: true,
                              ),
                            ),
                            const SizedBox(width: AppSpace.sm),
                            Expanded(
                              child: AppButton(
                                label: 'Save a copy',
                                icon: Icons.download_rounded,
                                variant: AppButtonVariant.secondary,
                                onPressed: () =>
                                    FileActions.saveCopyOf(file.path),
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
