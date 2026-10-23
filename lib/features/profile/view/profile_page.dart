import 'package:file_convertor/app/theme/app_palette.dart';
import 'package:file_convertor/app/theme/app_tokens.dart';
import 'package:file_convertor/app/theme/app_typography.dart';
import 'package:file_convertor/app/theme/theme_notifier.dart';
import 'package:file_convertor/core/utils/file_format.dart';
import 'package:file_convertor/core/widgets/app_button.dart';
import 'package:file_convertor/core/widgets/brand_mark.dart';
import 'package:file_convertor/core/widgets/custom_text_form_field.dart';
import 'package:file_convertor/core/widgets/segmented_toggle.dart';
import 'package:file_convertor/core/widgets/toggle_theme_button.dart';
import 'package:file_convertor/features/history/data/activity.dart';
import 'package:file_convertor/features/history/view/history_page.dart';
import 'package:file_convertor/features/profile/data/profile.dart';
import 'package:file_convertor/features/storage/storage_providers.dart';
import 'package:file_convertor/features/vault/view/vault_lock_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

final _packageInfoProvider = FutureProvider<PackageInfo>(
  (ref) => PackageInfo.fromPlatform(),
);

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final p = context.palette;
    final gutter = AppSpace.gutter(MediaQuery.sizeOf(context).width);
    final activity = ref.watch(activityProvider).value ?? const [];
    final storage = ref.watch(storageSnapshotProvider).value;
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            automaticallyImplyLeading: false,
            titleSpacing: gutter,
            title: Text(
              'PROFILE',
              style: AppType.eyebrow.copyWith(color: p.inkMuted),
            ),
            actions: [
              const ToggleThemeButton(),
              SizedBox(width: gutter - AppSpace.xs),
            ],
          ),

          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              gutter,
              AppSpace.md,
              gutter,
              AppSpace.navClearance,
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
                      const _ProfileHeader(),
                      const SizedBox(height: AppSpace.xl),
                      _group(context, [
                        _tile(
                          context,
                          title: "Private Vault",
                          subtitle: storage == null
                              ? 'Encrypted files'
                              : '${FileFormat.formatBytes(storage.app.vault)} encrypted',
                          icon: Icons.lock_outline,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const VaultLockPage(),
                            ),
                          ),
                        ),
                        _tile(
                          context,
                          title: "History",
                          subtitle: activity.isEmpty
                              ? 'No activity yet'
                              : '${activity.length} ${activity.length == 1 ? 'item' : 'items'}',
                          icon: Icons.history,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HistoryPage(),
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: AppSpace.lg),
                      Text(
                        'APPEARANCE',
                        style: AppType.eyebrow.copyWith(color: p.inkMuted),
                      ),
                      const SizedBox(height: AppSpace.sm),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SegmentedToggle(
                          segments: const ['System', 'Light', 'Dark'],
                          segmentWidth: 92,
                          selectedIndex: switch (themeMode) {
                            ThemeMode.system => 0,
                            ThemeMode.light => 1,
                            ThemeMode.dark => 2,
                          },
                          onChanged: (i) => ref
                              .read(themeProvider.notifier)
                              .setMode(
                                const [
                                  ThemeMode.system,
                                  ThemeMode.light,
                                  ThemeMode.dark,
                                ][i],
                              ),
                        ),
                      ),
                      const SizedBox(height: AppSpace.lg),
                      _group(context, [
                        _tile(
                          context,
                          title: "About App",
                          subtitle: ref
                              .watch(_packageInfoProvider)
                              .whenOrNull(
                                data: (info) =>
                                    'Version ${info.version} (${info.buildNumber})',
                              ),
                          icon: Icons.info_outline,
                          onTap: () => _showAbout(context, ref),
                        ),
                      ]),
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

  static void _showAbout(BuildContext context, WidgetRef ref) {
    final info = ref.read(_packageInfoProvider).value;
    showLicensePage(
      context: context,
      applicationName: 'File Convertor',
      applicationVersion: info == null
          ? null
          : '${info.version} (${info.buildNumber})',
      applicationIcon: const Padding(
        padding: EdgeInsets.all(AppSpace.md),
        child: BrandMark(size: 48, showWordmark: false),
      ),
      applicationLegalese:
          'Conversions run on this device. Vault files are encrypted with '
          'AES-256-GCM. Nothing is uploaded.',
    );
  }

  Widget _group(BuildContext context, List<Widget> tiles) {
    final p = context.palette;
    return Material(
      color: p.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.card,
        side: BorderSide(color: p.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) Divider(indent: 64, color: p.line),
            tiles[i],
          ],
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required String title,
    String? subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    return ListTile(
      onTap: onTap,
      shape: const RoundedRectangleBorder(),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: p.surfaceSunken,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(icon, size: 19, color: p.ink),
      ),
      title: Text(title, style: text.titleSmall),
      subtitle: subtitle == null ? null : Text(subtitle, style: text.bodySmall),
      trailing: Icon(Icons.chevron_right, size: 20, color: p.inkMuted),
    );
  }
}

class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final profile = ref.watch(profileProvider).value ?? const UserProfile();

    return Row(
      children: [
        Container(
          width: 76,
          height: 76,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: p.ink,
            shape: BoxShape.circle,
            border: Border.all(color: p.accent, width: 2),
          ),
          child: ExcludeSemantics(
            child: profile.isEmpty
                ? Icon(Icons.person_outline, size: 34, color: p.paper)
                : Text(
                    profile.initials,
                    style: TextStyle(
                      fontFamily: AppFonts.serif,
                      fontSize: 32,
                      color: p.paper,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: AppSpace.md + 2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.isEmpty ? 'Welcome' : profile.name,
                style: text.headlineMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                profile.email.isEmpty
                    ? 'Stored on this device only'
                    : profile.email,
                style: AppType.mono.copyWith(color: p.inkMuted, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpace.sm),
              AppButton(
                label: profile.isEmpty ? "Add your name" : "Edit Profile",
                icon: Icons.edit_outlined,
                onPressed: () => _edit(context, ref, profile),
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.small,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    UserProfile current,
  ) async {
    final name = TextEditingController(text: current.name);
    final email = TextEditingController(text: current.email);
    final formKey = GlobalKey<FormState>();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.palette.surface,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpace.lg,
          0,
          AppSpace.lg,
          AppSpace.lg + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Your profile',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                'Saved on this device only.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpace.lg),
              CustomTextFormField(
                controller: name,
                labelText: 'Name',
                hintText: 'Your name',
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                prefix: const Icon(Icons.person_outline),
                validator: (v) => (v ?? '').trim().length > 60
                    ? 'Keep it under 60 characters'
                    : null,
              ),
              const SizedBox(height: AppSpace.md),
              CustomTextFormField(
                controller: email,
                labelText: 'Email (optional)',
                hintText: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                prefix: const Icon(Icons.alternate_email),
                validator: (v) {
                  final value = (v ?? '').trim();
                  if (value.isEmpty) return null;
                  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)
                      ? null
                      : 'Enter a valid email address';
                },
              ),
              const SizedBox(height: AppSpace.lg),
              AppButton(
                label: 'Save',
                onPressed: () {
                  if (formKey.currentState?.validate() ?? false) {
                    Navigator.pop(context, true);
                  }
                },
                size: AppButtonSize.large,
                expand: true,
              ),
            ],
          ),
        ),
      ),
    );

    if (saved == true) {
      await ref
          .read(profileProvider.notifier)
          .save(UserProfile(name: name.text, email: email.text));
    }
  }
}
