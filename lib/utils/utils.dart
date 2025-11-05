import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:wisepaise/models/type_model.dart';
import 'package:wisepaise/utils/toast.dart';

import '../models/reminder_model.dart';
import '../providers/api_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../screen/create_expense_group_page.dart';
import '../screen/create_expense_page.dart';
import '../screen/create_reminder_page.dart';
import '../screen/create_savings_goal_page.dart';
import 'constants.dart';
import 'dialog_utils.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:shimmer/shimmer.dart';

unfocusKeyboard() {
  FocusManager.instance.primaryFocus?.unfocus();
}

String formatCurrency(num amount, BuildContext context, {String? locale}) {
  final currencyCode =
      Provider.of<SettingsProvider>(context, listen: false).currency;
  final formatter = NumberFormat.simpleCurrency(
    name: currencyCode,
    locale: locale ?? 'en',
  );
  return formatter.format(amount);
}

String formatDateString(String dateStr, {String pattern = 'MMM dd, yyyy'}) {
  final DateTime date = DateTime.parse(dateStr);
  final formatter = DateFormat(pattern);
  return formatter.format(date);
}

String formatDate(DateTime date, {String pattern = 'MMM dd, yyyy'}) {
  final formatter = DateFormat(pattern);
  return formatter.format(date);
}

IconData getCategoryIcon(String category, String type) {
  CategoryModel thisCat = catList[type]!.firstWhere(
    (cat) => cat.cat == category,
  );
  return thisCat.icon;
}

Material buildCreateDataBox(
  BuildContext context,
  String title,
  var onTapFunction,
  Gradient gradients,
) {
  return Material(
    color: Colors.grey.shade100,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
    child: InkWell(
      borderRadius: BorderRadius.circular(8.0),
      onTap: onTapFunction,
      child: Ink(
        height: 125,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          gradient: gradients,
        ),
        padding: EdgeInsets.all(5.0),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: Colors.white,
              letterSpacing: 1.5,
              fontSize: 15.0,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );
}

buildCreateReminder(BuildContext context, ApiProvider api) {
  return buildCreateDataBox(
    context,
    addReminderMsg,
    () async {
      Map<String, dynamic>? data = await Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (context) => CreateReminderPage(reminder: ReminderModel.empty()),
        ),
      );

      if (data != null) {
        api.expenseReminderList.add(data);
        getActiveReminders(api).add(data);
      }
    },
    LinearGradient(
      colors: [Color(0xFFD66D75), Color(0xFFE29587)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );
}

List<Map<String, dynamic>> getActiveReminders(ApiProvider api) {
  return api.expenseReminderList.where((rem) {
    return rem['reminderIsActive'] == true;
  }).toList();
}

buildCreateGroup(BuildContext context) {
  return buildCreateDataBox(
    context,
    addGroupMsg,
    () {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CreateExpenseGroupPage(group: {}),
        ),
      );
    },
    LinearGradient(
      colors: [Color(0xFFE8CBC0), Color(0xFF636FA4)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );
}

buildCreateGoal(BuildContext context) {
  return buildCreateDataBox(
    context,
    addGoalMsg,
    () {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CreateSavingsGoalPage(goal: {}),
        ),
      );
    },
    LinearGradient(
      colors: [Color(0xFFff9966), Color(0xFFff5e62)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );
}

buildCreateExpense(BuildContext context) {
  return buildCreateDataBox(
    context,
    addExpenseMsg,
    () {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CreateExpensePage(group: {}, expense: {}),
        ),
      );
    },
    LinearGradient(
      colors: [Color(0xFF642B73), Color(0xFFC6426E)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );
}

Widget buildLoadingContainer({
  required BuildContext context,
  bool showBgColor = false,
}) {
  return Container(
    color:
        showBgColor
            ? (Theme.of(context).brightness == Brightness.light
                ? Colors.white54
                : Colors.black)
            : Colors.black54,
    child: Center(
      child: Card(
        elevation: 2.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Container(
          margin: EdgeInsets.all(10.0),
          height: 75.0,
          width: 100.0,
          decoration: BoxDecoration(
            // color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Image.asset('assets/loader.gif', fit: BoxFit.fill),
        ),
      ),
    ),
  );
}

Widget buildDashboardShimmer(BuildContext context) {
  return Shimmer.fromColors(
    direction: ShimmerDirection.ltr,
    period: Duration(seconds: 2),
    baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    highlightColor: Theme.of(context).colorScheme.surfaceContainerLow,
    child: SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Bar Placeholder
          titleShimmer(),
          const SizedBox(height: 10),
          // Horizontal Reminder List Placeholder
          SizedBox(
            height: 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder:
                  (context, index) => Container(
                    width: 280,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
            ),
          ),
          const SizedBox(height: 20),
          titleShimmer(),
          const SizedBox(height: 10),
          // Expense/Income cards placeholder
          SizedBox(
            height: 75,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder:
                  (context, index) => Container(
                    width: 280,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
            ),
          ),
          SizedBox(height: 20.0),
          titleShimmer(),
          const SizedBox(height: 10),
          ListView.builder(
            physics: NeverScrollableScrollPhysics(),
            itemCount: 5,
            shrinkWrap: true,
            itemBuilder: (context, index) {
              return Container(
                width: double.infinity,
                height: 50,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            },
          ),
        ],
      ),
    ),
  );
}

