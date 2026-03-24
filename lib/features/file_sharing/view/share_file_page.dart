import 'dart:io';
import 'package:file_convertor/core/widgets/ResponsiveWidget.dart';
import 'package:file_convertor/features/file_sharing/services/file_server.dart';
import 'package:file_convertor/features/file_sharing/services/network_service.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class ShareFilePage extends StatefulWidget {
  const ShareFilePage({super.key});

  @override
  State<ShareFilePage> createState() => _ShareFilePageState();
}

class _ShareFilePageState extends State<ShareFilePage> {
  File? file;
  String? ip;
  int? port;
  final server = FileServer();

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null) return;

    file = File(result.files.single.path!);
    ip = await NetworkService.getLocalIp();
    port = await server.start(file!);
    setState(() {});
  }

  @override
  void dispose() {
    server.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(pinned: true, title: Text("Send File")),
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveWidget.isDesktop(context) ? 140 : 20,
              vertical: 24,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PrimaryButton(label: "Choose File", onTap: pickFile),
                  const SizedBox(height: 24),
                  if (file != null) _ShareInfo(theme, file!, ip, port),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareInfo extends StatelessWidget {
  final ThemeData theme;
  final File file;
  final String? ip;
  final int? port;

  const _ShareInfo(this.theme, this.file, this.ip, this.port);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Sharing Details", style: theme.textTheme.titleSmall),
          const SizedBox(height: 12),
          SelectableText(
            "File: ${file.path.split('/').last}\n"
            "IP: $ip\n"
            "Port: $port",
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: onTap,
        child: Text(label),
      ),
    );
  }
}
