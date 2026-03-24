import 'package:file_convertor/core/widgets/ResponsiveWidget.dart';
import 'package:file_convertor/core/widgets/custom_text_form_field.dart';
import 'package:file_convertor/features/file_sharing/services/file_client.dart';
import 'package:flutter/material.dart';

class ReceiveFilePage extends StatefulWidget {
  const ReceiveFilePage({super.key});

  @override
  State<ReceiveFilePage> createState() => _ReceiveFilePageState();
}

class _ReceiveFilePageState extends State<ReceiveFilePage> {
  final ipCtrl = TextEditingController();
  final portCtrl = TextEditingController();
  String status = "";

  Future<void> receive() async {
    setState(() => status = "Receiving file...");
    await FileClient.download(ipCtrl.text, int.parse(portCtrl.text));
    setState(() => status = "File received successfully");
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(pinned: true, title: Text("Receive File")),
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveWidget.isDesktop(context) ? 140 : 20,
              vertical: 24,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  CustomTextFormField(
                    controller: ipCtrl,
                    hintText: "Sender IP",
                  ),
                  const SizedBox(height: 12),
                  CustomTextFormField(
                    hintText: "Port",
                    controller: portCtrl,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  _PrimaryButton(label: "Receive", onTap: receive),
                  const SizedBox(height: 16),
                  Text(status, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
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
          foregroundColor: theme.colorScheme.onPrimary,
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

// class _InputField extends StatelessWidget {
//   final String label;
//   final TextEditingController controller;
//   final TextInputType? keyboardType;

//   const _InputField(this.label, this.controller, {this.keyboardType});

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     return TextField(
//       controller: controller,
//       keyboardType: keyboardType,
//       decoration: InputDecoration(
//         labelText: label,
//         filled: true,
//         fillColor: theme.canvasColor,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: BorderSide.none,
//         ),
//       ),
//     );
//   }
// }
