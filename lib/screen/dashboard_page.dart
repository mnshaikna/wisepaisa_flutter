import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:wisepaise/models/type_model.dart';
import 'package:wisepaise/providers/api_provider.dart';
import 'package:wisepaise/providers/notification_provider.dart';
import 'package:wisepaise/providers/settings_provider.dart';
import 'package:wisepaise/screen/all_expense_page.dart';
import 'package:wisepaise/screen/create_expense_group_page.dart';
import 'package:wisepaise/screen/create_expense_page.dart';
import 'package:wisepaise/screen/expense_group_details_page.dart';
import 'package:wisepaise/screen/create_reminder_page.dart';
import 'package:wisepaise/utils/dialog_utils.dart';
import 'package:wisepaise/utils/utils.dart';

import '../models/reminder_model.dart';
import '../providers/auth_provider.dart';
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

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  init() async {
    ApiProvider api = Provider.of<ApiProvider>(context, listen: false);
    api.setLoading();
    AuthProvider auth = Provider.of<AuthProvider>(context, listen: false);
    NotificationProvider notification = Provider.of<NotificationProvider>(
      context,
      listen: false,
    );

    await Future.wait([
      api.getGroups(auth.user!.id, context),
      api.getReminders(auth.user!.id, context),
      api.getUserExpenses(auth.user!.id, context),
    ]);

    if (getActiveButExpired(api).isNotEmpty) {
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

    /*await notification.scheduleNotification(seconds: 30);
    Toasts.show(
      context,
      "Notification scheduled at ${DateTime.now().add(const Duration(seconds: 20))}",
      type: ToastType.info,
    );*/
  }

  List<Map<String, dynamic>> getActiveReminders(ApiProvider api) {
    return api.expenseReminderList.where((rem) {
      return rem['reminderIsActive'] == true;
    }).toList();
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
    return Consumer<ApiProvider>(
      builder: (_, api, __) {
        List top5Groups = List.from(api.groupList)..sort((a, b) {
          final dateA = DateTime.parse(a['exGroupCreatedOn']);
          final dateB = DateTime.parse(b['exGroupCreatedOn']);
          return dateB.compareTo(dateA);
        });

        top5Groups = top5Groups.take(5).toList();
        return Consumer<SettingsProvider>(
          builder: (_, set, __) {
            return Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              appBar: AppBar(
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
                  api.isAPILoading
                      ? buildLoadingContainer(
                        showBgColor: true,
                        context: context,
                      )
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
                                        borderRadius: BorderRadius.circular(
                                          12.0,
                                        ),
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
                      : RefreshIndicator(
                        onRefresh: () async {
                          await init();
                        },
                        child: Stack(
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.0,
                                vertical: 0.0,
                              ),
                              child:
                                  api.groupList.isEmpty &&
                                          getActiveReminders(api).isEmpty &&
                                          api.userExpenseList.isEmpty
                                      ? ListView(
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        children: [
                                          Text(
                                            'Welcome, ${auth.user!.displayName}',
                                            style: theme.textTheme.headlineSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                            textAlign: TextAlign.start,
                                            overflow: TextOverflow.ellipsis,
                                            softWrap: true,
                                            maxLines: 1,
                                          ),
                                          SizedBox(height: 15.0),
                                          buildCreateDataBox(
                                            context,
                                            "Looks empty 👀\n\n➕ Add your first expense reminder!",
                                            () async {
                                              Map<String, dynamic>?
                                              data = await Navigator.of(
                                                context,
                                              ).push(
                                                MaterialPageRoute(
                                                  builder:
                                                      (
                                                        context,
                                                      ) => CreateReminderPage(
                                                        reminder:
                                                            ReminderModel.empty(),
                                                      ),
                                                ),
                                              );

                                              if (data != null) {
                                                api.expenseReminderList.add(
                                                  data,
                                                );
                                                getActiveReminders(
                                                  api,
                                                ).add(data);
                                              }
                                            },
                                            LinearGradient(
                                              colors: [
                                                Color(0xFF757F9A),
                                                Color(0xFFD7DDE8),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                          ),
                                          SizedBox(height: 15.0),
                                          buildCreateDataBox(
                                            context,
                                            "Start organizing your spending 📊\n\n➕ Add your first group",
                                            () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder:
                                                      (context) =>
                                                          CreateExpenseGroupPage(),
                                                ),
                                              );
                                            },
                                            LinearGradient(
                                              colors: [
                                                Color(0xFF56CCF2),
                                                Color(0xFF2F80ED),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                          ),
                                          SizedBox(height: 15.0),
                                          buildCreateDataBox(
                                            context,
                                            "Be on Track 📊\n\n➕ Add your first Expense",
                                            () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder:
                                                      (context) =>
                                                          CreateExpensePage(
                                                            group: {},
                                                            expense: {},
                                                          ),
                                                ),
                                              );
                                            },
                                            LinearGradient(
                                              colors: [
                                                Color(0xFFEFEFBB),
                                                Color(0xFFD4D3DD),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                          ),
                                        ],
                                      )
                                      : ListView(
                                        physics:
                                            AlwaysScrollableScrollPhysics(),
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
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  "Expense Reminders",
                                                  style: theme
                                                      .textTheme
                                                      .titleLarge
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                                if (api
                                                    .expenseReminderList
                                                    .isNotEmpty)
                                                  ElevatedButton.icon(
                                                    onPressed:
                                                        api
                                                                .expenseReminderList
                                                                .isEmpty
                                                            ? null
                                                            : () async {
                                                              await Navigator.of(
                                                                context,
                                                              ).push(
                                                                MaterialPageRoute(
                                                                  builder:
                                                                      (
                                                                        context,
                                                                      ) =>
                                                                          AllReminderPage(),
                                                                ),
                                                              );
                                                              // Rebuild after coming back
                                                              setState(() {});
                                                            },

                                                    style: ElevatedButton.styleFrom(
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12.0,
                                                            ),
                                                      ),
                                                      elevation: 0.0,
                                                      animationDuration:
                                                          Duration(
                                                            milliseconds: 500,
                                                          ),
                                                    ),
                                                    label: Text(
                                                      'View all',
                                                      style: TextStyle(
                                                        letterSpacing: 1.5,
                                                      ),
                                                    ),
                                                    icon: Icon(
                                                      Icons.arrow_forward,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          getActiveReminders(api).isEmpty
                                              ? buildCreateDataBox(
                                                context,
                                                "Looks empty 👀\n\nAdd your first expense reminder!",
                                                () {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder:
                                                          (
                                                            context,
                                                          ) => CreateReminderPage(
                                                            reminder:
                                                                ReminderModel.empty(),
                                                          ),
                                                    ),
                                                  );
                                                },
                                                LinearGradient(
                                                  colors: [
                                                    Color(0xFF2193b0),
                                                    Color(0xFF6dd5ed),
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                              )
                                              : SizedBox(
                                                height: 165,
                                                child: ListView.separated(
                                                  physics:
                                                      BouncingScrollPhysics(),
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  itemCount:
                                                      getActiveReminders(
                                                        api,
                                                      ).length,
                                                  separatorBuilder:
                                                      (context, index) =>
                                                          const SizedBox(
                                                            width: 12,
                                                          ),
                                                  itemBuilder: (
                                                    context,
                                                    index,
                                                  ) {
                                                    final reminder =
                                                        getActiveReminders(
                                                          api,
                                                        )[index];

                                                    return GestureDetector(
                                                      onTap: () {
                                                        setState(() {
                                                          _selectedReminder =
                                                              reminder;
                                                          isExpanded = true;
                                                        });
                                                      },
                                                      child: buildReminderCard(
                                                        reminder,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                          const SizedBox(height: 15.0),

                                          // 🔹 Expense Groups Section
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 5.0,
                                              horizontal: 5.0,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,

                                              children: [
                                                Text(
                                                  "Expense Groups",
                                                  style: theme
                                                      .textTheme
                                                      .titleLarge
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                                if (api.groupList.isNotEmpty &&
                                                    api.groupList.length > 5)
                                                  ElevatedButton.icon(
                                                    onPressed:
                                                        api.groupList.isEmpty
                                                            ? null
                                                            : () async {
                                                              await Navigator.of(
                                                                context,
                                                              ).push(
                                                                MaterialPageRoute(
                                                                  builder:
                                                                      (
                                                                        context,
                                                                      ) =>
                                                                          AllGroupPage(),
                                                                ),
                                                              );
                                                              // Rebuild after coming back
                                                              setState(() {});
                                                            },

                                                    style: ElevatedButton.styleFrom(
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12.0,
                                                            ),
                                                      ),
                                                      elevation: 0.0,
                                                      animationDuration:
                                                          Duration(
                                                            milliseconds: 500,
                                                          ),
                                                    ),
                                                    label: Text(
                                                      'View all',
                                                      style: TextStyle(
                                                        letterSpacing: 1.5,
                                                      ),
                                                    ),
                                                    icon: Icon(
                                                      Icons.arrow_forward,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          if (api.groupList.isEmpty)
                                            buildCreateDataBox(
                                              context,
                                              "Start organizing your spending 📊\n\n➕ Add your first group",
                                              () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder:
                                                        (context) =>
                                                            CreateExpenseGroupPage(),
                                                  ),
                                                );
                                              },
                                              LinearGradient(
                                                colors: [
                                                  Color(0xFF56CCF2),
                                                  Color(0xFF2F80ED),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                            )
                                          else
                                            top5Groups.length <= 2
                                                ? SizedBox(
                                                  height: 85.0,
                                                  width: 140,
                                                  child: ListView.builder(
                                                    physics:
                                                        BouncingScrollPhysics(),
                                                    scrollDirection:
                                                        Axis.horizontal,
                                                    shrinkWrap: false,
                                                    itemCount:
                                                        top5Groups.length,
                                                    itemBuilder: (
                                                      context,
                                                      index,
                                                    ) {
                                                      Map<String, dynamic>
                                                      thisGroup =
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
                                                                  BorderRadius.circular(
                                                                    12,
                                                                  ),
                                                            ),
                                                            child: InkWell(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    12.0,
                                                                  ),
                                                              splashColor: theme
                                                                  .colorScheme
                                                                  .primary
                                                                  .withOpacity(
                                                                    0.15,
                                                                  ),
                                                              highlightColor: theme
                                                                  .colorScheme
                                                                  .primary
                                                                  .withOpacity(
                                                                    0.08,
                                                                  ),
                                                              onTap: () {
                                                                Navigator.of(
                                                                  context,
                                                                ).push(
                                                                  MaterialPageRoute(
                                                                    builder:
                                                                        (
                                                                          context,
                                                                        ) => ExpenseGroupDetailsPage(
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
                                                                            height:
                                                                                50.0,
                                                                            width:
                                                                                50.0,
                                                                            decoration: BoxDecoration(
                                                                              borderRadius: BorderRadius.circular(
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
                                                                            width:
                                                                                10.0,
                                                                          ),
                                                                          Expanded(
                                                                            child: Column(
                                                                              mainAxisAlignment:
                                                                                  MainAxisAlignment.center,
                                                                              crossAxisAlignment:
                                                                                  CrossAxisAlignment.start,
                                                                              children: [
                                                                                Text(
                                                                                  '${thisGroup['exGroupName']}',
                                                                                  style: theme.textTheme.titleMedium?.copyWith(
                                                                                    fontWeight:
                                                                                        FontWeight.bold,
                                                                                  ),
                                                                                  softWrap:
                                                                                      true,
                                                                                  overflow:
                                                                                      TextOverflow.ellipsis,
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
                                                                                      color: theme.colorScheme.onSurface.withOpacity(
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
                                                                              .end,
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .min,
                                                                      children: [
                                                                        Row(
                                                                          mainAxisSize:
                                                                              MainAxisSize.min,
                                                                          children: [
                                                                            const Icon(
                                                                              Icons.arrow_upward,
                                                                              color:
                                                                                  Colors.green,
                                                                              size:
                                                                                  20,
                                                                            ),
                                                                            const SizedBox(
                                                                              width:
                                                                                  2,
                                                                            ),
                                                                            Text(
                                                                              formatCurrency(
                                                                                thisGroup['exGroupIncome'],
                                                                                context,
                                                                              ),
                                                                              style: theme.textTheme.titleSmall?.copyWith(
                                                                                fontWeight:
                                                                                    FontWeight.bold,
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                        const SizedBox(
                                                                          height:
                                                                              5,
                                                                        ),
                                                                        Row(
                                                                          mainAxisSize:
                                                                              MainAxisSize.min,
                                                                          children: [
                                                                            const Icon(
                                                                              Icons.arrow_downward,
                                                                              color:
                                                                                  Colors.red,
                                                                              size:
                                                                                  20,
                                                                            ),
                                                                            const SizedBox(
                                                                              width:
                                                                                  2,
                                                                            ),
                                                                            Text(
                                                                              formatCurrency(
                                                                                thisGroup['exGroupExpenses'],
                                                                                context,
                                                                              ),
                                                                              style: theme.textTheme.titleSmall?.copyWith(
                                                                                fontWeight:
                                                                                    FontWeight.bold,
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
                                                    physics:
                                                        BouncingScrollPhysics(),
                                                    scrollDirection:
                                                        Axis.horizontal,
                                                    itemCount:
                                                        top5Groups.length,
                                                    gridDelegate:
                                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                                          crossAxisCount:
                                                              2, // 2 rows
                                                          mainAxisSpacing:
                                                              8.0, // spacing between columns
                                                          crossAxisSpacing:
                                                              8.0, // spacing between rows
                                                          mainAxisExtent: 300,
                                                        ),
                                                    itemBuilder: (
                                                      context,
                                                      index,
                                                    ) {
                                                      Map<String, dynamic>
                                                      thisGroup =
                                                          api.groupList[index];
                                                      return Hero(
                                                        tag:
                                                            'groupCard_${thisGroup['exGroupId']}',
                                                        child: Card(
                                                          elevation: 1,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12,
                                                                ),
                                                          ),
                                                          child: InkWell(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12.0,
                                                                ),
                                                            splashColor: theme
                                                                .colorScheme
                                                                .primary
                                                                .withOpacity(
                                                                  0.15,
                                                                ),
                                                            highlightColor: theme
                                                                .colorScheme
                                                                .primary
                                                                .withOpacity(
                                                                  0.08,
                                                                ),
                                                            onTap: () {
                                                              Navigator.of(
                                                                context,
                                                              ).push(
                                                                MaterialPageRoute(
                                                                  builder:
                                                                      (
                                                                        context,
                                                                      ) => ExpenseGroupDetailsPage(
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
                                                                          height:
                                                                              75.0,
                                                                          width:
                                                                              75.0,
                                                                          decoration: BoxDecoration(
                                                                            borderRadius: BorderRadius.circular(
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
                                                                          width:
                                                                              10.0,
                                                                        ),
                                                                        Expanded(
                                                                          child: Column(
                                                                            mainAxisAlignment:
                                                                                MainAxisAlignment.center,
                                                                            crossAxisAlignment:
                                                                                CrossAxisAlignment.start,
                                                                            children: [
                                                                              Text(
                                                                                '${thisGroup['exGroupName']}',
                                                                                style: theme.textTheme.titleMedium?.copyWith(
                                                                                  fontWeight:
                                                                                      FontWeight.bold,
                                                                                ),
                                                                                softWrap:
                                                                                    true,
                                                                                overflow:
                                                                                    TextOverflow.ellipsis,
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
                                                                                    color: theme.colorScheme.onSurface.withOpacity(
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
                                                                            .end,
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .min,
                                                                    children: [
                                                                      Row(
                                                                        mainAxisSize:
                                                                            MainAxisSize.min,
                                                                        children: [
                                                                          const Icon(
                                                                            Icons.arrow_upward,
                                                                            color:
                                                                                Colors.green,
                                                                            size:
                                                                                20,
                                                                          ),
                                                                          const SizedBox(
                                                                            width:
                                                                                2,
                                                                          ),
                                                                          Text(
                                                                            formatCurrency(
                                                                              thisGroup['exGroupIncome'],
                                                                              context,
                                                                            ),
                                                                            style: theme.textTheme.titleSmall?.copyWith(
                                                                              fontWeight:
                                                                                  FontWeight.bold,
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                      const SizedBox(
                                                                        height:
                                                                            5,
                                                                      ),
                                                                      Row(
                                                                        mainAxisSize:
                                                                            MainAxisSize.min,
                                                                        children: [
                                                                          const Icon(
                                                                            Icons.arrow_downward,
                                                                            color:
                                                                                Colors.red,
                                                                            size:
                                                                                20,
                                                                          ),
                                                                          const SizedBox(
                                                                            width:
                                                                                2,
                                                                          ),
                                                                          Text(
                                                                            formatCurrency(
                                                                              thisGroup['exGroupExpenses'],
                                                                              context,
                                                                            ),
                                                                            style: theme.textTheme.titleSmall?.copyWith(
                                                                              fontWeight:
                                                                                  FontWeight.bold,
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

                                          const SizedBox(height: 10.0),

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
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  "Expenses",
                                                  style: theme
                                                      .textTheme
                                                      .titleLarge
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                                if (api
                                                    .userExpenseList
                                                    .isNotEmpty)
                                                  ElevatedButton.icon(
                                                    onPressed:
                                                        api
                                                                .userExpenseList
                                                                .isEmpty
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
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12.0,
                                                            ),
                                                      ),
                                                      elevation: 0.0,
                                                      animationDuration:
                                                          Duration(
                                                            milliseconds: 500,
                                                          ),
                                                    ),
                                                    label: Text(
                                                      'View all',
                                                      style: TextStyle(
                                                        letterSpacing: 1.5,
                                                      ),
                                                    ),
                                                    icon: Icon(
                                                      Icons.arrow_forward,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          if (api.userExpenseList.isEmpty)
                                            buildCreateDataBox(
                                              context,
                                              "Start tracking your spending 📊\n\n➕ Add your first Expense",
                                              () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder:
                                                        (context) =>
                                                            CreateExpensePage(
                                                              group: {},
                                                              expense: {},
                                                            ),
                                                  ),
                                                );
                                              },
                                              LinearGradient(
                                                colors: [
                                                  Color(0xFF56CCF2),
                                                  Color(0xFF2F80ED),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                            )
                                          else
                                            ...buildGroupedExpenseWidgets(
                                              api.userExpenseList,
                                              context,
                                            ),
                                        ],
                                      ),
                            ),
                            // Overlay reminder card (conditionally visible)
                            if (_selectedReminder != null)
                              _buildExpandedReminderOverlay(context),
                          ],
                        ),
                      ),
            );
          },
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
                                  color: Colors.white,
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
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
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
          ],
        ),
      ),
    );
  }
}
