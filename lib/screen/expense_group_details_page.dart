import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:wisepaise/providers/api_provider.dart';
import 'package:wisepaise/providers/auth_provider.dart';
import 'package:wisepaise/screen/create_expense_group_page.dart';
import 'package:wisepaise/screen/create_expense_page.dart';
import 'package:wisepaise/screen/expense_search_page.dart';
import 'package:wisepaise/screen/group_balance_screen.dart';
import 'package:wisepaise/utils/print_share_pdf.dart';

import '../models/group_model.dart';
import '../models/type_model.dart';
import '../utils/constants.dart';
import '../utils/dialog_utils.dart';
import 'expense_chart_screen.dart';
import '../utils/toast.dart';
import '../utils/utils.dart';

class ExpenseGroupDetailsPage extends StatefulWidget {
  Map<String, dynamic> groupMap;

  ExpenseGroupDetailsPage({required this.groupMap});

  @override
  State<ExpenseGroupDetailsPage> createState() =>
      _ExpenseGroupDetailsPageState(groupMap: groupMap);
}

class _ExpenseGroupDetailsPageState extends State<ExpenseGroupDetailsPage> {
  Map<String, dynamic> groupMap;

  _ExpenseGroupDetailsPageState({required this.groupMap});

  late GroupModel group;
  final PageController _overviewController = PageController();
  int _overviewPageIndex = 0;
  DateTime? startDate, endDate;

  @override
  void initState() {
    super.initState();
    AuthProvider auth = Provider.of<AuthProvider>(context, listen: false);
    init();
    getMinMaxDates();
  }

  init() {
    group = GroupModel.fromJson(groupMap);

    group.expenses.sort((a, b) {
      final dateA = DateTime.parse(a['expenseDate']);
      final dateB = DateTime.parse(b['expenseDate']);
      return dateB.compareTo(dateA);
    });
    debugPrint(group.expenses.toString());
  }