Container titleShimmer() {
  return Container(
    width: 200,
    height: 20,
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
    ),
  );
}

Future<Uint8List?> pickFile({
  ImageSource pickType = ImageSource.gallery,
}) async {
  final ImagePicker picker = ImagePicker();
  final picked = await picker.pickImage(source: pickType);

  if (picked == null) return null;
  return picked.readAsBytes();
}

List<Widget> buildGroupedExpenseWidgets(
  List<Map<String, dynamic>> expenses,
  BuildContext context,
) {
  // Parse and sort by date desc
  final DateFormat inputFmt = DateFormat('yyyy-MM-dd');
  final DateFormat headerFmt = DateFormat('MMM yyyy');

  List<Map<String, dynamic>> parsed =
      expenses.map((e) {
        String dateStr = (e['expenseDate'] ?? '').toString();
        DateTime? dt;
        try {
          if (dateStr.isNotEmpty) dt = inputFmt.parse(dateStr);
        } catch (_) {
          dt = null;
        }
        return {...e, '_parsedDate': dt};
      }).toList();

  parsed.sort((a, b) {
    DateTime? da = a['_parsedDate'];
    DateTime? db = b['_parsedDate'];
    if (da == null && db == null) return 0;
    if (da == null) return 1;
    if (db == null) return -1;
    return db.compareTo(da);
  });

  Map<String, List<Map<String, dynamic>>> groups = {};
  for (var e in parsed) {
    DateTime? dt = e['_parsedDate'];
    String key = dt == null ? 'Unknown' : headerFmt.format(dt);
    groups.putIfAbsent(key, () => []).add(e);
  }

  final theme = Theme.of(context);
  List<Widget> widgets = [];
  groups.forEach((header, items) {
    widgets.add(
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
        child: Text(
          header,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
    widgets.addAll(
      items.take(10).map((e) {
        return Dismissible(
          key: ValueKey(e['expenseId']),
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
              children: [
                const Icon(Icons.delete, color: Colors.white),
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
            final shouldDelete = await DialogUtils.showGenericDialog(
              context: context,
              title: DialogUtils.titleText('Delete Expense?'),
              message: const Text(
                'Are you sure you want to delete this expense?',
              ),
              onConfirm: () {
                Navigator.of(context).pop(true);
              },
              onCancel: () => Navigator.of(context).pop(false),
              showCancel: true,
              cancelText: 'Cancel',
              confirmText: 'Delete',
              confirmColor: Colors.red,
            );
            return shouldDelete ?? false;
          },

          onDismissed: (direction) async {
            ApiProvider api = Provider.of<ApiProvider>(context, listen: false);

            String strExpId = e['expenseId'];

            api.userExpenseList.removeWhere(
              (exp) => exp['expenseId'] == strExpId,
            );

            await api.deleteExpense(context, strExpId).then((Response resp) {
              debugPrint(resp.statusCode.toString());
              if (resp.statusCode == 200) {
                Toasts.show(
                  context,
                  "Expense ${e['expenseTitle']} Removed",
                  type: ToastType.success,
                );
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: ListTile(
              isThreeLine: true,
              onTap: () {
                DialogUtils.showGenericDialog(
                  context: context,
                  showCancel: true,
                  onCancel: () => Navigator.pop(context),
                  confirmColor: Colors.green,
                  cancelText: 'Close',
                  onConfirm:
                      e['expenseId'] != null && e['expenseId'].isNotEmpty
                          ? () async {
                            final updatedGroup = await Navigator.of(
                              context,
                            ).push(
                              MaterialPageRoute(
                                builder:
                                    (context) => CreateExpensePage(
                                      group: {},
                                      expense: e,
                                    ),
                              ),
                            );
                            debugPrint(
                              'updatedGroup:::${updatedGroup.toString()}',
                            );
                            if (updatedGroup != null) {}
                            Navigator.of(context).pop();
                          }
                          : null,
                  confirmText: 'Edit',
                  title: SizedBox.shrink(),
                  message: SizedBox(child: expenseCard(context, e)),
                );
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              splashColor: Colors.grey.shade100,
              contentPadding: EdgeInsets.symmetric(horizontal: 2.5),

              leading: Card(
                margin: EdgeInsets.zero,
                elevation: 0.0,
                shape: CircleBorder(),
                child: Container(
                  decoration: BoxDecoration(shape: BoxShape.circle),
                  height: 65.0,
                  width: 65.0,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        DateTime.parse(e['expenseDate']).day.toString(),
                        style: TextStyle(
                          fontSize: 17.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        month
                            .elementAt(
                              int.parse(
                                    DateTime.parse(
                                      e['expenseDate'],
                                    ).month.toString(),
                                  ) -
                                  1,
                            )
                            .toUpperCase(),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              title: Text(e['expenseTitle'], style: TextStyle(fontSize: 17.5)),
              subtitle: Text(
                '${e['expenseCategory']} • ${e['expenseSubCategory']}',
                style: TextStyle(fontSize: 12.5),
              ),
              trailing: Card(
                margin: EdgeInsets.zero,
                elevation: 0.0,
                child: Container(
                  padding: EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        e['expenseSpendType'] == 'expense'
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                        color:
                            e['expenseSpendType'] == 'expense'
                                ? Colors.red
                                : Colors.green,
                      ),
                      SizedBox(width: 5.0),
                      Text(
                        formatCurrency(e['expenseAmount'], context),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              e['expenseSpendType'] == 'expense'
                                  ? Colors.red
                                  : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
    widgets.add(
      const Divider(height: 5, thickness: 0.25, indent: 25.0, endIndent: 25.0),
    );
  });
  return widgets;
}

Widget expenseCard(BuildContext context, Map<String, dynamic> expense) {
  return Card(
    margin: EdgeInsets.all(0.0),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      getCategoryIcon(
                        expense['expenseCategory'],
                        expense['expenseSpendType'],
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            expense['expenseCategory'],
                            style: TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                            softWrap: true,
                            maxLines: 1,
                          ),
                          Text(
                            expense['expenseSubCategory'] ?? '',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                              letterSpacing: 1.5,
                              fontSize: 12.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                            softWrap: true,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                "${expense['expenseSpendType'] == 'income' ? '+' : '-'} ₹${expense['expenseAmount']}",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color:
                      expense['expenseSpendType'] == 'income'
                          ? Colors.green
                          : Colors.red,
                ),
              ),
            ],
          ),

          SizedBox(height: 8),
          Text(
            expense['expenseTitle'],
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 4),
          Text(
            formatDateString(expense['expenseDate'], pattern: 'dd MMM yyyy'),
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),

          Divider(height: 20),

          // Paid By + Payment Method
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Paid By: ${expense['expensePaidBy']['userName']}",
                  style: TextStyle(fontSize: 14),
                ),

                Icon(
                  payMethodList
                      .firstWhere(
                        (pay) =>
                            pay.payMethod == expense['expensePaymentMethod'],
                      )
                      .icon,
                ),
              ],
            ),
          ),

          SizedBox(height: 8),

          Wrap(
            spacing: 6,
            children:
                expense['expensePaidTo'].map<Widget>((name) {
                  debugPrint('name:::${name.toString()}');
                  return Chip(label: Text(name['userName']));
                }).toList(),
          ),

          if (expense['expenseNote'].isNotEmpty) ...[
            SizedBox(height: 8),
            Text(
              "Note: ${expense['expenseNote']}",
              style: TextStyle(
                color: Colors.grey[700],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          if (expense['expenseReceiptURL'].isNotEmpty) ...[
            SizedBox(height: 12),
            InkWell(
              borderRadius: BorderRadius.circular(12.0),
              onTap: () {
                DialogUtils.showGenericDialog(
                  context: context,
                  showCancel: false,
                  confirmText: 'Close',
                  confirmColor: Colors.green,
                  onConfirm: () => Navigator.of(context).pop(),
                  title: SizedBox.shrink(),
                  message: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: Image.network(
                      expense['expenseReceiptURL'],
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) {
                          return child;
                        }
                        return const Center(
                          child: CupertinoActivityIndicator(),
                        );
                      },
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Icon(Icons.attach_file, color: Colors.purple),
                    SizedBox(width: 6),
                    Text(
                      "View Attachment",
                      style: TextStyle(color: Colors.purple),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

Widget initialsRow(
  List<dynamic> names,
  BuildContext context, {
  bool showImage = false,
}) {
  final double avatarSize = 35;
  final double overlap = 26.5;
  final int maxToShow = 5;

  // show max 5 names, rest go in "+X"
  final visibleNames =
      names.length > maxToShow ? names.take(maxToShow).toList() : names;

  final totalCount = names.length;
  final extraCount = totalCount - visibleNames.length;

  // total width for positioning
  final double totalWidth =
      avatarSize +
      ((visibleNames.length - 1) + (extraCount > 0 ? 1 : 0)) * overlap;

  return GestureDetector(
    onTap: () {
      debugPrint(names.toString());
      DialogUtils.showGenericDialog(
        context: context,
        title: DialogUtils.titleText('Group Members'),
        message: SizedBox(
          height:
              names.length > 5
                  ? MediaQuery.of(context).size.height / 3
                  : MediaQuery.of(context).size.height / 5,
          child: ListView(
            shrinkWrap: true,
            physics: BouncingScrollPhysics(),
            children:
                names.map((name) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CircleAvatar(
                        backgroundImage: NetworkImage(name['userImageUrl']),
                      ),
                    ),
                    title: Text(name['userName']),
                    subtitle: Text(name['userEmail']),
                  );
                }).toList(),
          ),
        ),
        showCancel: false,
        onConfirm: () {
          Navigator.of(context).pop();
        },
        confirmColor: Colors.green,
        confirmText: 'Close',
      );
    },
    child: SizedBox(
      height: avatarSize,
      width: totalWidth,
      child: Stack(
        children: [
          // actual initials
          for (int i = 0; i < visibleNames.length; i++)
            Positioned(
              left: i * overlap,
              child: CircleAvatar(
                radius: avatarSize / 2,
                backgroundColor: Colors.lightBlue,
                backgroundImage:
                    showImage
                        ? NetworkImage(
                          visibleNames[i]['userImageUrl'] ??
                              visibleNames[i].userImageUrl,
                        )
                        : null,
                child:
                    showImage
                        ? SizedBox.shrink()
                        : Text(
                          getInitials(
                            visibleNames[i]['userName'] ??
                                visibleNames[i].userName,
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
              ),
            ),

          // "+X" avatar if more members
          if (extraCount > 0)
            Positioned(
              left: visibleNames.length * overlap,
              child: CircleAvatar(
                radius: avatarSize / 2,
                backgroundColor: Colors.blue,
                child: Text(
                  "+$extraCount",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

String getInitials(String name) {
  final parts = name.trim().split(' ');
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

Future<String> uploadImage(
  Uint8List imageBytes,
  String fileName,
  BuildContext context,
) async {
  var dio = Dio();
  String imageUrl = "";
  ApiProvider api = Provider.of<ApiProvider>(context, listen: false);
  api.setLoading();

  await compressImage(imageBytes).then((compressedBytes) async {
    FormData formData = FormData.fromMap({
      "file": MultipartFile.fromBytes(
        compressedBytes as List<int>,
        filename: fileName,
        contentType: MediaType("image", "jpg"),
      ),
    });

    Response response = await dio.post(
      imageUploadURL,
      data: formData,
      options: Options(headers: {"Content-Type": "multipart/form-data"}),
    );

    if (response.statusCode == 200) {
      debugPrint("Upload successful: ${response.data}");
      Toasts.show(
        context,
        "Image successfully uploaded!",
        type: ToastType.success,
      );
      imageUrl = response.data['url'] ?? '';
      if (imageUrl.isEmpty) {
        Toasts.show(context, "Image upload failed", type: ToastType.error);
        api.removeLoading();
      }
    } else {
      Toasts.show(context, "Image upload failed", type: ToastType.error);
    }
  });

  return Future.value(imageUrl);
}

Future<Uint8List?> compressImage(Uint8List imageBytes) async {
  try {
    final compressedBytes = await FlutterImageCompress.compressWithList(
      imageBytes,
      minWidth: 1080,
      minHeight: 1080,
      quality: 80,
      format: CompressFormat.jpeg,
    );

    debugPrint('Original size: ${imageBytes.lengthInBytes / 1024} KB');
    debugPrint('Compressed size: ${compressedBytes.lengthInBytes / 1024} KB');

    return compressedBytes;
  } catch (e) {
    print('Compression failed: $e');
    return null;
  }
}

showSnackBar(context, text, Icon icon) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          SizedBox(width: 10.0),
          Text(
            text,
            textAlign: TextAlign.start,
            style: TextStyle(
              letterSpacing: 1.5,
              fontWeight: FontWeight.w500,
              fontSize: 13.5,
            ),
            overflow: TextOverflow.ellipsis,
            softWrap: true,
            maxLines: 2,
          ),
        ],
      ),
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: 2),
      elevation: 2.0,
      dismissDirection: DismissDirection.down,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
    ),
  );
}

String getPayStatus(Map<String, dynamic> expense, BuildContext context) {
  AuthProvider auth = Provider.of<AuthProvider>(context, listen: false);
  List<dynamic> paidTo = expense['expensePaidTo'];
  debugPrint('paidTo:::${paidTo.toString()}');

  if (expense['expensePaidBy']['userId'] == auth.user!.id &&
      (paidTo.length == 1 && paidTo.first['userId'] == auth.user!.id)) {
    return 'no balance';
  }

  if (expense['expensePaidBy']['userId'] == auth.user!.id) {
    return 'you lent';
  }

  final payItem = paidTo.firstWhere(
    (pay) => pay['userId'] == auth.user!.id,
    orElse: () => null, // returns null if not found
  );
  debugPrint('payItem:::${payItem.toString()}');
  if (payItem != null) {
    return 'you borrowed';
  }
  return 'not involved';
}

String formatCompactCurrency(num amount, BuildContext context) {
  SettingsProvider settings = Provider.of<SettingsProvider>(
    context,
    listen: false,
  );
  final format = NumberFormat.compactCurrency(
    symbol: settings.currency, // or manually set '₹', '$', etc.
    decimalDigits: 1,
  );
  return format.format(amount);
}

Widget noDataWidget(String header, String subHead, BuildContext context) {
  return Column(
    key: const ValueKey('noData'),
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      // 🔹 Illustration (optional Lottie or PNG)
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Image.asset(
          'assets/images/no-data.png',
          height: 100,
          fit: BoxFit.contain,
        ),
      ),

      // 🔹 Headline
      Text(
        header,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),

      const SizedBox(height: 2),

      // 🔹 Subtext
      Text(
        subHead,
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
      ),
    ],
  );
}
