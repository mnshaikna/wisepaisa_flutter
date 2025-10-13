import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:wisepaise/providers/api_provider.dart';
import 'package:wisepaise/providers/auth_provider.dart';
import 'package:wisepaise/screen/create_expense_page.dart';
import 'package:wisepaise/screen/expense_search_page.dart';

import '../models/group_model.dart';
import '../models/type_model.dart';
import '../utils/constants.dart';
import '../utils/dialog_utils.dart';
import '../utils/expense_pie_chart.dart';
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

  @override
  void initState() {
    super.initState();
    init();
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

  void _showChartSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      isDismissible: false,
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
                  child: Text(
                    'Expenses Chart',
                    style: TextStyle(
                      letterSpacing: 1.5,
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ExpensePieChart(expenses: group.expenses),
              ),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    AuthProvider auth = Provider.of<AuthProvider>(context, listen: false);
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
                    () =>
                        group.expenses.isNotEmpty
                            ? Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        ExpenseSearchPage(group: group),
                              ),
                            )
                            : Toasts.show(
                              context,
                              'Add atleast one expense',
                              type: ToastType.info,
                            ),
                child: AbsorbPointer(
                  child: CupertinoSearchTextField(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10.0,
                      horizontal: 10.0,
                    ),
                    placeholder: 'Search expenses...',
                    placeholderStyle: TextStyle(
                      fontSize: 15.0,
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
                        onTap: () => _showChartSheet(context),
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
                              child: Icon(FontAwesomeIcons.chartPie, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text('Chart')),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        onTap: () {
                          DialogUtils.showGenericDialog(
                            context: context,
                            title: DialogUtils.titleText('Delete Group?'),
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
                        margin: const EdgeInsets.all(16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,

                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12.0),
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
                                                if (loadingProgress == null) {
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
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),

                                        if (group.exGroupDesc.isNotEmpty)
                                          Text(
                                            group.exGroupDesc,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade700,
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
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Icon(Icons.person, size: 20.0),
                                      SizedBox(width: 5.0),
                                      Text(
                                        auth.user!.displayName!,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Icon(Icons.date_range, size: 20.0),
                                      SizedBox(width: 5.0),
                                      Text(
                                        formatDateString(
                                          group.exGroupCreatedOn,
                                        ),
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  SizedBox(height: 15.0),
                                  Row(
                                    mainAxisAlignment:
                                        group.exGroupShared &&
                                                group.exGroupMembers.isNotEmpty
                                            ? MainAxisAlignment.spaceBetween
                                            : MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      if (group.exGroupShared &&
                                          group.exGroupMembers.isNotEmpty)
                                        initialsRow(
                                          group.exGroupMembers,
                                          context,
                                        ),
                                      if (group.exGroupShared &&
                                          group.exGroupMembers.isNotEmpty)
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.arrow_upward,
                                                  color: Colors.green,
                                                ),
                                                Text(
                                                  formatCurrency(
                                                    group.exGroupIncome,
                                                    context,
                                                  ),
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 1.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(width: 5.0),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.arrow_downward,
                                                  color: Colors.red,
                                                ),
                                                Text(
                                                  formatCurrency(
                                                    group.exGroupExpenses,
                                                    context,
                                                  ),
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 1.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        )
                                      else
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.arrow_upward,
                                                  color: Colors.green,
                                                ),
                                                Text(
                                                  formatCurrency(
                                                    group.exGroupIncome,
                                                    context,
                                                  ),
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 1.5,
                                                    color: Colors.green
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(width: 5.0),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.arrow_downward,
                                                  color: Colors.red,
                                                ),
                                                Text(
                                                  formatCurrency(
                                                    group.exGroupExpenses,
                                                    context,
                                                  ),
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 1.5,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
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
                                    "Be on Track 📊\n\n➕ Add your Expenses",
                                    () async {
                                      final updatedGroup = await Navigator.of(
                                        context,
                                      ).push(
                                        MaterialPageRoute(
                                          builder:
                                              (context) => CreateExpensePage(
                                                group: group.toJson(),
                                                expense: {},
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
                                        setState(() {});
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
                                                if (resp.statusCode == 200) {
                                                  Toasts.show(
                                                    context,
                                                    "Expense ${expense['expenseTitle']} Removed",
                                                    type: ToastType.success,
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
                                                  });
                                                }
                                              });
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5.0,
                                          ),
                                          child: ListTile(
                                            onTap: () {
                                              debugPrint(
                                                'expenseId:::${expense['expenseId']}',
                                              );
                                              DialogUtils.showGenericDialog(
                                                context: context,
                                                showCancel: true,
                                                onConfirm:
                                                    expense['expenseId'] !=
                                                                null &&
                                                            expense['expenseId']
                                                                .isNotEmpty
                                                        ? () async {
                                                          final updatedGroup =
                                                              await Navigator.of(
                                                                context,
                                                              ).push(
                                                                MaterialPageRoute(
                                                                  builder:
                                                                      (
                                                                        context,
                                                                      ) => CreateExpensePage(
                                                                        group:
                                                                            group.toJson(),
                                                                        expense:
                                                                            expense,
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
                                                            setState(() {});
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
                                                height: 65.0,
                                                width: 65.0,
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      getCategoryIcon(
                                                        expense['expenseCategory'],
                                                        expense['expenseSpendType'],
                                                      ),
                                                      size: 15.0,
                                                    ),
                                                    Divider(
                                                      endIndent: 10.0,
                                                      indent: 10.0,
                                                      thickness: 0.5,
                                                    ),
                                                    Text(
                                                      '${DateTime.parse(expense['expenseDate']).day.toString()} ${month.elementAt(int.parse(DateTime.parse(expense['expenseDate']).month.toString()) - 1).toUpperCase()}',
                                                      style: TextStyle(
                                                        fontSize: 12.5,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            title: Text(
                                              expense['expenseTitle'],
                                              style: TextStyle(fontSize: 17.5),
                                            ),
                                            subtitle: Text(
                                              '${expense['expenseCategory']} | ${expense['expenseSubCategory']}',
                                              style: TextStyle(fontSize: 12.5),
                                            ),
                                            trailing: Text(
                                              formatCurrency(
                                                expense['expenseAmount'],
                                                context,
                                              ),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1.5,
                                                fontSize: 13.5,
                                                color:
                                                    expense['expenseSpendType'] ==
                                                            'income'
                                                        ? Colors.green
                                                        : Colors.red,
                                              ),
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
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              final updatedGroup = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (context) =>
                          CreateExpensePage(group: group.toJson(), expense: {}),
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
                setState(() {});
              }
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
            child: Icon(Icons.add),
          ),
        );
      },
    );
  }
}