  @override
  void dispose() {
    _overviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AuthProvider auth = Provider.of<AuthProvider>(context, listen: false);
    final theme = Theme.of(context);
    List expenseList = group.expenses;
    return Consumer<ApiProvider>(
      builder: (_, api, __) {
        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: Hero(
              tag: 'searchHero',
              child: GestureDetector(
                onTap:
                    () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ExpenseSearchPage(group: group),
                      ),
                    ),
                child: AbsorbPointer(
                  child: CupertinoSearchTextField(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10.0,
                      horizontal: 10.0,
                    ),
                    placeholder: 'Search expenses...',
                    placeholderStyle: theme.textTheme.titleSmall!.copyWith(
                      letterSpacing: 1.5,
                      color:
                          Theme.of(context).brightness == Brightness.light
                              ? Colors.black54
                              : Colors.white54,
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 8.0, top: 5.0),
                      child: Icon(Icons.search),
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              PopupMenuButton(
                itemBuilder:
                    (BuildContext context) => <PopupMenuEntry<String>>[
                      PopupMenuItem(
                        onTap: () async {
                          Uint8List pdfBytes =
                              await generateProfessionalGroupPdf(
                                group,
                                context,
                                expenses: [],
                              );

                          await Printing.sharePdf(
                            bytes: pdfBytes,
                            filename: '${group.exGroupName}_report.pdf',
                          );
                        },
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        value: 'OptionA',
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              height: 40,
                              width: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Icon(FontAwesomeIcons.share, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text('Export/Share')),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        onTap:
                            () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (context) => ExpenseChartScreen(
                                      expenses: group.expenses,
                                    ),
                              ),
                            ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        value: 'OptionB',
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              height: 40,
                              width: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Icon(FontAwesomeIcons.chartPie, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text('Chart')),
                          ],
                        ),
                      ),
                      if (group.exGroupShared)
                        PopupMenuItem(
                          onTap:
                              () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          GroupBalanceScreen(group: groupMap),
                                ),
                              ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          value: 'OptionC',
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                height: 40,
                                width: 40,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: Icon(
                                  FontAwesomeIcons.scaleUnbalancedFlip,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text('Member Balances')),
                            ],
                          ),
                        ),
                      if (group.exGroupOwnerId['userId'] ==
                          auth.thisUser!['userId'])
                        PopupMenuItem(
                          onTap: () {
                            DialogUtils.showGenericDialog(
                              context: context,
                              title: DialogUtils.titleText(
                                'Delete Group?',
                                context,
                              ),
                              message: Text(
                                'Are you sure you want to delete this Expense Group?',
                              ),
                              confirmText: 'Delete',
                              confirmColor: Colors.red,
                              onConfirm: () async {
                                Navigator.pop(context);
                                await api
                                    .deleteGroups(group.exGroupId, context)
                                    .then((Response res) {
                                      api.groupList.removeWhere(
                                        (element) =>
                                            element['exGroupId'] ==
                                            group.exGroupId,
                                      );
                                      Navigator.pop(context);
                                      Toasts.show(
                                        context,
                                        'Expense Group Deleted',
                                        type: ToastType.success,
                                      );
                                    });
                              },
                              showCancel: true,
                              cancelText: 'Cancel',
                              onCancel: () => Navigator.pop(context),
                            );
                          },
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          value: 'OptionD',
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                height: 40,
                                width: 40,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: Icon(Icons.delete, size: 20),
                              ),
                              SizedBox(width: 12),
                              Expanded(child: Text('Delete group')),
                            ],
                          ),
                        ),
                    ],
              ),
            ],
            actionsPadding: EdgeInsets.only(right: 10.0),
          ),
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    SizedBox(
                      height: group.exGroupShared ? 220.0 : 180.0,
                      child: PageView(
                        controller: _overviewController,
                        onPageChanged: (int i) {
                          setState(() {
                            _overviewPageIndex = i;
                          });
                        },
                        scrollDirection: Axis.horizontal,
                        children: [
                          Hero(
                            tag: 'groupCard_${group.exGroupId}',
                            flightShuttleBuilder: (
                              flightContext,
                              animation,
                              direction,
                              fromContext,
                              toContext,
                            ) {
                              return Material(
                                child:
                                    (direction == HeroFlightDirection.push
                                        ? fromContext.widget
                                        : toContext.widget),
                              );
                            },
                            child: Card(
                              elevation: 1,
                              margin: const EdgeInsets.all(15.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12.0,
                                          ),
                                          child:
                                              group.exGroupImageURL.isNotEmpty
                                                  ? Image.network(
                                                    group.exGroupImageURL,
                                                    width: 80,
                                                    height: 80,
                                                    fit: BoxFit.cover,
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
                                                        width: 80,
                                                        height: 80,
                                                        child: const Center(
                                                          child:
                                                              CupertinoActivityIndicator(),
                                                        ),
                                                      );
                                                    },
                                                  )
                                                  : Container(
                                                    width: 80,
                                                    height: 80,
                                                    color: Colors.grey.shade300,
                                                    child: Icon(
                                                      Icons.group,
                                                      size: 32,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                        ),
                                        const SizedBox(width: 12),

                                        // Group name & type
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                group.exGroupName,
                                                style: theme
                                                    .textTheme
                                                    .titleMedium!
                                                    .copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),

                                              if (group.exGroupDesc.isNotEmpty)
                                                Text(
                                                  group.exGroupDesc,
                                                  style: theme
                                                      .textTheme
                                                      .labelMedium!
                                                      .copyWith(
                                                        color:
                                                            Colors
                                                                .grey
                                                                .shade700,
                                                      ),
                                                ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                children: [
                                                  Icon(
                                                    typeList
                                                        .elementAt(
                                                          int.parse(
                                                            group.exGroupType,
                                                          ),
                                                        )
                                                        .icon,
                                                    size: 20.0,
                                                  ),
                                                  SizedBox(width: 5.0),
                                                  Text(
                                                    typeList
                                                        .elementAt(
                                                          int.parse(
                                                            group.exGroupType,
                                                          ),
                                                        )
                                                        .name,
                                                    style: theme
                                                        .textTheme
                                                        .labelMedium!
                                                        .copyWith(
                                                          color:
                                                              Colors
                                                                  .grey
                                                                  .shade700,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        group.exGroupOwnerId['userId'] ==
                                                auth.thisUser!['userId']
                                            ? IconButton(
                                              iconSize: 20.0,
                                              onPressed: () async {
                                                final updatedGroup =
                                                    await Navigator.of(
                                                      context,
                                                    ).push(
                                                      MaterialPageRoute(
                                                        builder:
                                                            (context) =>
                                                                CreateExpenseGroupPage(
                                                                  group:
                                                                      groupMap,
                                                                ),
                                                      ),
                                                    );
                                                debugPrint(
                                                  'updatedGroup:::$updatedGroup',
                                                );
                                                if (updatedGroup != null) {
                                                  group = GroupModel.fromJson(
                                                    updatedGroup,
                                                  );
                                                  group.expenses.sort((a, b) {
                                                    final dateA =
                                                        DateTime.parse(
                                                          a['expenseDate'],
                                                        );
                                                    final dateB =
                                                        DateTime.parse(
                                                          b['expenseDate'],
                                                        );
                                                    return dateB.compareTo(
                                                      dateA,
                                                    );
                                                  });
                                                  api.groupList.removeWhere(
                                                    (thisGrp) =>
                                                        thisGrp['exGroupId'] ==
                                                        group.exGroupId,
                                                  );
                                                  api.groupList.add(
                                                    group.toJson(),
                                                  );
                                                  setState(() {});
                                                }
                                              },
                                              icon: Icon(Icons.edit_outlined),
                                              style: IconButton.styleFrom(
                                                padding: EdgeInsets.zero,
                                                backgroundColor:
                                                    Theme.of(context)
                                                        .colorScheme
                                                        .surfaceContainerHighest,
                                              ),
                                            )
                                            : SizedBox.shrink(),
                                      ],
                                    ),
                                    const SizedBox(height: 20.0),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Icon(Icons.person, size: 18.0),
                                            SizedBox(width: 5.0),
                                            Text(
                                              group.exGroupOwnerId['userName'],
                                              style: theme
                                                  .textTheme
                                                  .labelMedium!
                                                  .copyWith(
                                                    color: Colors.grey.shade700,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Icon(Icons.date_range, size: 18.0),
                                            SizedBox(width: 5.0),
                                            Text(
                                              formatDateString(
                                                group.exGroupCreatedOn,
                                              ),
                                              style: theme
                                                  .textTheme
                                                  .labelMedium!
                                                  .copyWith(
                                                    color: Colors.grey.shade700,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    if (group.exGroupShared &&
                                        group.exGroupMembers.length > 1)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 15.0,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            initialsRow(
                                              group.exGroupMembers,
                                              context,
                                              showImage: true,
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    if (!group.exGroupShared)
                                                      Icon(
                                                        Icons.arrow_downward,
                                                        color: Colors.red,
                                                      ),
                                                    Text(
                                                      formatCurrency(
                                                        group.exGroupExpenses,
                                                        context,
                                                      ),
                                                      style:
                                                          group.exGroupShared
                                                              ? theme.textTheme.bodyLarge!.copyWith(
                                                                color:
                                                                    group.exGroupShared
                                                                        ? Colors
                                                                            .blue
                                                                        : Colors
                                                                            .red,
                                                                letterSpacing:
                                                                    1.5,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              )
                                                              : theme
                                                                  .textTheme
                                                                  .labelLarge!
                                                                  .copyWith(
                                                                    color:
                                                                        Colors
                                                                            .red,
                                                                    letterSpacing:
                                                                        1.5,
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
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (!group.exGroupShared)
                            _buildGroupMonthlyOverviewSlider(context),
                        ],
                      ),
                    ),
                    if (!group.exGroupShared)
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(2, (int i) {
                            final bool isActive = _overviewPageIndex == i;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: 8,
                              width: 8,
                              decoration: BoxDecoration(
                                color:
                                    isActive
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.25),
                                shape: BoxShape.circle,
                              ),
                            );
                          }),
                        ),
                      ),
                    SizedBox(height: 5.0),
                    Expanded(
                      child:
                          group.expenses.isEmpty
                              ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10.0,
                                  ),
                                  child: buildCreateDataBox(
                                    context,
                                    addExpenseMsg,
                                    () async {
                                      final updatedGroup = await Navigator.of(
                                        context,
                                      ).push(
                                        MaterialPageRoute(
                                          builder:
                                              (context) => CreateExpensePage(
                                                group: group.toJson(),
                                                expense: {},
                                                showGroup: false,
                                              ),
                                        ),
                                      );

                                      if (updatedGroup != null) {
                                        group = GroupModel.fromJson(
                                          updatedGroup,
                                        );
                                        group.expenses.sort((a, b) {
                                          final dateA = DateTime.parse(
                                            a['expenseDate'],
                                          );
                                          final dateB = DateTime.parse(
                                            b['expenseDate'],
                                          );
                                          return dateB.compareTo(dateA);
                                        });
                                        api.groupList.removeWhere(
                                          (thisGrp) =>
                                              thisGrp['exGroupId'] ==
                                              group.exGroupId,
                                        );
                                        api.groupList.add(group.toJson());
                                        setState(() {
                                          groupMap = updatedGroup;
                                        });
                                      }
                                    },
                                    LinearGradient(
                                      colors: [
                                        Color(0xFF3D7EAA),
                                        Color(0xFFFFE47A),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                ),
                              )
                              : ListView.builder(
                                physics: BouncingScrollPhysics(),
                                itemCount: expenseList.length,
                                itemBuilder: (context, index) {
                                  final expense = expenseList[index];
                                  String payStatus = getPayStatus(
                                    expense,
                                    context,
                                  );
                                  return Column(
                                    children: [
                                      Dismissible(
                                        key: UniqueKey(),
                                        direction: DismissDirection.endToStart,
                                        background: Container(
                                          alignment: Alignment.centerRight,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                          ),
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(
                                              10.0,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: const [
                                              Icon(
                                                Icons.delete,
                                                color: Colors.white,
                                              ),
                                              SizedBox(width: 10.0),
                                              Text(
                                                'Delete',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  letterSpacing: 1.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        confirmDismiss: (direction) async {
                                          final shouldDelete =
                                              await DialogUtils.showGenericDialog(
                                                context: context,
                                                title: DialogUtils.titleText(
                                                  'Delete Expense?',
                                                  context,
                                                ),
                                                message: const Text(
                                                  'Are you sure you want to delete this expense?',
                                                ),
                                                onConfirm: () {
                                                  Navigator.of(
                                                    context,
                                                  ).pop(true);
                                                },
                                                onCancel:
                                                    () => Navigator.of(
                                                      context,
                                                    ).pop(false),
                                                showCancel: true,
                                                cancelText: 'Cancel',
                                                confirmText: 'Delete',
                                                confirmColor: Colors.red,
                                              );
                                          return shouldDelete ?? false;
                                        },
                                        onDismissed: (direction) async {
                                          setState(() {
                                            group.expenses.removeAt(index);
                                          });
                                          ApiProvider api =
                                              Provider.of<ApiProvider>(
                                                context,
                                                listen: false,
                                              );
                                          await api
                                              .updateGroup(
                                                context,
                                                group.toJson(),
                                              )
                                              .then((Response resp) {
                                                debugPrint(
                                                  resp.statusCode.toString(),
                                                );
                                                if (resp.statusCode ==
                                                    HttpStatus.ok) {
                                                  debugPrint(
                                                    'resp.data:::${resp.data}',
                                                  );

                                                  var index = api.groupList
                                                      .indexWhere(
                                                        (element) =>
                                                            element['exGroupId'] ==
                                                            group.exGroupId,
                                                      );

                                                  api.groupList[index] =
                                                      resp.data;

                                                  List<Map<String, dynamic>>
                                                  tempList =
                                                      api.groupList.toList();
                                                  api.setGroupList(tempList);
                                                  setState(() {
                                                    group = GroupModel.fromJson(
                                                      resp.data,
                                                    );
                                                    groupMap = resp.data;
                                                  });
                                                  showSnackBar(
                                                    context,
                                                    "Expense Removed",
                                                    Icon(
                                                      Icons
                                                          .remove_circle_outline,
                                                    ),
                                                  );
                                                }
                                              });
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5.0,
                                          ),
                                          child: ListTile(
                                            onTap: () {
                                              DialogUtils.showGenericDialog(
                                                context: context,
                                                showCancel: true,
                                                onConfirm:
                                                    expense['expenseId'] !=
                                                                null &&
                                                            expense['expenseId']
                                                                .isNotEmpty
                                                        ? () async {
                                                          final updatedGroup = await Navigator.of(
                                                            context,
                                                          ).push(
                                                            MaterialPageRoute(
                                                              builder:
                                                                  (
                                                                    context,
                                                                  ) => CreateExpensePage(
                                                                    group:
                                                                        group
                                                                            .toJson(),
                                                                    expense:
                                                                        expense,
                                                                    showGroup:
                                                                        true,
                                                                  ),
                                                            ),
                                                          );
                                                          debugPrint(
                                                            'updatedGroup:::${updatedGroup.toString()}',
                                                          );
                                                          if (updatedGroup !=
                                                              null) {
                                                            group =
                                                                GroupModel.fromJson(
                                                                  updatedGroup,
                                                                );
                                                            group.expenses.sort((
                                                              a,
                                                              b,
                                                            ) {
                                                              final dateA =
                                                                  DateTime.parse(
                                                                    a['expenseDate'],
                                                                  );
                                                              final dateB =
                                                                  DateTime.parse(
                                                                    b['expenseDate'],
                                                                  );
                                                              return dateB
                                                                  .compareTo(
                                                                    dateA,
                                                                  );
                                                            });
                                                            api.groupList.removeWhere(
                                                              (thisGrp) =>
                                                                  thisGrp['exGroupId'] ==
                                                                  group
                                                                      .exGroupId,
                                                            );
                                                            api.groupList.add(
                                                              group.toJson(),
                                                            );
                                                            setState(() {
                                                              groupMap =
                                                                  updatedGroup;
                                                            });
                                                          }
                                                          Navigator.of(
                                                            context,
                                                          ).pop();
                                                        }
                                                        : null,
                                                onCancel:
                                                    () =>
                                                        Navigator.pop(context),

                                                confirmColor: Colors.green,
                                                cancelText: 'Cancel',
                                                confirmText: 'Edit',
                                                title: SizedBox.shrink(),
                                                message: SizedBox(
                                                  child: expenseCard(
                                                    context,
                                                    expense,
                                                  ),
                                                ),
                                              );
                                            },
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                            ),
                                            splashColor: Colors.grey.shade100,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 5.0,
                                                ),
                                            leading: Card(
                                              elevation: 0.0,
                                              margin: EdgeInsets.zero,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12.0),
                                              ),
                                              child: Container(
                                                padding: EdgeInsets.all(4.0),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                ),
                                                height: 75.0,
                                                width: 60.0,
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Expanded(
                                                      child: Icon(
                                                        getCategoryIcon(
                                                          expense['expenseCategory'],
                                                          expense['expenseSpendType'],
                                                        ),
                                                        size: 13.0,
                                                      ),
                                                    ),
                                                    Divider(
                                                      endIndent: 10.0,
                                                      indent: 10.0,
                                                      thickness: 0.5,
                                                    ),
                                                    Expanded(
                                                      child: Text(
                                                        '${DateTime.parse(expense['expenseDate']).day.toString()} ${month.elementAt(int.parse(DateTime.parse(expense['expenseDate']).month.toString()) - 1).toUpperCase()}',
                                                        style: theme
                                                            .textTheme
                                                            .labelSmall!
                                                            .copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            title: Text(
                                              expense['expenseTitle'],
                                              style: theme.textTheme.labelLarge!
                                                  .copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            subtitle: Text(
                                              groupMap['exGroupShared']
                                                  ? '${expense['expensePaidBy']['userId'] == auth.thisUser!['userId'] ? 'You' : expense['expensePaidBy']['userName']} paid ${formatCurrency(expense['expenseAmount'], context)} ${payStatus == 'no balance' ? 'for yourself' : ''}'
                                                  : '${expense['expenseCategory']} | ${expense['expenseSubCategory']}',
                                              style: theme.textTheme.labelSmall!
                                                  .copyWith(color: Colors.grey),
                                            ),
                                            trailing: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                if (groupMap['exGroupShared'])
                                                  Text(
                                                    payStatus,
                                                    style: theme
                                                        .textTheme
                                                        .labelMedium!
                                                        .copyWith(
                                                          letterSpacing: 1.5,
                                                          color:
                                                              payStatus ==
                                                                          'not involved' ||
                                                                      payStatus ==
                                                                          'no balance'
                                                                  ? Colors.grey
                                                                  : payStatus ==
                                                                      'You borrowed'
                                                                  ? Colors.red
                                                                  : Colors
                                                                      .green,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                  ),
                                                group.exGroupShared &&
                                                        (payStatus ==
                                                                'not involved' ||
                                                            payStatus ==
                                                                'no balance')
                                                    ? SizedBox.shrink()
                                                    : Text(
                                                      formatCurrency(
                                                        double.parse(
                                                          getPaidAmount(
                                                            expense,
                                                            group,
                                                          ),
                                                        ),
                                                        context,
                                                      ),
                                                      style: theme
                                                          .textTheme
                                                          .labelMedium!
                                                          .copyWith(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            letterSpacing: 1.5,
                                                            color:
                                                                expense['expenseSpendType'] ==
                                                                        'income'
                                                                    ? Colors
                                                                        .green
                                                                    : Colors
                                                                        .red,
                                                          ),
                                                    ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (index < expenseList.length - 1)
                                        Divider(
                                          indent: 25,
                                          endIndent: 25,
                                          height: 15,
                                          thickness: 0.15,
                                        ),
                                    ],
                                  );
                                },
                              ),
                    ),
                  ],
                ),
                if (api.isAPILoading) buildLoadingContainer(context: context),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            icon: Icon(Icons.receipt_outlined),
            onPressed: () async {
              final updatedGroup = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (context) => CreateExpensePage(
                        group: group.toJson(),
                        expense: {},
                        showGroup: false,
                      ),
                ),
              );

              if (updatedGroup != null) {
                group = GroupModel.fromJson(updatedGroup);
                group.expenses.sort((a, b) {
                  final dateA = DateTime.parse(a['expenseDate']);
                  final dateB = DateTime.parse(b['expenseDate']);
                  return dateB.compareTo(dateA);
                });
                api.groupList.removeWhere(
                  (thisGrp) => thisGrp['exGroupId'] == group.exGroupId,
                );
                api.groupList.add(group.toJson());
                setState(() {
                  groupMap = updatedGroup;
                });
              }
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            extendedIconLabelSpacing: 15.0,
            label: Text(
              'Add Expense',
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  getPaidAmount(Map<String, dynamic> expense, GroupModel group) {
    AuthProvider auth = Provider.of<AuthProvider>(context, listen: false);
    List<dynamic> paidFor = expense['expensePaidTo'];
    debugPrint('expense[expenseAmount]:::${expense['expenseAmount']}');
    debugPrint('paidFor.length:::${paidFor.length}');
    var itsme = paidFor.firstWhere(
      (ele) => ele['userId'] == auth.thisUser!['userId'],
      orElse: () => {},
    );

    if (group.exGroupShared) {
      if (itsme.isEmpty) {
        return expense['expenseAmount'].toStringAsFixed(2);
      } else {
        return (expense['expenseAmount'] -
                (expense['expenseAmount'] / paidFor.length))
            .toStringAsFixed(2);
      }
    } else {
      return expense['expenseAmount'].toStringAsFixed(2);
    }
  }

  Widget _buildGroupMonthlyOverviewSlider(BuildContext context) {
    final theme = Theme.of(context);
    final Color primary =
        theme.brightness == Brightness.light
            ? const Color(0xFF0D47A1)
            : theme.colorScheme.primary;

    final double income = group.exGroupIncome;
    final double expenses = group.exGroupExpenses;
    //final double savings = (income - expenses).clamp(0.0, double.infinity);
    final double savings = (income - expenses);
    double savingsPct =
        (income == 0 ? 0 : savings / income).clamp(0.0, 1.0).toDouble();
    savingsPct = 1 - savingsPct;

    return Container(
      margin: EdgeInsets.only(top: 10.0, left: 15.0, right: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: SizedBox(
              height: 150,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 0.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Group Overview',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${formatDateString(startDate.toString(), pattern: "dd MMM")} - ${formatDateString(endDate.toString(), pattern: 'dd MMM')}',
                          style: theme.textTheme.labelMedium!.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildOverviewStatTile(
                                  context,
                                  label: 'Income',
                                  value: formatCurrency(income, context),
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildOverviewStatTile(
                                  context,
                                  label: 'Expenses',
                                  value: formatCurrency(expenses, context),
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildOverviewStatTile(
                                  context,
                                  label: 'Savings',
                                  value: formatCurrency(savings, context),
                                  color: primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10.0),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: savingsPct,
                              minHeight: 7.5,
                              color: savingsPct > 0.75 ? Colors.red : primary,
                              backgroundColor: theme.colorScheme.onSurface
                                  .withOpacity(0.08),
                            ),
                          ),
                          const SizedBox(height: 5.0),
                          Text(
                            '${(savingsPct * 100).toStringAsFixed(0)}% spent',
                            style: theme.textTheme.labelSmall!.copyWith(
                              color: savingsPct > 0.75 ? Colors.red : primary,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewStatTile(
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
                  style: theme.textTheme.labelMedium?.copyWith(
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

  getMinMaxDates() {
    if (group.expenses.isNotEmpty) {
      Map<String, dynamic> earliest = group.expenses.reduce(
        (a, b) =>
            DateTime.parse(
                  a['expenseDate'],
                ).isBefore(DateTime.parse(b['expenseDate']))
                ? a
                : b,
      );

      Map<String, dynamic> latest = group.expenses.reduce(
        (a, b) =>
            DateTime.parse(
                  a['expenseDate'],
                ).isAfter(DateTime.parse(b['expenseDate']))
                ? a
                : b,
      );

      setState(() {
        startDate = DateTime.parse(earliest['expenseDate']);
        endDate = DateTime.parse(latest['expenseDate']);
      });
    } else {
      startDate = DateTime.now();
      endDate = DateTime.now();
    }
  }
}
