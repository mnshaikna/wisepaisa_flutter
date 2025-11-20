import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wisepaise/providers/api_provider.dart';

import '../utils/utils.dart';
import 'create_expense_page.dart';

class AllExpensePage extends StatefulWidget {
  const AllExpensePage({super.key});

  @override
  State<AllExpensePage> createState() => _AllExpensePageState();
}

class _AllExpensePageState extends State<AllExpensePage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<ApiProvider>(
      builder: (_, api, __) {
        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: Text(
              'Expenses',
              style: theme.textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body:
              api.userExpenseList.isEmpty
                  ? Center(
                    child: noDataWidget(
                      'Expenses not found',
                      'Create an Expense and track spends wisely',
                      context,
                    ),
                  )
                  : SingleChildScrollView(
                    physics: BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: buildGroupedExpenseWidgets(
                        api.userExpenseList,
                        context,
                      ),
                    ),
                  ),
          floatingActionButton: FloatingActionButton.extended(
            icon: Icon(Icons.receipt_outlined),
            onPressed:
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (context) => CreateExpensePage(
                          group: {},
                          expense: {},
                          showGroup: true,
                        ),
                  ),
                ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            extendedIconLabelSpacing: 15.0,
            label: Text(
              'Add Expenses',
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
}
