import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:wisepaise/providers/api_provider.dart';
import 'package:wisepaise/utils/expense_chart.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/dialog_utils.dart';
import 'login_page.dart';
import 'package:slide_to_act/slide_to_act.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  void _showThemeSheet(BuildContext context, SettingsProvider settings) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Choose Theme',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Divider(height: 1),
              ListTile(
                title: const Text('System'),
                trailing:
                    settings.themeMode == ThemeMode.system
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                onTap: () {
                  settings.setThemeMode(ThemeMode.system);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Light'),
                trailing:
                    settings.themeMode == ThemeMode.light
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                onTap: () {
                  settings.setThemeMode(ThemeMode.light);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Dark'),
                trailing:
                    settings.themeMode == ThemeMode.dark
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                onTap: () {
                  settings.setThemeMode(ThemeMode.dark);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    AuthProvider authProvider = Provider.of<AuthProvider>(
      context,
      listen: false,
    );
    ApiProvider api = Provider.of<ApiProvider>(context, listen: false);
    showModalBottomSheet(
      isDismissible: false,
      isScrollControlled: false,
      showDragHandle: true,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Icon(FontAwesomeIcons.triangleExclamation),
                      SizedBox(width: 10.0),
                      Text(
                        'Permanently Delete Account?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Divider(height: 1),
              SizedBox(height: 15.0),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'You are about to delete your account and all associated data.\n'
                  'This action is permanent and cannot be reversed.',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.5,
                    fontSize: 15.0,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 15.0,
                ),
                child: SlideAction(
                  borderRadius: 10.0,
                  text: 'Slide to Delete',
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                  outerColor: Colors.red,
                  innerColor: Colors.white,
                  sliderButtonIcon: const Icon(Icons.delete, color: Colors.red),
                  onSubmit: () async {
                    try {
                      Navigator.of(context).pop(true);
                      authProvider.signOut(context, source: 'delete');
                      await api.deleteUser(context, authProvider.user!.id);
                      if (context.mounted) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error signing out: ${e.toString()}'),
                          ),
                        );
                      }
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCurrencySheet(BuildContext context, SettingsProvider settings) {
    final List<MapEntry<String, String>> currencies = const [
      MapEntry('INR', 'INR ₹'),
      MapEntry('USD', 'USD \$'),
      MapEntry('AED', 'AED د.إ'),
      MapEntry('GBP', 'GBP £'),
      MapEntry('SAR', 'SAR ﷼'),
      MapEntry('SGD', 'SGD S\$'),
      MapEntry('HKD', 'HKD HK\$'),
      MapEntry('PKR', 'PKR ₨'),
      MapEntry('EUR', 'EUR €'),
      MapEntry('JPY', 'JPY ¥'),
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Choose Currency',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Divider(height: 1),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemBuilder: (ctx, index) {
                    final entry = currencies[index];
                    final isSelected = settings.currency == entry.key;
                    return ListTile(
                      title: Text(entry.value),
                      trailing:
                          isSelected
                              ? const Icon(Icons.check, color: Colors.green)
                              : null,
                      onTap: () {
                        settings.setCurrency(entry.key);
                        Navigator.pop(context);
                      },
                    );
                  },
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemCount: currencies.length,
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );
  }

  void _showReminderTimeSheet(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    // Parse existing time
    final parts = settings.reminderTime.split(":");
    TimeOfDay initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 9,
      minute: int.tryParse(parts[1]) ?? 0,
    );

    final picked = await showModalBottomSheet<TimeOfDay>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        TimeOfDay selectedTime = initial;

        return StatefulBuilder(
          builder: (context, setState) {
            return SafeArea(
              bottom: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TimePickerDialog(
                    initialEntryMode: TimePickerEntryMode.dial,
                    initialTime: selectedTime,
                    confirmText: 'Okay',
                    cancelText: 'Cancel',
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (picked != null) {
      final hh = picked.hour.toString().padLeft(2, '0');
      final mm = picked.minute.toString().padLeft(2, '0');
      settings.setReminderTime('$hh:$mm');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: Consumer3<AuthProvider, SettingsProvider, ApiProvider>(
        builder: (context, authProvider, settings, api, child) {
          return SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.max,
              children: [
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border:
                                  authProvider.user?.photoUrl == null
                                      ? Border.all(
                                        width: 0.15,
                                        color:
                                            Theme.of(context).brightness ==
                                                    Brightness.light
                                                ? Colors.black54
                                                : Colors.white54,
                                      )
                                      : null,
                              borderRadius: BorderRadius.circular(12.0),
                              image: DecorationImage(
                                image:
                                    authProvider.user?.photoUrl != null
                                        ? NetworkImage(
                                          authProvider.user!.photoUrl!,
                                        )
                                        : AssetImage(
                                          Theme.of(context).brightness ==
                                                  Brightness.light
                                              ? 'assets/logos/logo_light.png'
                                              : 'assets/logos/logo_dark.png',
                                        ),
                              ),
                            ),
                            height: 75.0,
                            width: 75.0,
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  authProvider.user?.displayName ?? 'User',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  softWrap: true,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  authProvider.user?.email ?? 'N/a',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                  softWrap: true,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 15.0),
                    // Report Section
                    Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10.0),
                        child: ExpenseChartCard(
                          dataList: api.userExpenseList,
                          currency: settings.currency,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ⚙️ Settings Section
                    Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.color_lens),
                            title: const Text("Theme"),
                            trailing: GestureDetector(
                              onTap: () => _showThemeSheet(context, settings),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12.0),
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.surfaceVariant,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.style, size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      settings.themeMode.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            onTap: () => _showThemeSheet(context, settings),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.currency_exchange),
                            title: const Text("Currency"),
                            trailing: GestureDetector(
                              onTap:
                                  () => _showCurrencySheet(context, settings),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12.0),
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.surfaceVariant,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.payments, size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      settings.currency,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            onTap: () => _showCurrencySheet(context, settings),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.notifications_active),
                            title: const Text("Reminder Time"),
                            trailing: GestureDetector(
                              onTap:
                                  () =>
                                      _showReminderTimeSheet(context, settings),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12.0),
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.surfaceVariant,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.access_time, size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      settings.reminderTime,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            onTap:
                                () => _showReminderTimeSheet(context, settings),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [SizedBox(height: 20.0),
                    SizedBox(
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: ElevatedButton.icon(
                          onPressed:
                              () => DialogUtils.showGenericDialog(
                            title: DialogUtils.titleText('Sign Out?'),
                            message: const Text(
                              'Do you want to Signout?',
                              style: TextStyle(
                                fontSize: 15.0,
                                letterSpacing: 1.5,
                              ),
                              textAlign: TextAlign.left,
                            ),
                            confirmText: 'Sign out',
                            cancelText: 'Cancel',
                            confirmColor: Colors.green,
                            showCancel: true,
                            onConfirm: () {
                              try {
                                Navigator.of(context).pop(true);
                                authProvider.signOut(context);
                                if (context.mounted) {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (context) => const LoginPage(),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Error signing out: ${e.toString()}',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            onCancel: () => Navigator.of(context).pop(),
                            context: context,
                          ),
                          icon: const Icon(Icons.logout),
                          label: const Text('Sign Out'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 24,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 15.0,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 5.0),
                    SizedBox(
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: ElevatedButton.icon(
                          onPressed:
                              () => DialogUtils.showGenericDialog(
                            title: DialogUtils.titleText('Delete Account'),
                            message: const Text(
                              'User data will be deleted!!!\nDo you want to Delete your account?',
                              style: TextStyle(
                                fontSize: 15.0,
                                letterSpacing: 1.5,
                              ),
                              textAlign: TextAlign.left,
                            ),
                            confirmText: 'Cancel',
                            cancelText: 'Delete',
                            confirmColor: Colors.red,
                            showCancel: true,
                            onCancel: () {
                              Navigator.of(context).pop();
                              _showDeleteConfirmation(context);
                            },
                            onConfirm: () => Navigator.of(context).pop(),
                            context: context,
                          ),
                          icon: const Icon(FontAwesomeIcons.trashCan),
                          label: const Text('Delete Account'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 24,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 15.0,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),],
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
