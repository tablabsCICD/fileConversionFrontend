import 'package:file_convertor/core/services/permissions_service.dart';
import 'package:file_convertor/features/history/data/activity.dart';
import 'package:file_convertor/features/history/view/history_page.dart';
import 'package:file_convertor/features/history/widgets/activity_tile.dart';
import 'package:file_convertor/features/home/widgets/storage_overview.dart';
import 'package:file_convertor/features/vault/data/vault_auth_service.dart';
import 'package:file_convertor/features/vault/widgets/passcode_field.dart';
import 'package:file_convertor/features/vault/widgets/vault_setup_flow.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:widgetbook/widgetbook.dart';

import '../support/mocks.dart';
import '../support/showcase.dart';

final features = WidgetbookFolder(
  name: 'Features',
  children: [
    WidgetbookComponent(
      name: 'Storage overview',
      useCases: [
        for (final access in MediaAccess.values)
          WidgetbookUseCase(
            name: switch (access) {
              MediaAccess.full => 'Android · full access',
              MediaAccess.limited => 'Android · selected photos only',
              MediaAccess.denied => 'Android · not granted',
              MediaAccess.permanentlyDenied => 'Android · blocked',
              MediaAccess.notApplicable => 'iOS',
            },
            builder: (context) => Showcase(
              maxWidth: 720,
              child: StorageOverview(
                snapshot: Fixtures.storage(access),
                onRequestAccess: logAction(context, 'onRequestAccess'),
                onOpenSettings: logAction(context, 'onOpenSettings'),
                onRefresh: logAction(context, 'onRefresh'),
              ),
            ),
          ),
        WidgetbookUseCase(
          name: 'Web (no capacity)',
          builder: (context) => Showcase(
            maxWidth: 720,
            child: StorageOverview(
              snapshot: Fixtures.storage(
                MediaAccess.notApplicable,
                capacity: false,
              ),
            ),
          ),
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'History',
      useCases: [
        WidgetbookUseCase(
          name: 'Activity tile',
          builder: (context) =>
              Showcase(child: ActivityTile(entry: Fixtures.activity().first)),
        ),
        WidgetbookUseCase(
          name: 'History page',
          builder: (context) => ProviderScope(
            overrides: [
              activityProvider.overrideWith(
                () => DemoActivityNotifier(Fixtures.activity()),
              ),
            ],
            child: const HistoryPage(),
          ),
        ),
        WidgetbookUseCase(
          name: 'History page · empty',
          builder: (context) => ProviderScope(
            overrides: [
              activityProvider.overrideWith(
                () => DemoActivityNotifier(const []),
              ),
            ],
            child: const HistoryPage(),
          ),
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Vault',
      useCases: [
        WidgetbookUseCase(
          name: 'Choose unlock method',
          builder: (context) => Showcase(
            maxWidth: 440,
            child: VaultSetupFlow(onComplete: logAction(context, 'onComplete')),
          ),
        ),
        WidgetbookUseCase(
          name: 'PIN field',
          builder: (context) => Showcase(
            maxWidth: 360,
            child: PasscodeField(
              kind: PasscodeKind.pin,
              label: 'PIN',
              errorText: context.knobs.boolean(label: 'Show error')
                  ? 'Incorrect. 2 attempts left before a short lockout.'
                  : null,
              onSubmitted: logValue<String>(context, 'onSubmitted'),
            ),
          ),
        ),
        WidgetbookUseCase(
          name: 'Password field',
          builder: (context) => Showcase(
            maxWidth: 360,
            child: PasscodeField(
              kind: PasscodeKind.password,
              label: 'Password',
              onSubmitted: logValue<String>(context, 'onSubmitted'),
            ),
          ),
        ),
      ],
    ),
  ],
);
