import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:wisepaise/models/expense_model.dart';
import 'package:wisepaise/providers/api_provider.dart';
import 'package:wisepaise/providers/auth_provider.dart';
import 'package:wisepaise/providers/settings_provider.dart';
import 'package:wisepaise/utils/calculator_bottom_sheet.dart';
import 'package:wisepaise/utils/constants.dart';
import 'package:wisepaise/utils/utils.dart';

import '../models/type_model.dart';
import '../models/user_model.dart';
import '../utils/toast.dart';
import 'home_page.dart';
import 'package:flutter/cupertino.dart';

class CreateExpensePage extends StatefulWidget {
  Map<String, dynamic> group;
  Map<String, dynamic> expense;
  bool showGroup;

  CreateExpensePage({
    super.key,
    required this.expense,
    required this.group,
    this.showGroup = false,
  });

  @override
  State<CreateExpensePage> createState() => _CreateExpensePageState(
    group: group,
    expense: expense,
    showGroup: showGroup,
  );
}

class _CreateExpensePageState extends State<CreateExpensePage> {
  Map<String, dynamic> group;
  Map<String, dynamic> expense;
  bool showGroup;
  Uint8List? imageBytes;

  _CreateExpensePageState({
    required this.group,
    required this.expense,
    this.showGroup = false,
  });

  bool isExpense = true;
  TextEditingController dateController = TextEditingController(),
      descController = TextEditingController(),
      amountController = TextEditingController(),
      expenseNote = TextEditingController();
  dynamic paidBy;
  CategoryModel? selectedCategory;
  PaymentMethodModel? payMethod;
  String? subCategoryValue;
  final Set<dynamic> paidTo = {};
  Map<String, dynamic> selectedGroup = {};
  dynamic members;

  @override
  void initState() {
    super.initState();
    if (group.isNotEmpty) {
      dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
      members = (group['exGroupMembers'] ?? []).toList();
    }
    debugPrint('members:::${members.toString()}');
    if (expense.isNotEmpty) {
      descController.text = expense['expenseTitle'];
      amountController.text = expense['expenseAmount'].toString();
      expenseNote.text = expense['expenseNote'];
      dateController.text = expense['expenseDate'];
      isExpense = expense['expenseSpendType'] == 'expense';
      selectedCategory = catList[isExpense ? 'expense' : 'income']!.firstWhere(
        (cat) => cat.cat == expense['expenseCategory'],
      );
      subCategoryValue = catList[isExpense ? 'expense' : 'income']!
          .firstWhere((cat) => cat.cat == expense['expenseCategory'])
          .subCat
          .firstWhere((str) => str == expense['expenseSubCategory']);

      payMethod = payMethodList.firstWhere(
        (pay) => pay.payMethod == expense['expensePaymentMethod'],
      );
    }
    if (group.isEmpty && expense.isEmpty) {
      dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    }
  }

