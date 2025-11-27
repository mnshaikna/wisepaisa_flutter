import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:wisepaise/models/savings_goal_model.dart';
import 'package:wisepaise/providers/api_provider.dart';
import 'package:wisepaise/screen/create_savings_goal_page.dart';
import 'package:wisepaise/utils/dialog_utils.dart';
import 'package:wisepaise/utils/utils.dart';

import '../models/savings_goal_transaction.dart';
import '../providers/settings_provider.dart';
import '../utils/toast.dart';

class SavingsGoalDetailsPage extends StatefulWidget {
  final Map<String, dynamic> goal;

  const SavingsGoalDetailsPage({super.key, required this.goal});

  @override
  State<SavingsGoalDetailsPage> createState() =>
      _SavingsGoalDetailsPageState(goal: goal);
}

class _SavingsGoalDetailsPageState extends State<SavingsGoalDetailsPage> {
  Map<String, dynamic> goal;

  _SavingsGoalDetailsPageState({required this.goal});

  final PageController _metricsController = PageController(
    viewportFraction: 0.88,
  );
  int _metricsIndex = 0;

  @override
  void dispose() {
    _metricsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary =
        theme.brightness == Brightness.light
            ? const Color(0xFF0D47A1)
            : theme.colorScheme.primary;

    final double target = (goal['savingsGoalTargetAmount'] as num).toDouble();
    final double saved =
        (goal['savingsGoalCurrentAmount'] as num? ?? 0).toDouble();
    final double remaining = (target - saved).clamp(0, double.infinity);
    final DateTime today = DateTime.now();
    final DateTime targetDate =
        DateTime.tryParse(goal['savingsGoalTargetDate']?.toString() ?? '') ??
        today;

    final int daysLeft = targetDate.difference(today).inDays;
    debugPrint('daysLeft:::$daysLeft');
    final double pct = target == 0 ? 0 : (saved / target).clamp(0, 1);

    // Suggested and observed cadence
    final double requiredPerMonth =
        daysLeft > 0 ? remaining / (daysLeft / 30) : remaining;
    final List<dynamic> trxs = goal['savingsGoalTransactions'] ?? <dynamic>[];
    final double totalTrxSaved = trxs.fold<double>(
      0.0,
      (s, t) => s + ((t['savingsGoalTrxAmount'] as num? ?? 0).toDouble()),
    );

    debugPrint('goal[savingsGoalCreatedOn]:::${goal['savingsGoalCreatedOn']}');

    final createdOn = DateFormat(
      "MMM dd, yyyy",
    ).parse(goal['savingsGoalCreatedOn']);

    debugPrint('createdOn:::$createdOn');
    final int daysSoFar = (today.difference(createdOn).inDays).clamp(
      1,
      1000000,
    );

    debugPrint('daysSoFar:::$daysSoFar');

    final double pacePerDay = totalTrxSaved / daysSoFar;
    final DateTime? etaDate =
        pacePerDay > 0
            ? today.add(Duration(days: (remaining / pacePerDay).ceil()))
            : null;

    return Consumer<ApiProvider>(
      builder: (_, api, __) {
        return Stack(
          children: [
            Scaffold(
              appBar: AppBar(
                title: Text(goal['savingsGoalName']),
                centerTitle: true,
                actions: [
                  IconButton(
                    onPressed: () {
                      DialogUtils.showGenericDialog(
                        context: context,
                        title: DialogUtils.titleText('Delete Goal?', context),
                        message: Text(
                          "Are you sure you want to delete the Goal '${goal['savingsGoalName']}'",
                        ),
                        onCancel: () async {
                          Navigator.of(context).pop();
                          await api
                              .deleteGoal(context, goal['savingsGoalId'])
                              .then((Response resp) {
                                if (resp.statusCode == HttpStatus.ok) {
                                  Toasts.show(
                                    context,
                                    'Goal Deleted',
                                    type: ToastType.success,
                                  );
                                  Navigator.of(context).pop();
                                }
                              });
                        },
                        cancelText: 'Delete',
                        confirmColor: Colors.red,
                        confirmText: 'Cancel',
                        showCancel: true,
                        onConfirm: () => Navigator.pop(context),
                      );
                    },
                    icon: Icon(Icons.delete),
                  ),
                ],
                actionsPadding: EdgeInsets.symmetric(horizontal: 5.0),
              ),
              body: ListView(
                padding: const EdgeInsets.all(15),
                children: [
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
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
                                              child:
                                                  CupertinoActivityIndicator(),
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
                                      goal['savingsGoalName'] ?? '-',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    Text(
                                      'Target by ${formatDateString(goal['savingsGoalTargetDate'] ?? '', pattern: 'dd MMM yyyy')}',
                                      style: theme.textTheme.labelSmall,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                iconSize: 20.0,
                                onPressed: () async {
                                  final updatedGoal = await Navigator.of(
                                    context,
                                  ).push(
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              CreateSavingsGoalPage(goal: goal),
                                    ),
                                  );
                                  debugPrint('updatedGoal:::$updatedGoal');
                                  if (updatedGoal != null) {
                                    goal = updatedGoal;

                                    api.savingsGoalList.removeWhere(
                                      (thisGoal) =>
                                          thisGoal['savingsGoalId'] ==
                                          updatedGoal['savingsGoalId'],
                                    );
                                    api.savingsGoalList.add(updatedGoal);
                                    setState(() {});
                                  }
                                },
                                icon: Icon(Icons.edit_outlined),
                                style: IconButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  backgroundColor:
                                      Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainerHighest,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 8,
                              color: primary,
                              backgroundColor: theme.colorScheme.onSurface
                                  .withOpacity(0.08),
                            ),
                          ),
                          const SizedBox(height: 8),
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
                                'Target: ${formatCurrency(target, context)}',
                                style: theme.textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'What it takes to hit your goal',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 135,
                            child: PageView(
                              controller: _metricsController,
                              onPageChanged:
                                  (i) => setState(() => _metricsIndex = i),
                              physics: const BouncingScrollPhysics(),
                              children: [
                                _metricCard(
                                  context,
                                  title: 'Remaining',
                                  value: formatCurrency(remaining, context),
                                  hint: 'Left to reach your target',
                                  color: Colors.deepPurple,
                                  icon: Icons.flag_outlined,
                                ),
                                _metricCard(
                                  context,
                                  title: 'Days left',
                                  value: daysLeft >= 0 ? '$daysLeft' : '0',
                                  hint:
                                      'Until ${formatDateString(targetDate.toString(), pattern: 'dd MMM')}',
                                  color: Colors.orange,
                                  icon: Icons.calendar_today,
                                ),
                                _metricCard(
                                  context,
                                  title: 'Required/month',
                                  value: formatCurrency(
                                    requiredPerMonth,
                                    context,
                                  ),
                                  hint: 'Monthly to stay on track',
                                  color: Colors.blue,
                                  icon: Icons.trending_up,
                                ),
                                _metricCard(
                                  context,
                                  title: 'Pace/day',
                                  value: formatCurrency(pacePerDay, context),
                                  hint: 'Your current daily pace',
                                  color: Colors.green,
                                  icon: Icons.bolt_outlined,
                                ),
                                _metricCard(
                                  context,
                                  title: 'ETA',
                                  value:
                                      etaDate == null
                                          ? '-'
                                          : formatDateString(
                                            etaDate.toString(),
                                            pattern: 'dd MMM yyyy',
                                          ),
                                  hint: 'If you keep this pace',
                                  color: primary,
                                  icon: Icons.schedule_outlined,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(5, (i) {
                                final bool active = _metricsIndex == i;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  height: 8,
                                  width: 8,
                                  decoration: BoxDecoration(
                                    color:
                                        active
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.onSurface
                                                .withOpacity(0.25),
                                    shape: BoxShape.circle,
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Transactions',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  //const SizedBox(height: 8),
                  if (trxs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      child: Center(
                        child: Text(
                          'No transactions yet',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: trxs.length,
                      //separatorBuilder: (_, __) => const Divider(height: 10),
                      itemBuilder: (context, index) {
                        final t = trxs[index];
                        return Dismissible(
                          key: UniqueKey(),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: const [
                                Icon(Icons.delete, color: Colors.white),
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
                                    'Delete Transaction?',
                                    context,
                                  ),
                                  message: const Text(
                                    'Are you sure you want to delete this transaction?',
                                  ),
                                  onConfirm: () {
                                    Navigator.of(context).pop(true);
                                  },
                                  onCancel:
                                      () => Navigator.of(context).pop(false),
                                  showCancel: true,
                                  cancelText: 'Cancel',
                                  confirmText: 'Delete',
                                  confirmColor: Colors.red,
                                );
                            return shouldDelete ?? false;
                          },
                          onDismissed: (direction) async {
                            setState(() {
                              trxs.removeAt(index);
                            });

                            ApiProvider api = Provider.of<ApiProvider>(
                              context,
                              listen: false,
                            );
                            goal['savingsGoalTransactions'] = trxs;

                            api.updateGoal(context, goal).then((Response resp) {
                              if (resp.statusCode == HttpStatus.ok) {
                                var index = api.savingsGoalList.indexWhere(
                                  (element) =>
                                      element['savingsGoalId'] ==
                                      goal['savingsGoalId'],
                                );

                                api.savingsGoalList[index] = resp.data;
                                debugPrint('resp.data:::${resp.data}');
                                setState(() {
                                  goal = resp.data;
                                });
                                Toasts.show(
                                  context,
                                  'Transaction deleted',
                                  type: ToastType.success,
                                );
                              }
                            });
                          },
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4,
                            ),
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundColor:
                                  theme.colorScheme.surfaceContainerHigh,
                              child: const Icon(Icons.add, size: 18),
                            ),
                            title: Text(t['savingsGoalTrxName'] ?? '-'),
                            subtitle: Text(
                              t['savingsGoalTrxCreatedOn'],
                              style: theme.textTheme.labelMedium!.copyWith(
                                color: Colors.grey.shade700,
                              ),
                            ),
                            trailing: Text(
                              formatCurrency(
                                (t['savingsGoalTrxAmount'] as num? ?? 0)
                                    .toDouble(),
                                context,
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 80),
                ],
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () async {
                  unfocusKeyboard();
                  _showTopUpDialog(context, goal);
                },
                icon: Icon(FontAwesomeIcons.moneyBills, size: 22.5),
                extendedIconLabelSpacing: 15.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                label: Text(
                  'Add Transaction',
                  style: TextStyle(
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (api.isAPILoading) buildLoadingContainer(context: context),
          ],
        );
      },
    );
  }

  Widget _metricCard(
    BuildContext context, {
    required String title,
    required String value,
    required String hint,
    required Color color,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final bg = theme.colorScheme.onSurface.withOpacity(0.035);
    return Padding(
      padding: const EdgeInsets.only(right: 10.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(colors: [bg, bg]),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: theme.textTheme.labelSmall),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.textTheme.labelSmall?.color?.withOpacity(
                        0.8,
                      ),
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
      title: DialogUtils.titleText('Top-up', context),
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
                textCapitalization: TextCapitalization.sentences,
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
              setState(() {
                debugPrint('resp.add:::${resp.data}');
                this.goal = resp.data;
              });
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
