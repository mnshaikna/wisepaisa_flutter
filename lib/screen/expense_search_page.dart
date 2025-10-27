import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:wisepaise/providers/auth_provider.dart';
import 'package:wisepaise/utils/utils.dart';
import '../models/group_model.dart';
import '../models/type_model.dart';
import '../utils/constants.dart';
import '../utils/dialog_utils.dart';
import 'create_expense_page.dart';

class ExpenseSearchPage extends StatefulWidget {
  final GroupModel group;

  const ExpenseSearchPage({super.key, required this.group});

  @override
  State<ExpenseSearchPage> createState() =>
      _ExpenseSearchPageState(group: group);
}

class _ExpenseSearchPageState extends State<ExpenseSearchPage> {
  final GroupModel group;

  _ExpenseSearchPageState({required this.group});

  TextEditingController searchCont = TextEditingController();
  bool isShowHint = false;

  String selectedType = 'all';
  String selectedCategory = 'all';
  String selectedSubCategory = 'all';
  String selectedPayMethod = 'all';

  List<CategoryModel> currentCategories = [];
  List<String> currentSubCategories = [];

  DateTime? startDate, endDate;

  @override
  void initState() {
    super.initState();
    getMinMaxDates();
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

  List getResultList() {
    return group.expenses.where((exp) {
      // 2️⃣ Search text filter (case-insensitive on title & note)
      if (searchCont.text.trim().isNotEmpty) {
        final lowerSearch = searchCont.text.trim().toLowerCase();
        final title = (exp['expenseTitle'] ?? '').toLowerCase();
        final note = (exp['expenseNote'] ?? '').toLowerCase();

        if (!title.contains(lowerSearch) && !note.contains(lowerSearch)) {
          return false;
        }
      }

      // 3️⃣ Category filter
      if (selectedCategory != 'all' && selectedCategory.isNotEmpty) {
        if (exp['expenseCategory'] != selectedCategory) return false;
      }

      // 4️⃣ SubCategory filter
      if (selectedSubCategory != 'all' && selectedSubCategory.isNotEmpty) {
        if (exp['expenseSubCategory'] != selectedSubCategory) {
          return false;
        }
      }

      // 5️⃣ Spend Type filter
      if (selectedType != 'all' && selectedType.isNotEmpty) {
        if (exp['expenseSpendType'] != selectedType) return false;
      }

      // 6️⃣ Payment Method filter
      if (selectedPayMethod != 'all' && selectedPayMethod.isNotEmpty) {
        if (exp['expensePaymentMethod'] != selectedPayMethod) {
          return false;
        }
      }

      // 7️⃣ Date range filter
      if (startDate != null && endDate != null) {
        try {
          final expenseDate = DateTime.parse(exp['expenseDate']);
          if (expenseDate.isBefore(startDate!) ||
              expenseDate.isAfter(endDate!)) {
            return false;
          }
        } catch (e) {
          // If date parsing fails, exclude or handle gracefully
          return false;
        }
      }
      return true;
    }).toList();
  }

  void _showReminderDateRangeSheet(BuildContext context) async {
    DateTimeRange? selectedRange;
    DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      initialDateRange: selectedRange,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: 'Select reminder date range',
      confirmText: 'OK',
      cancelText: 'Cancel',
    );
    ;

    if (pickedRange != null) {
      setState(() {
        startDate = pickedRange.start;
        endDate = pickedRange.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    AuthProvider auth = Provider.of<AuthProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0.0,
        title: Hero(
          tag: 'searchHero',
          child: Padding(
            padding: const EdgeInsets.only(left: 10.0, right: 10.0),
            child: CupertinoSearchTextField(
              controller: searchCont,
              padding: const EdgeInsets.symmetric(
                vertical: 10.0,
                horizontal: 10.0,
              ),
              style: TextStyle(
                letterSpacing: 1.5,
                color: isDark ? Colors.white : Colors.black,
              ),
              keyboardType: TextInputType.text,
              onTap: () => setState(() => isShowHint = true),
              onChanged: (String search) {
                setState(() {});
              },
              onSubmitted: (String search) {
                setState(() {});
              },
              suffixIcon: const Icon(Icons.clear),
              suffixMode: OverlayVisibilityMode.editing,
              placeholder: 'Search expenses...',
              placeholderStyle: TextStyle(
                fontSize: 15.0,
                letterSpacing: 1.5,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 8.0, top: 5.0),
                child: Icon(Icons.search),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            onPressed: () {
              FocusScope.of(context).unfocus();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          SizedBox(width: 5.0),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(90),
          child: Container(
            padding: EdgeInsets.only(left: 10.0, right: 10.0, bottom: 10.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Search Filters',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(8.0),

                      onTap: () {
                        setState(() {
                          selectedType = 'all';
                          selectedCategory = 'all';
                          selectedSubCategory = 'all';
                          selectedPayMethod = 'all';
                          currentCategories = [];
                          currentSubCategories = [];

                          getMinMaxDates();
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Icon(Icons.clear, size: 15.0, color: Colors.blue),
                            SizedBox(width: 5.0),
                            Text(
                              'Reset filters',
                              style: TextStyle(color: Colors.blue),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 5.0),
                  height: 45.0,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.zero,
                    physics: BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        Container(
                          height: 35,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 🗓 Main tappable area
                              InkWell(
                                borderRadius: BorderRadius.circular(5),
                                onTap:
                                    () => _showReminderDateRangeSheet(context),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        FontAwesomeIcons.calendar,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        startDate != null
                                            ? '${formatDate(startDate!)} - ${formatDate(endDate!)}'
                                            : 'Date Range',
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // ❌ Independent clear button
                              if (startDate != null && endDate != null)
                                InkWell(
                                  borderRadius: BorderRadius.circular(5),
                                  onTap: () {
                                    debugPrint('clear');
                                    getMinMaxDates();
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 10,
                                    ),
                                    child: Icon(
                                      Icons.clear,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8.0),
                        SizedBox(
                          height: 35.0,
                          width: 175.0,
                          child: DropdownButtonFormField<String>(
                            value: selectedType,
                            isExpanded: true,
                            decoration: _filterDecoration('Type', context),
                            items: [
                              const DropdownMenuItem(
                                value: 'all',
                                child: Text('All'),
                              ),
                              ...catList.keys.map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        type == 'income'
                                            ? Icons.arrow_upward
                                            : Icons.arrow_downward,
                                        size: 16,
                                        color:
                                            type == 'income'
                                                ? Colors.green
                                                : Colors.red,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          type.capitalize(),
                                          overflow: TextOverflow.ellipsis,
                                          softWrap: true,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                selectedType = value!;
                                selectedCategory = 'all';
                                selectedSubCategory = 'all';
                                currentCategories =
                                    value == 'all' ? [] : catList[value] ?? [];
                                currentSubCategories = [];
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Status Filter
                        SizedBox(
                          height: 35.0,
                          width: 175.0,
                          child: DropdownButtonFormField<String>(
                            value: selectedCategory,
                            isExpanded: true,
                            decoration: _filterDecoration('Category', context),
                            items: [
                              const DropdownMenuItem(
                                value: 'all',
                                child: Text('All'),
                              ),
                              ...currentCategories.map(
                                (cat) => DropdownMenuItem(
                                  value: cat.cat,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(cat.icon, size: 16),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          cat.cat.capitalize(),
                                          overflow: TextOverflow.ellipsis,
                                          softWrap: true,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                selectedCategory = value!;
                                selectedSubCategory = 'all';
                                if (value != 'all') {
                                  currentSubCategories =
                                      currentCategories
                                          .firstWhere((cat) => cat.cat == value)
                                          .subCat;
                                } else {
                                  currentSubCategories = [];
                                }
                              });
                            },
                          ),
                        ),

                        const SizedBox(width: 8),

                        SizedBox(
                          height: 35.0,
                          width: 175.0,
                          child: DropdownButtonFormField<String>(
                            value: selectedSubCategory,
                            isExpanded: true,
                            decoration: _filterDecoration(
                              'Subcategory',
                              context,
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: 'all',
                                child: Text('All'),
                              ),
                              ...currentSubCategories.map(
                                (sub) => DropdownMenuItem(
                                  value: sub,
                                  child: Text(
                                    sub.capitalize(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                selectedSubCategory = value!;
                              });
                            },
                          ),
                        ),

                        const SizedBox(width: 8),

                        SizedBox(
                          height: 35.0,
                          width: 175.0,
                          child: DropdownButtonFormField<String>(
                            value: selectedPayMethod,
                            isExpanded: true,
                            decoration: _filterDecoration(
                              'Payment Method',
                              context,
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: 'all',
                                child: Text('All'),
                              ),
                              ...payMethodList.map(
                                (pay) => DropdownMenuItem(
                                  value: pay.payMethod,
                                  child: Row(
                                    children: [
                                      Icon(pay.icon, size: 16),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          pay.payMethod.capitalize(),
                                          overflow: TextOverflow.ellipsis,
                                          softWrap: true,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            onChanged:
                                (v) => setState(() => selectedPayMethod = v!),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body:
          getResultList().isEmpty
              ? Center(
                child: noDataWidget(
                  'No Matching Results',
                  'Change the filter criteria to view data',
                  context,
                ),
              )
              : ListView(
                padding: EdgeInsets.all(5.0),
                physics: BouncingScrollPhysics(),
                children:
                    getResultList().map((expense) {
                      String payStatus = getPayStatus(expense, context);
                      debugPrint('payStatus:::$payStatus');
                      return ListTile(
                        onTap: () {
                          DialogUtils.showGenericDialog(
                            context: context,
                            showCancel: true,
                            onConfirm: () {
                              Navigator.pop(context);
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder:
                                      (context) => CreateExpensePage(
                                        group: {},
                                        expense: expense,
                                      ),
                                ),
                              );
                            },
                            onCancel: () => Navigator.pop(context),

                            confirmColor: Colors.green,
                            cancelText: 'Cancel',
                            confirmText: 'Edit',
                            title: SizedBox.shrink(),
                            message: SizedBox(
                              child: expenseCard(context, expense),
                            ),
                          );
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        splashColor: Colors.grey.shade100,
                        contentPadding: EdgeInsets.symmetric(horizontal: 5.0),
                        leading: Card(
                          elevation: 0.0,
                          margin: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Container(
                            padding: EdgeInsets.all(4.0),
                            decoration: BoxDecoration(shape: BoxShape.circle),
                            height: 65.0,
                            width: 65.0,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
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
                                    fontWeight: FontWeight.bold,
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
                          group.exGroupShared
                              ? '${expense['expensePaidBy']['userId'] == auth.user!.id ? 'You' : expense['expensePaidBy']['userName']} paid ${formatCurrency(expense['expenseAmount'], context)}'
                              : '${expense['expenseCategory']} | ${expense['expenseSubCategory']}',
                          style: TextStyle(fontSize: 12.5),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            group.exGroupShared
                                ? Text(
                                  payStatus,
                                  style: TextStyle(
                                    letterSpacing: 1.5,
                                    color:
                                        payStatus == 'not involved' ||
                                                payStatus == 'no balance'
                                            ? Colors.grey
                                            : payStatus == 'you borrowed'
                                            ? Colors.red
                                            : Colors.green,
                                  ),
                                )
                                : SizedBox.shrink(),
                            group.exGroupShared &&
                                    (payStatus == 'not involved' ||
                                        payStatus == 'no balance')
                                ? SizedBox.shrink()
                                : Text(
                                  formatCurrency(
                                    expense['expenseAmount'],
                                    context,
                                  ),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                    fontSize: 13.5,
                                    color:
                                        expense['expenseSpendType'] == 'income'
                                            ? Colors.green
                                            : Colors.red,
                                  ),
                                ),
                          ],
                        ),
                      );
                    }).toList(),
              ),
    );
  }

  InputDecoration _filterDecoration(String label, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: label,
      filled: true,
      isDense: true,
      fillColor: isDark ? Colors.black54 : Colors.white54,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      border: outlineInputBorder(isDark),
      focusedBorder: outlineInputBorder(isDark),
      enabledBorder: outlineInputBorder(isDark),
    );
  }

  OutlineInputBorder outlineInputBorder(bool isDark) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(5.0),
      borderSide: BorderSide(
        color: isDark ? Colors.white54 : Colors.black54,
        width: 0.1,
      ),
    );
  }
}

extension StringExtn on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1).toLowerCase()}";
  }
}
