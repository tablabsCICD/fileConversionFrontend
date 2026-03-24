import 'package:file_convertor/features/file_conversion/data/helper/conversion_helper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../data/models/conversion_section.dart';

class FileUploadPage extends StatefulWidget {
  final ConversionItem item;

  const FileUploadPage({super.key, required this.item});

  @override
  State<FileUploadPage> createState() => _FileUploadPageState();
}

class _FileUploadPageState extends State<FileUploadPage> {
  PlatformFile? _file;

  late final List<String> allowedExtensions =
      ConversionHelper.allowedExtensionsFromTitle(widget.item.title);

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: allowedExtensions.isEmpty ? FileType.any : FileType.custom,
      allowedExtensions: allowedExtensions,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() => _file = result.files.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          /// --------------------------------------------------
          /// Sliver AppBar
          /// --------------------------------------------------
          SliverAppBar(
            floating: true,
            snap: true,
            elevation: 0,
            backgroundColor: theme.scaffoldBackgroundColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(widget.item.title, style: theme.textTheme.titleMedium),
            centerTitle: false,
          ),

          /// --------------------------------------------------
          /// Main Content
          /// --------------------------------------------------
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      /// ---------------- TITLE ----------------
                      Text(
                        "Convert ${widget.item.title}",
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 12),

                      Text(
                        ConversionHelper.subtitleFromTitle(widget.item.title),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.hintColor,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 40),

                      /// ---------------- UPLOAD CARD ----------------
                      GestureDetector(
                        onTap: _pickFile,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 36,
                            horizontal: 24,
                          ),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: theme.dividerColor.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                widget.item.icon,
                                size: 56,
                                color: widget.item.color,
                              ),
                              const SizedBox(height: 20),

                              ElevatedButton(
                                onPressed: _pickFile,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  allowedExtensions.isEmpty
                                      ? "Select file"
                                      : "Select ${allowedExtensions.join(", ").toUpperCase()} file",
                                ),
                              ),

                              const SizedBox(height: 16),

                              Text(
                                "or drop file here",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.hintColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      /// ---------------- SELECTED FILE ----------------
                      if (_file != null) ...[
                        const SizedBox(height: 24),
                        _SelectedFileTile(
                          fileName: _file!.name,
                          onRemove: () => setState(() => _file = null),
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

class _SelectedFileTile extends StatelessWidget {
  final String fileName;
  final VoidCallback onRemove;

  const _SelectedFileTile({required this.fileName, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file),
          const SizedBox(width: 12),
          Expanded(child: Text(fileName, overflow: TextOverflow.ellipsis)),
          IconButton(icon: const Icon(Icons.close), onPressed: onRemove),
        ],
      ),
    );
  }
}
