import 'package:file_convertor/core/widgets/ResponsiveWidget.dart';
import 'package:file_convertor/features/home/widgets/dashed_rounded_rect_painter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class FileUploadCard extends StatefulWidget {
  final bool isShort;

  const FileUploadCard({super.key, this.isShort = false});

  @override
  State<FileUploadCard> createState() => _FileUploadCardState();
}

class _FileUploadCardState extends State<FileUploadCard> {
  PlatformFile? _selectedFile;
  bool _isUploading = false;
  double _progress = 0;

  bool get hasFile => _selectedFile != null;

  /// ---------------- PICK FILE ----------------
  Future<void> _pickFile() async {
    if (_isUploading) return;

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.any,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() => _selectedFile = result.files.first);
    }
  }

  /// ---------------- UPLOAD FILE ----------------
  Future<void> _uploadFile() async {
    if (!hasFile || _isUploading) return;

    setState(() {
      _isUploading = true;
      _progress = 0;
    });

    /// 🔄 Simulated upload (replace with API progress)
    for (int i = 1; i <= 100; i++) {
      await Future.delayed(const Duration(milliseconds: 30));
      setState(() => _progress = i / 100);
    }

    setState(() => _isUploading = false);

    debugPrint("Upload completed: ${_selectedFile!.name}");
  }

  /// ---------------- COMMON ACTION ----------------
  void _handleAction() {
    hasFile ? _uploadFile() : _pickFile();
  }

  /// ---------------- COMMON BUTTON ----------------
  Widget _actionButton(ThemeData theme, {bool compact = false}) {
    return ElevatedButton(
      onPressed: _isUploading ? null : _handleAction,
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 18 : 28,
          vertical: compact ? 10 : 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
      child: Text(
        _isUploading
            ? "Uploading..."
            : hasFile
            ? "Upload"
            : "Select",
        style: TextStyle(
          fontSize: compact ? 13 : 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// ================= SHORT CARD =================
  Widget _shortCard(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: _isUploading ? null : _pickFile,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor.withOpacity(0.25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.primaryColor.withOpacity(0.12),
              ),
              child: Icon(
                _isUploading
                    ? Icons.cloud_upload_outlined
                    : hasFile
                    ? Icons.insert_drive_file_rounded
                    : Icons.upload_rounded,
                color: theme.primaryColor,
                size: 24,
              ),
            ),

            const SizedBox(height: 10),

            /// File name / status
            Text(
              hasFile ? _selectedFile!.name : "No file selected",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              _isUploading ? "Uploading..." : "Tap to select or upload",
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),

            /// Progress
            if (_isUploading) ...[
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: _progress,
                minHeight: 4,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 6),
              Text(
                "${(_progress * 100).toInt()}%",
                style: theme.textTheme.bodySmall,
              ),
            ],

            const SizedBox(height: 14),

            /// Action button
            _actionButton(theme, compact: true),
          ],
        ),
      ),
    );
  }

  /// ================= FULL CARD =================
  Widget _fullCard(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Container(
        width: ResponsiveWidget.isMobile(context) ? double.infinity : 500,
        padding: const EdgeInsets.all(20),
        child: AbsorbPointer(
          absorbing: _isUploading,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: _pickFile,
            child: CustomPaint(
              painter: DashedRoundedRectPainter(
                radius: 18,
                strokeWidth: 2.4,
                color: theme.canvasColor.withOpacity(0.5),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 36,
                ),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    /// Icon
                    Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.primaryColor.withOpacity(0.1),
                      ),
                      child: Icon(
                        _isUploading
                            ? Icons.cloud_upload_outlined
                            : hasFile
                            ? Icons.insert_drive_file_rounded
                            : Icons.upload_rounded,
                        size: 48,
                        color: theme.primaryColor,
                      ),
                    ),

                    const SizedBox(height: 22),

                    /// Title
                    Text(
                      _isUploading
                          ? "Uploading file..."
                          : hasFile
                          ? "Selected file"
                          : "Drop files here or click to select",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    if (hasFile) ...[
                      const SizedBox(height: 10),
                      Text(
                        _selectedFile!.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],

                    if (_isUploading) ...[
                      const SizedBox(height: 18),
                      LinearProgressIndicator(
                        value: _progress,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      const SizedBox(height: 8),
                      Text("${(_progress * 100).toInt()}%"),
                    ],

                    if (!hasFile && !_isUploading) ...[
                      const SizedBox(height: 10),
                      Text(
                        "Text • Documents • Images • Audio • Video • Archives",
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],

                    const SizedBox(height: 28),
                    _actionButton(theme),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    return widget.isShort ? _shortCard(context) : _fullCard(context);
  }
}
