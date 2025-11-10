import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:wisepaise/models/type_model.dart';
import 'package:wisepaise/providers/api_provider.dart';
import 'package:wisepaise/providers/notification_provider.dart';
import 'package:wisepaise/providers/settings_provider.dart';
import 'package:wisepaise/screen/all_expense_page.dart';
import 'package:wisepaise/screen/all_savings_goals_page.dart';
import 'package:wisepaise/screen/expense_group_details_page.dart';
import 'package:wisepaise/screen/create_reminder_page.dart';
import 'package:wisepaise/screen/savings_goal_details_page.dart';
import 'package:wisepaise/utils/dialog_utils.dart';
import 'package:wisepaise/utils/utils.dart';

import '../models/savings_goal_transaction.dart';
import '../models/reminder_model.dart';
import '../providers/auth_provider.dart';
import '../utils/toast.dart';
import 'all_group_page.dart';
import 'all_reminder_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;
  bool isInitComplete = false;

  @override
  void initState() {
    super.initState();
    init();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  init() async {
    await Future.microtask(() async {
      ApiProvider api = Provider.of<ApiProvider>(context, listen: false);
      setState(() => isInitComplete = true);
      api.setLoading();
      AuthProvider auth = Provider.of<AuthProvider>(context, listen: false);
      SettingsProvider set = Provider.of<SettingsProvider>(
        context,
        listen: false,
      );
      NotificationProvider notification = Provider.of<NotificationProvider>(
        context,
        listen: false,
      );

      try {
        await api.getGroups(auth.user!.id, context);
        if (!api.isTimedOut) {
          await api.getReminders(auth.user!.id, context);
          await api.getUserExpenses(auth.user!.id, context);
          await api.getUserGoals(auth.user!.id, context);
          await api.getGoogleUsers(context);
        }
      } catch (e) {
        debugPrint("Error in API: $e");
      }

      debugPrint('getActiveButExpired:::${getActiveButExpired(api).length}');
      if (getActiveButExpired(api).isNotEmpty &&
          set.getExpiredReminderAlert()) {
        set.setExpiredReminderAlert();
        DialogUtils.showGenericDialog(
          context: context,
          title: DialogUtils.titleText('Expired Reminders'),
          message: Text(
            'You have Expired Reminders. Do you want to View all reminders?',
          ),
          onCancel: () => Navigator.pop(context),
          cancelText: 'Cancel',
          confirmColor: Colors.green,
          confirmText: 'View all',
          showCancel: true,
          onConfirm: () {
            Navigator.pop(context);
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (context) => AllReminderPage()));
          },
        );
      }
    });

    /*await notification.scheduleNotification(seconds: 30);
    Toasts.show(
      context,
      "Notification scheduled at ${DateTime.now().add(const Duration(seconds: 20))}",
      type: ToastType.info,
    );*/
  }

  List<Map<String, dynamic>> getActiveButExpired(ApiProvider api) {
    return api.expenseReminderList.where((rem) {
      return DateTime.parse(rem['reminderDate']).isBefore(DateTime.now()) &&
          rem['reminderIsActive'] == true;
    }).toList();
  }

  Map<String, dynamic>? _selectedReminder;
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    AuthProvider auth = Provider.of<AuthProvider>(context, listen: false);
    return Consumer2<ApiProvider, SettingsProvider>(
      builder: (_, api, set, __) {
        List top5Groups = List.from(api.groupList)..sort((a, b) {
          final dateA = DateTime.parse(a['exGroupCreatedOn']);
          final dateB = DateTime.parse(b['exGroupCreatedOn']);
          return dateB.compareTo(dateA);
        });

        top5Groups = top5Groups.take(5).toList();

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar:
              api.groupList.isEmpty &&
                      api.expenseReminderList.isEmpty &&
                      api.userExpenseList.isEmpty &&
                      api.savingsGoalList.isEmpty
                  ? null
                  : AppBar(
                    backgroundColor: theme.scaffoldBackgroundColor,
                    centerTitle: true,
                    elevation: 0.5,
                    title: Image.asset(
                      Theme.of(context).brightness == Brightness.light
                          ? 'assets/logos/logo_light.png'
                          : 'assets/logos/logo_dark.png',
                      fit: BoxFit.contain,
                      height: 50.0,
                    ),
                  ),
          body:
              !isInitComplete || api.isAPILoading
                  ? buildDashboardShimmer(context)
                  : api.isTimedOut
                  ? Container(
                    padding: EdgeInsets.all(35.0),
                    child: Center(
                      child: Card(
                        elevation: 2.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Container(
                          padding: EdgeInsets.all(15.0),
                          height: 150.0,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            // color: Colors.white,
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Column(
                            children: [
                              Spacer(),
                              Icon(FontAwesomeIcons.triangleExclamation),
                              SizedBox(height: 5.0),
                              Text(
                                'Request Timed Out!',
                                style: TextStyle(
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Spacer(),
                              ElevatedButton.icon(
                                onPressed: () => init(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).brightness ==
                                              Brightness.light
                                          ? Colors.blue
                                          : Colors.blue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                ),
                                icon: Icon(
                                  FontAwesomeIcons.arrowsRotate,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  'Retry?',
                                  style: TextStyle(
                                    color: Colors.white,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                  : api.groupList.isEmpty &&
                      api.expenseReminderList.isEmpty &&
                      api.userExpenseList.isEmpty &&
                      api.savingsGoalList.isEmpty
                  ? Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors:
                            Theme.of(context).brightness == Brightness.dark
                                ? [
                                  const Color(0xFF0F2027),
                                  const Color(0xFF203A43),
                                  const Color(0xFF2C5364),
                                ]
                                : [
                                  const Color(0xFFE8F0F9),
                                  const Color(0xFFD0E1F4),
                                  const Color(0xFFB8D7F1),
                                ],
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 15.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, ${auth.user!.displayName}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.start,
                          overflow: TextOverflow.ellipsis,
                          softWrap: true,
                          maxLines: 1,
                        ),
                        GridView.count(
                          physics: NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          crossAxisSpacing: 15.0,
                          mainAxisSpacing: 15.0,
                          crossAxisCount: 2,
                          children: [
                            buildCreateGroup(context),
                            buildCreateReminder(context, api),
                            buildCreateGoal(context),
                            buildCreateExpense(context),
                          ],
                        ),
                      ],
                    ),
                  )
                  : RefreshIndicator(
                    onRefresh: () async {
                      await init();
                    },
                    child: Stack(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                            left: 10.0,
                            /*right: 10.0,*/
                            bottom: 10.0,
                          ),
                          child: ListView(
                            physics: AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5.0,
                                  vertical: 5.0,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Expense Reminders",
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    if (api.expenseReminderList.isNotEmpty)
                                      ElevatedButton.icon(
                                        onPressed:
                                            api.expenseReminderList.isEmpty
                                                ? null
                                                : () async {
                                                  await Navigator.of(
                                                    context,
                                                  ).push(
                                                    MaterialPageRoute(
                                                      builder:
                                                          (context) =>
                                                              AllReminderPage(),
                                                    ),
                                                  );
                                                  // Rebuild after coming back
                                                  setState(() {});
                                                },

                                        style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12.0,
                                            ),
                                          ),
                                          elevation: 0.0,
                                          animationDuration: Duration(
                                            milliseconds: 500,
                                          ),
                                        ),
                                        label: Text(
                                          'View all',
                                          style: TextStyle(letterSpacing: 1.5),
                                        ),
                                        icon: Icon(Icons.arrow_forward),
                                      ),
                                  ],
                                ),
                              ),
                              getActiveReminders(api).isEmpty
                                  ? buildCreateReminder(context, api)
                                  : SizedBox(
                                    height: 165,
                                    child: ListView.separated(
                                      physics: BouncingScrollPhysics(),
                                      scrollDirection: Axis.horizontal,
                                      itemCount: getActiveReminders(api).length,
                                      separatorBuilder:
                                          (context, index) =>
                                              const SizedBox(width: 12),
                                      itemBuilder: (context, index) {
                                        final reminder =
                                            getActiveReminders(api)[index];

                                        return GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _selectedReminder = reminder;
                                              isExpanded = true;
                                            });
                                          },
                                          child: buildReminderCard(reminder),
                                        );
                                      },
                                    ),
                                  ),
                              const SizedBox(height: 15.0),

                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 5.0,
                                  horizontal: 5.0,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Savings Goals",
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    if (api.savingsGoalList.isNotEmpty)
                                      ElevatedButton.icon(
                                        onPressed:
                                            () => Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder:
                                                    (context) =>
                                                        AllSavingsGoalsPage(),
                                              ),
                                            ),
                                        style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12.0,
                                            ),
                                          ),
                                          elevation: 0.0,
                                          animationDuration: const Duration(
                                            milliseconds: 500,
                                          ),
                                        ),
                                        label: const Text('View all'),
                                        icon: const Icon(Icons.arrow_forward),
                                      ),
                                  ],
                                ),
                              ),
                              (api.savingsGoalList.isEmpty)
                                  ? Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Center(
                                      child: buildCreateGoal(context),
                                    ),
                                  )
                                  : SizedBox(
                                    height: 160,
                                    child: ListView.separated(
                                      physics: const BouncingScrollPhysics(),
                                      scrollDirection: Axis.horizontal,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5.0,
                                      ),
                                      itemCount: api.savingsGoalList.length,
                                      separatorBuilder:
                                          (_, __) => const SizedBox(width: 12),
                                      itemBuilder: (context, index) {
                                        Map<String, dynamic> goal =
                                            api.savingsGoalList[index];
                                        return _buildSavingsGoalCard(
                                          context,
                                          goal,
                                        );
                                      },
                                    ),
                                  ),

                              const SizedBox(height: 10.0),

                              // 🔹 Expense Groups Section
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 5.0,
                                  horizontal: 5.0,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,

                                  children: [
                                    Text(
                                      "Expense Groups",
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),

                                    if (api.groupList.isNotEmpty)
                                      ElevatedButton.icon(
                                        onPressed: () async {
                                          await Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder:
                                                  (context) => AllGroupPage(),
                                            ),
                                          );
                                          // Rebuild after coming back
                                          setState(() {});
                                        },

                                        style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12.0,
                                            ),
                                          ),
                                          elevation: 0.0,
                                          animationDuration: Duration(
                                            milliseconds: 500,
                                          ),
                                        ),
                                        label: Text(
                                          'View all',
                                          style: TextStyle(letterSpacing: 1.5),
                                        ),
                                        icon: Icon(Icons.arrow_forward),
                                      ),
                                  ],
                                ),
                              ),
                              if (api.groupList.isEmpty)
                                buildCreateGroup(context)
                              else
                                top5Groups.length <= 2
                                    ? SizedBox(
                                      height: 85.0,
                                      width: 140,
                                      child: ListView.builder(
                                        physics: BouncingScrollPhysics(),
                                        scrollDirection: Axis.horizontal,
                                        shrinkWrap: false,
                                        itemCount: top5Groups.length,
                                        itemBuilder: (context, index) {
                                          Map<String, dynamic> thisGroup =
                                              api.groupList[index];
                                          return Hero(
                                            tag:
                                                'groupCard_${thisGroup['exGroupId']}',
                                            child: SizedBox(
                                              width: 300.0,
                                              child: Card(
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: InkWell(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        12.0,
                                                      ),
                                                  splashColor: theme
                                                      .colorScheme
                                                      .primary
                                                      .withOpacity(0.15),
                                                  highlightColor: theme
                                                      .colorScheme
                                                      .primary
                                                      .withOpacity(0.08),
                                                  onTap: () {
                                                    Navigator.of(context).push(
                                                      MaterialPageRoute(
                                                        builder:
                                                            (context) =>
                                                                ExpenseGroupDetailsPage(
                                                                  groupMap:
                                                                      thisGroup,
                                                                ),
                                                      ),
                                                    );
                                                  },
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          10.0,
                                                        ),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Expanded(
                                                          child: Row(
                                                            children: [
                                                              Container(
                                                                height: 50.0,
                                                                width: 50.0,
                                                                decoration: BoxDecoration(
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        12.0,
                                                                      ),
                                                                ),
                                                                child:
                                                                    (thisGroup['exGroupImageURL'] !=
                                                                                null &&
                                                                            thisGroup['exGroupImageURL'].toString().trim().isNotEmpty)
                                                                        ? ClipRRect(
                                                                          borderRadius: BorderRadius.circular(
                                                                            12.0,
                                                                          ),
                                                                          child: Image.network(
                                                                            thisGroup['exGroupImageURL'],
                                                                            fit:
                                                                                BoxFit.cover,
                                                                            loadingBuilder: (
                                                                              context,
                                                                              child,
                                                                              loadingProgress,
                                                                            ) {
                                                                              if (loadingProgress ==
                                                                                  null) {
                                                                                return child; // Image loaded
                                                                              }
                                                                              return SizedBox(
                                                                                width:
                                                                                    50,
                                                                                height:
                                                                                    50,
                                                                                child: const Center(
                                                                                  child:
                                                                                      CupertinoActivityIndicator(),
                                                                                ),
                                                                              );
                                                                            },
                                                                            errorBuilder:
                                                                                (
                                                                                  context,
                                                                                  _,
                                                                                  __,
                                                                                ) => Image.asset(
                                                                                  Theme.of(
                                                                                            context,
                                                                                          ).brightness ==
                                                                                          Brightness.light
                                                                                      ? 'assets/logos/logo_light.png'
                                                                                      : 'assets/logos/logo_dark.png',
                                                                                  fit:
                                                                                      BoxFit.contain,
                                                                                ),
                                                                          ),
                                                                        )
                                                                        : Image.asset(
                                                                          Theme.of(
                                                                                    context,
                                                                                  ).brightness ==
                                                                                  Brightness.light
                                                                              ? 'assets/logos/logo_light.png'
                                                                              : 'assets/logos/logo_dark.png',
                                                                          fit:
                                                                              BoxFit.contain,
                                                                        ),
                                                              ),
                                                              const SizedBox(
                                                                width: 10.0,
                                                              ),
                                                              Expanded(
                                                                child: Column(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    Text(
                                                                      '${thisGroup['exGroupName']}',
                                                                      style: theme
                                                                          .textTheme
                                                                          .titleMedium
                                                                          ?.copyWith(
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                          ),
                                                                      softWrap:
                                                                          true,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                      maxLines:
                                                                          1,
                                                                    ),
                                                                    Row(
                                                                      children: [
                                                                        Icon(
                                                                          typeList
                                                                              .elementAt(
                                                                                int.parse(
                                                                                  thisGroup['exGroupType'],
                                                                                ),
                                                                              )
                                                                              .icon,
                                                                          size:
                                                                              17.5,
                                                                          color: theme
                                                                              .colorScheme
                                                                              .onSurface
                                                                              .withOpacity(
                                                                                0.7,
                                                                              ),
                                                                        ),
                                                                        const SizedBox(
                                                                          width:
                                                                              2.5,
                                                                        ),
                                                                        Expanded(
                                                                          child: Text(
                                                                            typeList
                                                                                .elementAt(
                                                                                  int.parse(
                                                                                    thisGroup['exGroupType'],
                                                                                  ),
                                                                                )
                                                                                .name,
                                                                            maxLines:
                                                                                1,
                                                                            overflow:
                                                                                TextOverflow.ellipsis,
                                                                            style: theme.textTheme.labelSmall?.copyWith(
                                                                              color: theme.colorScheme.onSurface.withOpacity(
                                                                                0.7,
                                                                              ),
                                                                              fontWeight:
                                                                                  FontWeight.bold,
                                                                              letterSpacing:
                                                                                  1.2,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 12,
                                                        ),
                                                        Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                const Icon(
                                                                  Icons
                                                                      .arrow_upward,
                                                                  color:
                                                                      Colors
                                                                          .green,
                                                                  size: 20,
                                                                ),
                                                                const SizedBox(
                                                                  width: 2,
                                                                ),
                                                                Text(
                                                                  formatCurrency(
                                                                    thisGroup['exGroupIncome'],
                                                                    context,
                                                                  ),
                                                                  style: theme
                                                                      .textTheme
                                                                      .titleSmall
                                                                      ?.copyWith(
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        color:
                                                                            Colors.green,
                                                                      ),
                                                                ),
                                                              ],
                                                            ),
                                                            const SizedBox(
                                                              height: 5,
                                                            ),
                                                            Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                const Icon(
                                                                  Icons
                                                                      .arrow_downward,
                                                                  color:
                                                                      Colors
                                                                          .red,
                                                                  size: 20,
                                                                ),
                                                                const SizedBox(
                                                                  width: 2,
                                                                ),
                                                                Text(
                                                                  formatCurrency(
                                                                    thisGroup['exGroupExpenses'],
                                                                    context,
                                                                  ),
                                                                  style: theme
                                                                      .textTheme
                                                                      .titleSmall
                                                                      ?.copyWith(
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        color:
                                                                            Colors.red,
                                                                      ),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    )
                                    : SizedBox(
                                      height: 175.0,
                                      child: GridView.builder(
                                        physics: BouncingScrollPhysics(),
                                        scrollDirection: Axis.horizontal,
                                        itemCount: top5Groups.length,
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 2, // 2 rows
                                              mainAxisSpacing:
                                                  8.0, // spacing between columns
                                              crossAxisSpacing:
                                                  8.0, // spacing between rows
                                              mainAxisExtent: 300,
                                            ),
                                        itemBuilder: (context, index) {
                                          Map<String, dynamic> thisGroup =
                                              api.groupList[index];
                                          return Hero(
                                            tag:
                                                'groupCard_${thisGroup['exGroupId']}',
                                            child: Card(
                                              elevation: 1,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: InkWell(
                                                borderRadius:
                                                    BorderRadius.circular(12.0),
                                                splashColor: theme
                                                    .colorScheme
                                                    .primary
                                                    .withOpacity(0.15),
                                                highlightColor: theme
                                                    .colorScheme
                                                    .primary
                                                    .withOpacity(0.08),
                                                onTap: () {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder:
                                                          (context) =>
                                                              ExpenseGroupDetailsPage(
                                                                groupMap:
                                                                    thisGroup,
                                                              ),
                                                    ),
                                                  );
                                                },
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                    10.0,
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        child: Row(
                                                          children: [
                                                            Container(
                                                              height: 75.0,
                                                              width: 75.0,
                                                              decoration:
                                                                  BoxDecoration(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          12.0,
                                                                        ),
                                                                  ),
                                                              child:
                                                                  (thisGroup['exGroupImageURL'] !=
                                                                              null &&
                                                                          thisGroup['exGroupImageURL']
                                                                              .toString()
                                                                              .trim()
                                                                              .isNotEmpty)
                                                                      ? ClipRRect(
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                              12.0,
                                                                            ),
                                                                        child: Image.network(
                                                                          thisGroup['exGroupImageURL'],
                                                                          fit:
                                                                              BoxFit.cover,
                                                                          loadingBuilder: (
                                                                            context,
                                                                            child,
                                                                            loadingProgress,
                                                                          ) {
                                                                            if (loadingProgress ==
                                                                                null) {
                                                                              return child; // Image loaded
                                                                            }
                                                                            return const Center(
                                                                              child:
                                                                                  CupertinoActivityIndicator(),
                                                                            );
                                                                          },
                                                                          errorBuilder:
                                                                              (
                                                                                context,
                                                                                _,
                                                                                __,
                                                                              ) => Image.asset(
                                                                                Theme.of(
                                                                                          context,
                                                                                        ).brightness ==
                                                                                        Brightness.light
                                                                                    ? 'assets/logos/logo_light.png'
                                                                                    : 'assets/logos/logo_dark.png',
                                                                                fit:
                                                                                    BoxFit.contain,
                                                                              ),
                                                                        ),
                                                                      )
                                                                      : Image.asset(
                                                                        Theme.of(
                                                                                  context,
                                                                                ).brightness ==
                                                                                Brightness.light
                                                                            ? 'assets/logos/logo_light.png'
                                                                            : 'assets/logos/logo_dark.png',
                                                                        fit:
                                                                            BoxFit.contain,
                                                                      ),
                                                            ),
                                                            const SizedBox(
                                                              width: 10.0,
                                                            ),
                                                            Expanded(
                                                              child: Column(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .center,
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Text(
                                                                    '${thisGroup['exGroupName']}',
                                                                    style: theme
                                                                        .textTheme
                                                                        .titleMedium
                                                                        ?.copyWith(
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                        ),
                                                                    softWrap:
                                                                        true,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                    maxLines: 1,
                                                                  ),
                                                                  Row(
                                                                    children: [
                                                                      Icon(
                                                                        typeList
                                                                            .elementAt(
                                                                              int.parse(
                                                                                thisGroup['exGroupType'],
                                                                              ),
                                                                            )
                                                                            .icon,
                                                                        size:
                                                                            17.5,
                                                                        color: theme
                                                                            .colorScheme
                                                                            .onSurface
                                                                            .withOpacity(
                                                                              0.7,
                                                                            ),
                                                                      ),
                                                                      const SizedBox(
                                                                        width:
                                                                            2.5,
                                                                      ),
                                                                      Expanded(
                                                                        child: Text(
                                                                          typeList
                                                                              .elementAt(
                                                                                int.parse(
                                                                                  thisGroup['exGroupType'],
                                                                                ),
                                                                              )
                                                                              .name,
                                                                          maxLines:
                                                                              1,
                                                                          overflow:
                                                                              TextOverflow.ellipsis,
                                                                          style: theme.textTheme.labelSmall?.copyWith(
                                                                            color: theme.colorScheme.onSurface.withOpacity(
                                                                              0.7,
                                                                            ),
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                            letterSpacing:
                                                                                1.2,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .end,
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              const Icon(
                                                                Icons
                                                                    .arrow_upward,
                                                                color:
                                                                    Colors
                                                                        .green,
                                                                size: 20,
                                                              ),
                                                              const SizedBox(
                                                                width: 2,
                                                              ),
                                                              Text(
                                                                formatCurrency(
                                                                  thisGroup['exGroupIncome'],
                                                                  context,
                                                                ),
                                                                style: theme
                                                                    .textTheme
                                                                    .titleSmall
                                                                    ?.copyWith(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(
                                                            height: 5,
                                                          ),
                                                          Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              const Icon(
                                                                Icons
                                                                    .arrow_downward,
                                                                color:
                                                                    Colors.red,
                                                                size: 20,
                                                              ),
                                                              const SizedBox(
                                                                width: 2,
                                                              ),
                                                              Text(
                                                                formatCurrency(
                                                                  thisGroup['exGroupExpenses'],
                                                                  context,
                                                                ),
                                                                style: theme
                                                                    .textTheme
                                                                    .titleSmall
                                                                    ?.copyWith(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),

                              if (api.userExpenseList.isNotEmpty)
                                const SizedBox(height: 10.0),
                              // 🔹 Savings Goals Overview (dummy)
                              if (api.userExpenseList.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    //horizontal: 5.0,
                                    vertical: 5.0,
                                  ),
                                  child: _buildSavingsOverviewCard(context),
                                ),
                              // 🔹 Expenses Section
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 5.0,
                                  bottom: 10.0,
                                  left: 5.0,
                                  right: 5.0,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Expenses",
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    if (api.userExpenseList.isNotEmpty)
                                      ElevatedButton.icon(
                                        onPressed:
                                            api.userExpenseList.isEmpty
                                                ? null
                                                : () => Navigator.of(
                                                  context,
                                                ).push(
                                                  MaterialPageRoute(
                                                    builder:
                                                        (context) =>
                                                            AllExpensePage(),
                                                  ),
                                                ),
                                        style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12.0,
                                            ),
                                          ),
                                          elevation: 0.0,
                                          animationDuration: Duration(
                                            milliseconds: 500,
                                          ),
                                        ),
                                        label: Text(
                                          'View all',
                                          style: TextStyle(letterSpacing: 1.5),
                                        ),
                                        icon: Icon(Icons.arrow_forward),
                                      ),
                                  ],
                                ),
                              ),
                              if (api.userExpenseList.isEmpty)
                                buildCreateExpense(context)
                              else
                                ...buildGroupedExpenseWidgets(
                                  api.userExpenseList,
                                  context,
                                ),
                            ],
                          ),
                        ),
                        if (_selectedReminder != null)
                          _buildExpandedReminderOverlay(context),
                      ],
                    ),
                  ),
        );
      },
    );
  }

  Widget buildReminderCard(Map<String, dynamic> reminder) {
    bool isExpired = DateTime.parse(
      reminder['reminderDate'],
    ).isBefore(DateTime.now());

    final String title = (reminder['reminderName'] ?? '').toString();
    final String description =
        (reminder['reminderDescription'] ?? '').toString();
    final String date = (reminder['reminderDate'] ?? '').toString();
    final String amount = (reminder['reminderAmount'] ?? '0').toString();
    final String amountType =
        (reminder['reminderAmountType'] ?? 'expense').toString();
    final bool isRecurring =
        reminder['reminderIsRecurring'] == true ||
        reminder['reminderIsRecurring'] == 1;
    final bool isActive =
        reminder['reminderIsActive'] == true ||
        reminder['reminderIsActive'] == 1;

    final bool isExpense = amountType.toLowerCase() == 'expense';
    final Color accent = isExpense ? Colors.red : Colors.green;

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          width: 300,
          margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 2.5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (isExpired ? Colors.red : Colors.green).withOpacity(
                  _glowAnimation.value,
                ),
                blurRadius: 5,
                spreadRadius: .25,
              ),
            ],
          ),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
                gradient: LinearGradient(
                  colors:
                      Theme.of(context).brightness == Brightness.dark
                          ? [const Color(0xFF232526), const Color(0xFF414345)]
                          : [const Color(0xFF2193b0), const Color(0xFF6dd5ed)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          FontAwesomeIcons.userClock,
                          color: accent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title.isEmpty ? 'Untitled Reminder' : title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: true,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  isExpense
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
                                  size: 14,
                                  color:
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? isExpense
                                              ? Colors.red
                                              : Colors.green
                                          : isExpense
                                          ? Colors.red.shade200
                                          : Colors.green.shade200,
                                ),
                                Expanded(
                                  child: Text(
                                    formatCurrency(
                                      double.tryParse(amount) ?? 0,
                                      context,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: true,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? isExpense
                                                  ? Colors.red
                                                  : Colors.green
                                              : isExpense
                                              ? Colors.red.shade200
                                              : Colors.green.shade200,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10.0,
                          vertical: 5.5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.event, size: 14, color: accent),
                            const SizedBox(width: 4),
                            Text(
                              date,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade900,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (description.isNotEmpty)
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.95),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _buildTag(
                            isRecurring
                                ? Icons.repeat
                                : Icons.remove_red_eye_outlined,
                            isRecurring ? 'Recurring' : 'One-time',
                          ),
                          const SizedBox(width: 6),
                          _buildTag(
                            isActive
                                ? Icons.check_circle_outline
                                : Icons.update_disabled,
                            isActive ? 'Active' : 'Disabled',
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10.0,
                          vertical: 5.5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isExpense ? Icons.remove : Icons.add,
                              size: 14,
                              color: accent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isExpense ? 'Expense' : 'Income',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade900,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.5),
      decoration: BoxDecoration(
        color:
            Theme.of(context).brightness == Brightness.light
                ? Colors.black54
                : Colors.white10,
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ===== Dummy Savings UI =====
  Widget _buildSavingsOverviewCard(BuildContext context) {
    final theme = Theme.of(context);
    final Color primary =
        theme.brightness == Brightness.light
            ? const Color(0xFF0D47A1)
            : theme.colorScheme.primary;
    final now = DateTime.now();
    ApiProvider api = Provider.of<ApiProvider>(context, listen: false);
    final monthly = api.userExpenseList.where((e) {
      final d = DateTime.tryParse(e['expenseDate'] ?? '') ?? DateTime(2000);
      return d.year == now.year && d.month == now.month;
    });

    final income = monthly
        .where(
          (e) =>
              (e['expenseSpendType']?.toString().toLowerCase() ?? '') ==
              'income',
        )
        .fold<double>(
          0,
          (s, e) => s + (e['expenseAmount'] as num?)!.toDouble() ?? 0,
        );

    final expenses = monthly
        .where(
          (e) =>
              (e['expenseSpendType']?.toString().toLowerCase() ?? '') ==
              'expense',
        )
        .fold<double>(
          0,
          (s, e) => s + (e['expenseAmount'] as num?)!.toDouble() ?? 0,
        );

    final savings = (income - expenses).clamp(0, double.infinity);
    double savingsPct =
        (income == 0 ? 0 : savings / income).clamp(0.0, 1.0).toDouble();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Overview',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildStatTile(
                    context,
                    label: 'Income',
                    value: formatCurrency(income, context),
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatTile(
                    context,
                    label: 'Expenses',
                    value: formatCurrency(expenses, context),
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatTile(
                    context,
                    label: 'Savings',
                    value: formatCurrency(savings, context),
                    color: primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: savingsPct,
                minHeight: 8,
                color: primary,
                backgroundColor: theme.colorScheme.onSurface.withOpacity(0.08),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${(savingsPct * 100).toStringAsFixed(0)}% of income saved',
              style: theme.textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelSmall),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsGoalCard(
    BuildContext context,
    Map<String, dynamic> goal,
  ) {
    final theme = Theme.of(context);
    final Color primary =
        theme.brightness == Brightness.light
            ? const Color(0xFF0D47A1)
            : theme.colorScheme.primary;
    final double target = (goal['savingsGoalTargetAmount'] as double);
    final double saved = (goal['savingsGoalCurrentAmount'] as double);
    final double pct = (saved / (target == 0 ? 1 : target)).clamp(0, 1);

    return SizedBox(
      width: 250,

      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SavingsGoalDetailsPage(goal: goal),
            ),
          );
        },
        child: Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    goal['savingsGoalImageUrl'].isEmpty
                        ? Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            // color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: primary.withOpacity(0.15),
                            ),
                          ),
                          child: Icon(Icons.savings_outlined),
                        )
                        : SizedBox(
                          width: 45,
                          height: 45,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12.0),
                            child: Image.network(
                              goal['savingsGoalImageUrl'],
                              fit: BoxFit.cover,
                              loadingBuilder: (
                                context,
                                child,
                                loadingProgress,
                              ) {
                                if (loadingProgress == null) {
                                  return child; // Image loaded
                                }
                                return SizedBox(
                                  width: 50,
                                  height: 50,
                                  child: const Center(
                                    child: CupertinoActivityIndicator(),
                                  ),
                                );
                              },
                              errorBuilder:
                                  (context, _, __) => Image.asset(
                                    Theme.of(context).brightness ==
                                            Brightness.light
                                        ? 'assets/logos/logo_light.png'
                                        : 'assets/logos/logo_dark.png',
                                    fit: BoxFit.contain,
                                  ),
                            ),
                          ),
                        ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal['savingsGoalName'].toString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Target: ${formatCurrency(target, context)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    color: primary,
                    backgroundColor: theme.colorScheme.onSurface.withOpacity(
                      0.08,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Saved: ${formatCurrency(saved, context)}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      goal['savingsGoalTargetDate'].toString(),
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showTopUpDialog(context, goal),
                        icon: const Icon(Icons.add),
                        label: const Text('Top up'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          side: BorderSide(color: primary.withOpacity(0.25)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedReminderOverlay(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isExpanded = false;
          _selectedReminder = null;
        });
      },
      child: AnimatedOpacity(
        opacity: isExpanded ? 1 : 0,
        duration: const Duration(milliseconds: 300),
        child: Stack(
          children: [
            // Blur background
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(color: Colors.black.withOpacity(0.3)),
              ),
            ),
            // Centered expanded card
            Center(
              child: AnimatedScale(
                duration: const Duration(milliseconds: 500),
                scale: isExpanded ? 1.0 : 0.8,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: MediaQuery.of(context).size.height / 6,
                  child: buildReminderCard(_selectedReminder!),
                ),
              ),
            ),
            Positioned(
              bottom: MediaQuery.of(context).size.height / 4,
              left: MediaQuery.of(context).size.width / 6.5,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 3,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        debugPrint(_selectedReminder.toString());
                        await Navigator.of(context)
                            .push(
                              MaterialPageRoute(
                                builder:
                                    (context) => CreateReminderPage(
                                      reminder: ReminderModel.fromJson(
                                        _selectedReminder!,
                                      ),
                                    ),
                              ),
                            )
                            .then((_) {
                              setState(() {
                                isExpanded = false;
                                _selectedReminder = null;
                              });
                            });
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      label: Text('Edit'),
                      icon: Icon(Icons.edit),
                    ),
                  ),
                  SizedBox(width: 15.0),
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 3,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        ApiProvider api = Provider.of<ApiProvider>(
                          context,
                          listen: false,
                        );
                        _selectedReminder!['reminderIsActive'] = false;
                        await api
                            .updateReminder(context, _selectedReminder!)
                            .then((Response resp) {
                              debugPrint(resp.statusCode.toString());

                              if (resp.statusCode == 200) {
                                debugPrint('resp.data:::${resp.data}');

                                api.expenseReminderList.removeWhere(
                                  (element) =>
                                      element['reminderId'] ==
                                      _selectedReminder!['reminderId'],
                                );
                                api.expenseReminderList.add(resp.data);
                                api.updateRemindersList(
                                  api.expenseReminderList,
                                );
                                setState(() {
                                  getActiveReminders(api).removeWhere(
                                    (element) =>
                                        element['reminderId'] ==
                                        _selectedReminder!['reminderId'],
                                  );
                                });

                                Toasts.show(
                                  context,
                                  'Reminder marked complete',
                                  type: ToastType.success,
                                );
                                setState(() {
                                  isExpanded = false;
                                  _selectedReminder = null;
                                });
                              }
                            });
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      label: Text('Complete'),
                      icon: Icon(Icons.check),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTopUpDialog(BuildContext context, Map<String, dynamic> goal) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    final nameController = TextEditingController();
    final amountController = TextEditingController();

    bool showError = false;

    // Will hold the setState from StatefulBuilder so onConfirm can call it.
    void Function(void Function())? dialogSetState;

    // showGenericDialog usually returns a Future; dispose controllers after dialog closes.
    DialogUtils.showGenericDialog(
      context: context,
      title: DialogUtils.titleText('Top-up'),
      message: StatefulBuilder(
        builder: (context, setState) {
          // capture the setState reference for use in onConfirm
          dialogSetState = setState;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 5.0),
              TextField(
                controller: nameController,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelText: 'Title',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 20.0),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelText: 'Amount',
                  hintText: settings.currency,
                ),
              ),
              if (showError)
                const Padding(
                  padding: EdgeInsets.only(top: 10.0),
                  child: Text(
                    'Please fill all values',
                    textAlign: TextAlign.left,
                    style: TextStyle(color: Colors.red, letterSpacing: 1.2),
                  ),
                ),
            ],
          );
        },
      ),
      onConfirm: () async {
        final hasError =
            nameController.text.isEmpty || amountController.text.isEmpty;

        if (hasError) {
          dialogSetState?.call(() {
            showError = true;
          });
        } else {
          Navigator.of(context).pop();
          SavingsGoalTransaction trx = SavingsGoalTransaction(
            savingsGoalTrxId: Random().nextInt(10000000).toString(),
            savingsGoalTrxName: nameController.text.trim(),
            savingsGoalTrxAmount: double.parse(amountController.text),
            savingsGoalTrxCreatedOn: formatDate(DateTime.now()),
          );
          List<dynamic> trxs = goal['savingsGoalTransactions'];
          trxs.add(trx.toJson());

          goal['savingsGoalTransactions'] = trxs;

          ApiProvider api = Provider.of<ApiProvider>(context, listen: false);
          await api.updateGoal(context, goal).then((Response resp) {
            if (resp.statusCode == HttpStatus.ok) {
              Toasts.show(
                context,
                'Savings added to the Goal',
                type: ToastType.success,
              );
            }
          });
        }
      },
      showCancel: true,
      confirmText: 'Add',
      confirmColor: Colors.green,
      cancelText: 'Cancel',
      onCancel: () => Navigator.of(context).pop(),
    );
  }
}
