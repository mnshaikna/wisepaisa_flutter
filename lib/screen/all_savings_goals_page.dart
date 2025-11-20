import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:wisepaise/models/savings_goal_transaction.dart';
import 'package:wisepaise/providers/settings_provider.dart';
import 'package:wisepaise/utils/dialog_utils.dart';
import '../providers/api_provider.dart';
import '../utils/toast.dart';
import '../utils/utils.dart';
import 'create_savings_goal_page.dart';
import 'savings_goal_details_page.dart';

class AllSavingsGoalsPage extends StatefulWidget {
  AllSavingsGoalsPage({super.key});

  @override
  State<AllSavingsGoalsPage> createState() => _AllSavingsGoalsPageState();
}

class _AllSavingsGoalsPageState extends State<AllSavingsGoalsPage> {
  TextEditingController nameController = TextEditingController();

  TextEditingController amountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<ApiProvider>(
      builder: (_, api, __) {
        return api.isAPILoading
            ? buildLoadingContainer(context: context)
            : Scaffold(
              appBar: AppBar(
                title: Text(
                  'Saving Goals',
                  style: theme.textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                centerTitle: true,
              ),
              body:
                  (api.savingsGoalList.isEmpty)
                      ? Center(
                        child: noDataWidget(
                          'Goals not found',
                          'Create a goal and be on target',
                          context,
                        ),
                      )
                      : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: api.savingsGoalList.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final goal = api.savingsGoalList[index];
                          final pct =
                              (goal['savingsGoalCurrentAmount'] /
                                  goal['savingsGoalTargetAmount']);
                          debugPrint('pct:::$pct');
                          final primary =
                              theme.brightness == Brightness.light
                                  ? const Color(0xFF0D47A1)
                                  : theme.colorScheme.primary;

                          return InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder:
                                      (_) => SavingsGoalDetailsPage(goal: goal),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            splashColor:
                                Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                            child: Card(
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
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: primary.withOpacity(
                                                    0.15,
                                                  ),
                                                ),
                                              ),
                                              child: Icon(
                                                Icons.savings_outlined,
                                              ),
                                            )
                                            : SizedBox(
                                              width: 45,
                                              height: 45,
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12.0),
                                                child: Image.network(
                                                  goal['savingsGoalImageUrl'],
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
                                                      width: 50,
                                                      height: 50,
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
                                                        fit: BoxFit.contain,
                                                      ),
                                                ),
                                              ),
                                            ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                goal['savingsGoalName'],
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: theme
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                              Text(
                                                'Target: ${formatCurrency(goal['savingsGoalTargetAmount'], context)}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style:
                                                    theme.textTheme.labelSmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          style: IconButton.styleFrom(
                                            backgroundColor:
                                                Theme.of(context)
                                                    .colorScheme
                                                    .surfaceContainerHigh,
                                          ),
                                          onPressed:
                                              () => _showTopUpDialog(
                                                context,
                                                goal,
                                              ),
                                          icon: const Icon(Icons.add),
                                          tooltip: 'Top up',
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
                                        backgroundColor: theme
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.08),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Saved: ${formatCurrency(goal['savingsGoalCurrentAmount'], context)}',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        Text(
                                          formatDateString(
                                            goal['savingsGoalTargetDate'],
                                            pattern: 'dd MMM yyyy',
                                          ),
                                          style: theme.textTheme.labelSmall!
                                              .copyWith(color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CreateSavingsGoalPage(goal: {}),
                    ),
                  );
                },
                icon: const Icon(FontAwesomeIcons.flagCheckered),
                label: Text(
                  'Create a goal',
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            );
      },
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
      title: DialogUtils.titleText('Top-up',context),
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
