import 'dart:ui';
import 'package:file_convertor/core/widgets/ResponsiveWidget.dart';
import 'package:file_convertor/core/widgets/toggle_theme_button.dart';
import 'package:file_convertor/features/vault/view/vault_lock_page.dart';
import 'package:file_convertor/features/vault/view/vault_page.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _sliverHeader(context, theme),

          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveWidget.isMobile(context) ? 16 : 200,
              vertical: 24,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _profileTile(
                  title: "Private Vault",
                  icon: Icons.remove_red_eye_outlined,
                  theme: theme,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const VaultLockPage()),
                    );
                  },
                ),
                _profileTile(
                  title: "History",
                  icon: Icons.history,
                  theme: theme,
                  onTap: () {},
                ),
                _profileTile(
                  title: "Support",
                  icon: Icons.support_agent,
                  theme: theme,
                  onTap: () {},
                ),
                _profileTile(
                  title: "About App",
                  icon: Icons.info_outline,
                  theme: theme,
                  onTap: () {},
                ),
                _profileTile(
                  title: "Logout",
                  icon: Icons.logout,
                  theme: theme,
                  onTap: () {
                    // TODO: logout
                  },
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------
  // SLIVER HEADER
  // -----------------------------------------------------------
  SliverAppBar _sliverHeader(BuildContext context, ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      elevation: 0,
      backgroundColor: theme.scaffoldBackgroundColor,
      automaticallyImplyLeading: false,
      actions: const [ToggleThemeButton(), SizedBox(width: 8)],
      flexibleSpace: FlexibleSpaceBar(
        background: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(50),
            bottomRight: Radius.circular(50),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.18),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      padding: EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: theme.scaffoldBackgroundColor,
                        child: Icon(
                          Icons.person,
                          size: 70,
                          color: theme.canvasColor.withOpacity(0.4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "John Doe",
                      style: theme.textTheme.titleLarge!.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.canvasColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "john@example.com",
                      style: theme.textTheme.bodyMedium!.copyWith(
                        color: theme.canvasColor.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: Icon(Icons.edit, color: theme.canvasColor),
                      label: Text(
                        "Edit Profile",
                        style: TextStyle(color: theme.canvasColor),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // -----------------------------------------------------------
  // PROFILE TILE
  // -----------------------------------------------------------
  Widget _profileTile({
    required String title,
    required IconData icon,
    required ThemeData theme,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
        //color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: theme.primaryColor),
        title: Text(
          title,
          style: theme.textTheme.bodyMedium!.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.canvasColor,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: theme.canvasColor.withOpacity(0.6),
        ),
      ),
    );
  }
}