  UserModel getUser() {
    AuthProvider auth = Provider.of(context, listen: false);
    return UserModel(
      userId: auth.thisUser!['userId'],
      userName: auth.thisUser!['userName'],
      userEmail: auth.thisUser!['userEmail'],
      userImageUrl: auth.thisUser!['userImageUrl'],
      userCreatedOn: auth.thisUser!['userCreatedOn'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ApiProvider>(
      builder: (_, api, __) {
        return Consumer<SettingsProvider>(
          builder: (_, set, __) {
            return Stack(
              children: [
                Scaffold(
                  appBar: AppBar(
                    centerTitle: true,
                    title: Text(
                      group.isNotEmpty
                          ? group['exGroupName']
                          : expense.isNotEmpty
                          ? "Edit Expense"
                          : 'Add Expense',
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  body: Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15.0,
                            vertical: 0.0,
                          ),
                          child: SingleChildScrollView(
                            physics: BouncingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (group.isEmpty || !group['exGroupShared'])
                                  SizedBox(height: 10.0),
                                if (group.isEmpty || !group['exGroupShared'])
                                  Card(
                                    elevation: 0.0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  isExpense = true;
                                                  selectedCategory = null;
                                                  subCategoryValue = null;
                                                });
                                              },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 14,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      isExpense
                                                          ? Colors.red
                                                          : Colors.transparent,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.arrow_downward,
                                                      color:
                                                          !isExpense
                                                              ? Colors
                                                                  .grey
                                                                  .shade700
                                                              : Colors.black,
                                                    ),
                                                    Text(
                                                      "Expense",
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            !isExpense
                                                                ? Colors
                                                                    .grey
                                                                    .shade700
                                                                : Colors.black,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  isExpense = false;
                                                  selectedCategory = null;
                                                  subCategoryValue = null;
                                                });
                                              },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 14,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      !isExpense
                                                          ? Colors.green
                                                          : Colors.transparent,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.arrow_upward,
                                                      color:
                                                          isExpense
                                                              ? Colors
                                                                  .grey
                                                                  .shade700
                                                              : Colors.black,
                                                    ),
                                                    Text(
                                                      "Income",
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            isExpense
                                                                ? Colors
                                                                    .grey
                                                                    .shade700
                                                                : Colors.black,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 16),
                                // Amount field
                                TextField(
                                  controller: amountController,
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(
                                      isExpense ? Icons.remove : Icons.add,
                                      color:
                                          isExpense ? Colors.red : Colors.green,
                                    ),
                                    suffixIcon: IconButton(
                                      onPressed:
                                          () => _openCalculatorBottomSheet(),
                                      icon: Icon(Icons.calculate_outlined),
                                    ),
                                    hintText: set.currency,
                                    labelText: 'Amount',
                                    labelStyle: labelStyle(context),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.next,
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: descController,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  keyboardType: TextInputType.text,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    labelText: "Enter a Desc",
                                    labelStyle: labelStyle(context),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  maxLines: 1,
                                ),

                                const SizedBox(height: 16),
                                TextField(
                                  controller: dateController,
                                  readOnly: true,
                                  onTap:
                                      () => _showBottomSheetCalendar(context),
                                  decoration: InputDecoration(
                                    labelText: "Date",
                                    labelStyle: labelStyle(context),
                                    suffixIcon: IconButton(
                                      onPressed:
                                          () =>
                                              _showBottomSheetCalendar(context),
                                      icon: Icon(Icons.calendar_today),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 2.5),
                                SizedBox(
                                  height: 40.0,
                                  child: ListView(
                                    physics: BouncingScrollPhysics(),
                                    scrollDirection: Axis.horizontal,
                                    children: [
                                      buildPresetChip(
                                        'Today',
                                        Icon(Icons.today, size: 17.5),
                                        () =>
                                            dateController.text = formatDate(
                                              DateTime.now(),
                                              pattern: 'yyyy-MM-dd',
                                            ),
                                      ),
                                      buildPresetChip(
                                        'Yesterday',
                                        Icon(
                                          Icons.calendar_today_sharp,
                                          size: 17.5,
                                        ),
                                        () =>
                                            dateController.text = formatDate(
                                              DateTime.now().subtract(
                                                Duration(days: 1),
                                              ),
                                              pattern: 'yyyy-MM-dd',
                                            ),
                                      ),
                                      buildPresetChip(
                                        'This week Monday',
                                        Icon(
                                          Icons.calendar_view_week,
                                          size: 17.5,
                                        ),
                                        () =>
                                            dateController.text = formatDate(
                                              getMondayOfCurrentWeek(),
                                              pattern: 'yyyy-MM-dd',
                                            ),
                                      ),
                                      buildPresetChip(
                                        '1st ${month[DateTime.now().month - 1]}',
                                        Icon(Icons.calendar_month, size: 17.5),
                                        () =>
                                            dateController.text = formatDate(
                                              getFirstDayOfCurrentMonth(),
                                              pattern: 'yyyy-MM-dd',
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    // Category Dropdown
                                    Expanded(
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxWidth: 250,
                                        ),
                                        child: DropdownButtonFormField<
                                          CategoryModel
                                        >(
                                          borderRadius: BorderRadius.circular(
                                            8.0,
                                          ),
                                          decoration: InputDecoration(
                                            labelText: "Category",
                                            labelStyle: labelStyle(context),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          value: selectedCategory,
                                          isExpanded: true,
                                          menuMaxHeight: 250.0,

                                          // 🔑 Choose expense or income list
                                          items:
                                              (isExpense
                                                      ? catList["expense"]!
                                                      : catList["income"]!)
                                                  .map((cat) {
                                                    return DropdownMenuItem<
                                                      CategoryModel
                                                    >(
                                                      value: cat,
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 4,
                                                            ),
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                              cat.icon,
                                                              size: 20,
                                                              color:
                                                                  Colors
                                                                      .blueAccent,
                                                            ),
                                                            const SizedBox(
                                                              width: 15,
                                                            ),
                                                            Expanded(
                                                              child: Text(
                                                                cat.cat,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                softWrap: true,
                                                                maxLines: 1,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  })
                                                  .toList(),

                                          // 👇 Control how selected item is displayed
                                          selectedItemBuilder: (context) {
                                            return (isExpense
                                                    ? catList["expense"]!
                                                    : catList["income"]!)
                                                .map((cat) {
                                                  return Row(
                                                    children: [
                                                      Icon(
                                                        cat.icon,
                                                        size: 20,
                                                        color:
                                                            Colors.blueAccent,
                                                      ),
                                                      const SizedBox(width: 15),
                                                      Expanded(
                                                        child: Text(
                                                          cat.cat,
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                          maxLines: 1,
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                })
                                                .toList();
                                          },

                                          onChanged: (CategoryModel? val) {
                                            setState(() {
                                              selectedCategory = val;
                                              subCategoryValue = null;
                                            });
                                          },
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 12),

                                    // SubCategory Dropdown (depends on selectedCategory)
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        borderRadius: BorderRadius.circular(
                                          8.0,
                                        ),
                                        decoration: InputDecoration(
                                          labelText: "Sub-Category",
                                          labelStyle: labelStyle(context),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        isExpanded: true,
                                        menuMaxHeight: 250.0,
                                        value: subCategoryValue,
                                        items:
                                            (selectedCategory?.subCat ?? [])
                                                .map((sub) {
                                                  return DropdownMenuItem<
                                                    String
                                                  >(
                                                    value: sub,
                                                    child: Text(
                                                      sub,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      softWrap: true,
                                                      maxLines: 1,
                                                    ),
                                                  );
                                                })
                                                .toList(),
                                        onChanged: (String? val) {
                                          setState(() {
                                            subCategoryValue = val;
                                            debugPrint(
                                              'Dropdown Value::: $subCategoryValue',
                                            );
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),
                                ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: 250),
                                  child: DropdownButtonFormField<
                                    PaymentMethodModel
                                  >(
                                    borderRadius: BorderRadius.circular(8.0),
                                    decoration: InputDecoration(
                                      labelText: "Payment Method",
                                      labelStyle: labelStyle(context),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    value: payMethod,
                                    isExpanded: true,
                                    menuMaxHeight: 250.0,
                                    items:
                                        payMethodList.map((pay) {
                                          return DropdownMenuItem<
                                            PaymentMethodModel
                                          >(
                                            value: pay,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      8,
                                                    ), // rounded corners
                                              ),
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 4,
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    pay.icon,
                                                    size: 20,
                                                    color: Colors.blueAccent,
                                                  ),
                                                  SizedBox(width: 15),
                                                  Text(pay.payMethod),
                                                  // here it’s okay if long
                                                ],
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                    // 👇 This controls how selected item is shown
                                    selectedItemBuilder: (context) {
                                      return payMethodList.map((pay) {
                                        return Row(
                                          children: [
                                            Icon(
                                              pay.icon,
                                              size: 20,
                                              color: Colors.blueAccent,
                                            ),
                                            SizedBox(width: 15),
                                            Expanded(
                                              child: Text(
                                                pay.payMethod,
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList();
                                    },
                                    onChanged: (PaymentMethodModel? val) {
                                      setState(() {
                                        payMethod = val;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: expenseNote,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  decoration: InputDecoration(
                                    labelText: "Write a note (Optional)",
                                    labelStyle: labelStyle(context),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 16),
                                imageBytes == null &&
                                        (expense['expenseReceiptURL'] == null ||
                                            expense['expenseReceiptURL']
                                                .isEmpty)
                                    ? buildCreateDataBox(
                                      shrinkHeight: true,
                                      context,
                                      "➕ Tap to add attachment",
                                      () {
                                        _showAttachmentOptions(context);
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
                                    : GestureDetector(
                                      onTap:
                                          () => _showAttachmentOptions(context),
                                      child: Container(
                                        height: 250.0,
                                        width: double.infinity,
                                        padding: EdgeInsets.all(0.0),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            12.0,
                                          ),
                                          border: Border.all(
                                            width: 1.0,
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.light
                                                    ? Colors.black54
                                                    : Colors.white54,
                                            style:
                                                imageBytes != null ||
                                                        expense['expenseReceiptURL']
                                                            .toString()
                                                            .isNotEmpty
                                                    ? BorderStyle.none
                                                    : BorderStyle.solid,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12.0,
                                          ),
                                          child:
                                              expense['expenseReceiptURL'] !=
                                                          null &&
                                                      expense['expenseReceiptURL']
                                                          .isNotEmpty
                                                  ? Image.network(
                                                    expense['expenseReceiptURL'],
                                                    fit: BoxFit.cover,
                                                  )
                                                  : Image.memory(
                                                    imageBytes as Uint8List,
                                                    fit: BoxFit.cover,
                                                  ),
                                        ),
                                      ),
                                    ),
                                if (group.isNotEmpty)
                                  const SizedBox(height: 16),
                                if (group.isNotEmpty && members.length > 1)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Paid By Section (Single Select)
                                      Text(
                                        "Paid By",
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge!.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 10.0,
                                        runSpacing: 10.0,
                                        children:
                                            members.map<Widget>((name) {
                                              final isSelected = paidBy == name;
                                              return GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    paidBy = name;
                                                  });
                                                },
                                                child: SizedBox(
                                                  width: 75.0,
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      CircleAvatar(
                                                        radius: 20,
                                                        backgroundColor:
                                                            isSelected
                                                                ? Colors.green
                                                                : Colors
                                                                    .grey
                                                                    .shade300,
                                                        backgroundImage:
                                                            NetworkImage(
                                                              name['userImageUrl'],
                                                            ),
                                                      ),
                                                      const SizedBox(height: 5),
                                                      Text(
                                                        name['userName'],
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: Theme.of(
                                                          context,
                                                        ).textTheme.bodySmall!.copyWith(
                                                          fontWeight:
                                                              isSelected
                                                                  ? FontWeight
                                                                      .bold
                                                                  : FontWeight
                                                                      .normal,
                                                          color:
                                                              isSelected
                                                                  ? Colors.green
                                                                  : Theme.of(
                                                                        context,
                                                                      ).brightness ==
                                                                      Brightness
                                                                          .light
                                                                  ? Colors.black
                                                                  : Colors
                                                                      .white,
                                                        ),
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                        maxLines: 2,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                      ),
                                      const SizedBox(height: 15),
                                      Text(
                                        "Paid To",
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge!.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Column(
                                        children:
                                            members.map<Widget>((name) {
                                              final isSelected = paidTo
                                                  .contains(name);
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 2.5,
                                                    ),
                                                child: ListTile(
                                                  style: ListTileStyle.drawer,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8.0,
                                                        ),
                                                  ),
                                                  selected: isSelected,
                                                  selectedColor:
                                                      Theme.of(
                                                                context,
                                                              ).brightness ==
                                                              Brightness.dark
                                                          ? Colors.white
                                                          : Colors.black,
                                                  selectedTileColor:
                                                      Theme.of(
                                                                context,
                                                              ).brightness ==
                                                              Brightness.dark
                                                          ? Colors.grey[800]
                                                          : Colors.grey[300],
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                        horizontal: 5.0,
                                                      ),
                                                  onTap:
                                                      () => setState(
                                                        () =>
                                                            isSelected
                                                                ? paidTo.remove(
                                                                  name,
                                                                )
                                                                : paidTo.add(
                                                                  name,
                                                                ),
                                                      ),
                                                  leading: CircleAvatar(
                                                    backgroundImage:
                                                        NetworkImage(
                                                          name['userImageUrl'],
                                                        ),
                                                  ),
                                                  title: Text(
                                                    name['userName'],
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium!
                                                        .copyWith(
                                                          fontWeight:
                                                              isSelected
                                                                  ? FontWeight
                                                                      .bold
                                                                  : FontWeight
                                                                      .normal,
                                                        ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 2,
                                                  ),
                                                  trailing:
                                                      isSelected
                                                          ? Icon(
                                                            Icons.check,
                                                            size: 20.0,
                                                          )
                                                          : SizedBox.shrink(),
                                                ),
                                              );
                                            }).toList(),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed:
                                    group.isEmpty || showGroup
                                        ? () => _showGroupSheet(context)
                                        : null,
                                style: TextButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  textStyle: Theme.of(
                                    context,
                                  ).textTheme.bodySmall!.copyWith(
                                    letterSpacing: 1.25,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 5.0,
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        height: 25.0,
                                        width: 25.0,
                                        child:
                                            selectedGroup['exGroupImageURL'] !=
                                                        null ||
                                                    group['exGroupImageURL'] !=
                                                        null
                                                ? ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        12.0,
                                                      ),
                                                  child: Image.network(
                                                    (group['exGroupImageURL'] !=
                                                            null)
                                                        ? group['exGroupImageURL']
                                                        : selectedGroup['exGroupImageURL'],
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
                                                        child: Center(
                                                          child:
                                                              CupertinoActivityIndicator(),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                )
                                                : Image.asset(
                                                  Theme.of(
                                                            context,
                                                          ).brightness ==
                                                          Brightness.light
                                                      ? 'assets/logos/logo_light.png'
                                                      : 'assets/logos/logo_dark.png',
                                                  fit: BoxFit.contain,
                                                ),
                                      ),
                                      SizedBox(width: 5.0),
                                      Expanded(
                                        child: Text(
                                          group.isNotEmpty
                                              ? group['exGroupName']
                                              : selectedGroup['exGroupName'] ??
                                                  'non-grouped expenses',
                                          overflow: TextOverflow.ellipsis,
                                          softWrap: true,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 5.0),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  String url = "";
                                  if (validateForm()) {
                                    if (group.isNotEmpty) {
                                      if (members.length == 1) {
                                        AuthProvider auth =
                                            Provider.of<AuthProvider>(
                                              context,
                                              listen: false,
                                            );
                                        paidBy = getUser();
                                        paidTo.add(getUser());
                                      }
                                      if (imageBytes != null) {
                                        url = await uploadImage(
                                          imageBytes!,
                                          '${Random().nextInt(1000000)}',
                                          context,
                                        );
                                      }
                                      ExpenseModel expense = ExpenseModel(
                                        expenseId:
                                            this.expense['expenseId'] != null &&
                                                    this
                                                        .expense['expenseId']
                                                        .isNotEmpty
                                                ? this.expense['expenseId']
                                                : Random()
                                                    .nextInt(9999999)
                                                    .toString(),
                                        expenseTitle:
                                            descController.text.trim(),
                                        expenseNote: expenseNote.text.trim(),
                                        expenseAmount: double.parse(
                                          amountController.text.trim(),
                                        ),
                                        expenseSpendType:
                                            isExpense ? 'expense' : 'income',
                                        expenseDate: dateController.text.trim(),
                                        expensePaidTo:
                                            paidTo.toList().isEmpty
                                                ? [getUser().toJson()]
                                                : paidTo.toList(),
                                        expenseCategory:
                                            selectedCategory!.cat.toString(),
                                        expenseSubCategory:
                                            subCategoryValue.toString(),
                                        expensePaymentMethod:
                                            payMethod!.payMethod.toString(),
                                        expensePaidBy:
                                            paidBy ?? getUser().toJson(),
                                        expenseReceiptURL:
                                            url.isNotEmpty ? url : '',
                                        expenseUserId: UserModel.empty(),
                                      );
                                      List<dynamic> expenses =
                                          group['expenses'] ?? [];

                                      if (this.expense.isNotEmpty) {
                                        expenses.removeWhere(
                                          (exp) =>
                                              exp['expenseId'] ==
                                              this.expense['expenseId'],
                                        );
                                      }
                                      expenses.add(expense.toJson());
                                      debugPrint(
                                        'Expense Data:::${expense.toJson().toString()}',
                                      );
                                      group['expenses'] = expenses;

                                      await api.updateGroup(context, group).then((
                                        Response resp,
                                      ) {
                                        debugPrint(resp.statusCode.toString());
                                        if (resp.statusCode == 200) {
                                          Toasts.show(
                                            context,
                                            this.expense.isNotEmpty
                                                ? 'Expense successfully updated'
                                                : 'Expense successfully added',
                                            type: ToastType.success,
                                          );
                                          api.groupList.removeWhere(
                                            (element) =>
                                                element['exGroupId'] ==
                                                group['exGroupId'],
                                          );
                                          api.groupList.add(resp.data);
                                          Navigator.pop(context, resp.data);
                                        }
                                      });
                                    } else {
                                      if (expense.isNotEmpty) {
                                        debugPrint('Edit User Expense');
                                        AuthProvider auth =
                                            Provider.of<AuthProvider>(
                                              context,
                                              listen: false,
                                            );
                                        paidBy = getUser();
                                        paidTo.add(getUser());

                                        if (imageBytes != null) {
                                          url = await uploadImage(
                                            imageBytes!,
                                            '${Random().nextInt(1000000)}',
                                            context,
                                          );
                                        }

                                        ExpenseModel expense = ExpenseModel(
                                          expenseId: this.expense['expenseId'],
                                          expenseTitle:
                                              descController.text.trim(),
                                          expenseNote: expenseNote.text.trim(),
                                          expenseAmount: double.parse(
                                            amountController.text.trim(),
                                          ),
                                          expenseSpendType:
                                              isExpense ? 'expense' : 'income',
                                          expenseDate:
                                              dateController.text.trim(),
                                          expensePaidTo:
                                              paidTo.toList().isEmpty
                                                  ? [getUser().toJson()]
                                                  : paidTo.toList(),
                                          expenseCategory:
                                              selectedCategory!.cat.toString(),
                                          expenseSubCategory:
                                              subCategoryValue.toString(),
                                          expensePaymentMethod:
                                              payMethod!.payMethod.toString(),
                                          expensePaidBy:
                                              paidBy ?? getUser().toJson(),
                                          expenseReceiptURL:
                                              url.isNotEmpty ? url : '',
                                          expenseUserId: getUser(),
                                        );

                                        debugPrint(
                                          'Edit User Expense Data:::${expense.toJson().toString()}',
                                        );

                                        await api
                                            .updateExpense(
                                              context,
                                              expense.toJson(),
                                            )
                                            .then((Response resp) {
                                              debugPrint(
                                                resp.statusCode.toString(),
                                              );
                                              if (resp.statusCode == 200) {
                                                Toasts.show(
                                                  context,
                                                  'Expense successfully Updated',
                                                  type: ToastType.success,
                                                );

                                                Navigator.pushAndRemoveUntil(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (context) =>
                                                            MyDashboardPage(),
                                                  ),
                                                  (Route<dynamic> route) =>
                                                      false,
                                                );
                                              }
                                            });
                                      } else {
                                        debugPrint('Add Expense');
                                        AuthProvider auth =
                                            Provider.of<AuthProvider>(
                                              context,
                                              listen: false,
                                            );
                                        paidBy = getUser();
                                        paidTo.add(getUser());
                                        if (imageBytes != null) {
                                          url = await uploadImage(
                                            imageBytes!,
                                            '${Random().nextInt(1000000)}',
                                            context,
                                          );
                                        }
                                        ExpenseModel expense = ExpenseModel(
                                          expenseId: '',
                                          expenseTitle:
                                              descController.text.trim(),
                                          expenseNote: expenseNote.text.trim(),
                                          expenseAmount: double.parse(
                                            amountController.text.trim(),
                                          ),
                                          expenseSpendType:
                                              isExpense ? 'expense' : 'income',
                                          expenseDate:
                                              dateController.text.trim(),
                                          expensePaidTo: paidTo.toList(),
                                          expenseCategory:
                                              selectedCategory!.cat.toString(),
                                          expenseSubCategory:
                                              subCategoryValue.toString(),
                                          expensePaymentMethod:
                                              payMethod!.payMethod.toString(),
                                          expensePaidBy: paidBy!,
                                          expenseReceiptURL:
                                              url.isNotEmpty ? url : '',
                                          expenseUserId: getUser(),
                                        );

                                        debugPrint(
                                          'Expense Data:::${expense.toJson().toString()}',
                                        );

                                        await api
                                            .createExpense(
                                              context,
                                              expense.toJson(),
                                            )
                                            .then((Response resp) {
                                              debugPrint(
                                                resp.statusCode.toString(),
                                              );
                                              if (resp.statusCode == 200) {
                                                Toasts.show(
                                                  context,
                                                  'Expense successfully Created',
                                                  type: ToastType.success,
                                                );

                                                Navigator.pushAndRemoveUntil(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (context) =>
                                                            MyDashboardPage(),
                                                  ),
                                                  (Route<dynamic> route) =>
                                                      false,
                                                );
                                              }
                                            });
                                      }
                                    }
                                  }
                                },
                                icon: Icon(
                                  expense.isNotEmpty ? Icons.edit : Icons.check,
                                ),
                                label: Text(
                                  expense.isNotEmpty
                                      ? isExpense
                                          ? 'Edit Expense'
                                          : "Edit Income"
                                      : isExpense
                                      ? 'Add Expense'
                                      : 'Add Income',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 24,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  textStyle: Theme.of(
                                    context,
                                  ).textTheme.titleSmall!.copyWith(
                                    letterSpacing: 1.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (api.isAPILoading) buildLoadingContainer(context: context),
              ],
            );
          },
        );
      },
    );
  }

  Widget buildPresetChip(String label, Icon icon, var onTap) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: InkWell(
        borderRadius: BorderRadius.circular(8.0),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [icon, SizedBox(width: 5.0), Text(label)],
          ),
        ),
      ),
    );
  }

  void _showBottomSheetCalendar(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SizedBox(
          height: 400,
          child: CalendarDatePicker(
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
            onDateChanged: (date) {
              Navigator.of(context).pop();
              dateController.text = DateFormat('yyyy-MM-dd').format(date);
            },
          ),
        );
      },
    );
  }

  void _showAttachmentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Wrap(
              children: [
                Center(
                  child: Container(
                    height: 5.0,
                    width: 50.0,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(10.0),
                        bottomRight: Radius.circular(10.0),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10.0),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  leading: const Icon(Icons.camera_alt, color: Colors.purple),
                  title: const Text("Take a photo"),
                  onTap: () async {
                    Navigator.pop(context);
                    await pickFile(pickType: ImageSource.camera).then((bytes) {
                      setState(() {
                        imageBytes = bytes!;
                      });
                    });
                  },
                ),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  leading: const Icon(Icons.image, color: Colors.green),
                  title: const Text("Choose from gallery"),
                  onTap: () async {
                    Navigator.pop(context);
                    await pickFile(pickType: ImageSource.gallery).then((bytes) {
                      setState(() {
                        imageBytes = bytes!;
                      });
                    });
                  },
                ),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text("Remove Photo"),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      imageBytes = null;
                      expense['expenseReceiptURL'] = '';
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool validateForm() {
    if (descController.text.trim().isEmpty) {
      Toasts.show(context, 'Enter a Desc', type: ToastType.error);
      return false;
    }
    if (amountController.text.trim().isEmpty ||
        amountController.text.trim() == '0') {
      Toasts.show(context, 'Enter amount', type: ToastType.error);
      return false;
    }
    if (dateController.text.trim().isEmpty) {
      Toasts.show(context, 'Choose a date', type: ToastType.error);
      return false;
    }
    if (selectedCategory == null || selectedCategory!.cat.isEmpty) {
      Toasts.show(context, 'Select a category', type: ToastType.error);
      return false;
    }
    if (subCategoryValue == null || subCategoryValue!.isEmpty) {
      Toasts.show(context, 'Select a sub category', type: ToastType.error);
      return false;
    }
    if (payMethod == null || payMethod!.payMethod.isEmpty) {
      Toasts.show(context, 'Select a Payment method', type: ToastType.error);
      return false;
    }
    if ((members != null && members.length > 1) &&
        (paidBy == null || paidBy!['userId'].isEmpty)) {
      Toasts.show(context, 'Select PaidBy', type: ToastType.error);
      return false;
    }
    if (members != null && members.length > 1 && (paidTo.isEmpty)) {
      Toasts.show(context, 'Select PaidTo', type: ToastType.error);
      return false;
    }
    return true;
  }

  Future<void> _openCalculatorBottomSheet() async {
    final result = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const CalculatorBottomSheet(),
    );

    if (result != null) {
      setState(() {
        amountController.text = result.toStringAsFixed(2);
      });
    }
  }

  void _showGroupSheet(BuildContext context) {
    showModalBottomSheet(
      showDragHandle: true,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        ApiProvider api = Provider.of<ApiProvider>(context, listen: false);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Select a Group',
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Divider(height: 1),
              const SizedBox(height: 6),
              Column(
                children: [
                  ListTile(
                    title: Text(
                      'non-grouped expense',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'This expense is not part of any groups',
                      style: Theme.of(context).textTheme.titleSmall!.copyWith(
                        color: Colors.grey.shade500,
                      ),
                    ),
                    leading: Container(
                      height: 50.0,
                      width: 50.0,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Image.asset(
                        Theme.of(context).brightness == Brightness.light
                            ? 'assets/logos/logo_light.png'
                            : 'assets/logos/logo_dark.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        selectedGroup = {};
                        group = selectedGroup;
                        dateController.text = DateFormat(
                          'yyyy-MM-dd',
                        ).format(DateTime.now());
                        members = (group['exGroupMembers'] ?? []).toList();
                      });
                    },
                  ),
                  ...api.groupList.map((grp) {
                    return ListTile(
                      title: Text(
                        grp['exGroupName'],
                        style: Theme.of(context).textTheme.titleMedium!
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        grp['exGroupDesc'],
                        style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          color: Colors.grey.shade500,
                        ),
                      ),
                      leading: Container(
                        height: 50.0,
                        width: 50.0,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child:
                            (grp['exGroupImageURL'] != null)
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12.0),
                                  child: Image.network(
                                    grp['exGroupImageURL'],
                                    fit: BoxFit.cover,
                                    loadingBuilder: (
                                      context,
                                      child,
                                      loadingProgress,
                                    ) {
                                      if (loadingProgress == null) {
                                        return child;
                                      }
                                      return SizedBox(
                                        width: 50,
                                        height: 50,
                                        child: Center(
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
                                )
                                : Image.asset(
                                  Theme.of(context).brightness ==
                                          Brightness.light
                                      ? 'assets/logos/logo_light.png'
                                      : 'assets/logos/logo_dark.png',
                                  fit: BoxFit.contain,
                                ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          selectedGroup = grp;
                          group = selectedGroup;
                          dateController.text = DateFormat(
                            'yyyy-MM-dd',
                          ).format(DateTime.now());
                          members = (group['exGroupMembers'] ?? []).toList();
                        });
                      },
                    );
                  }),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
