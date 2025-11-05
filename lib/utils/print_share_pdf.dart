import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:wisepaise/models/type_model.dart';
import 'package:wisepaise/providers/api_provider.dart';
import 'package:wisepaise/utils/utils.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/group_model.dart';

Future<Uint8List> generateProfessionalGroupPdf(
  GroupModel group,
  BuildContext contexts, {
  required List<dynamic> expenses,
}) async {
  ApiProvider api = Provider.of<ApiProvider>(contexts, listen: false);
  api.setLoading();

  List<dynamic> myExpenses = expenses.isEmpty ? group.expenses : expenses;

  final pdf = pw.Document();

  final logoBytes = await rootBundle.load('assets/logos/logo_light_splash.png');
  final Uint8List logo = logoBytes.buffer.asUint8List();

  final ownerUrl = group.exGroupOwnerId['userImageUrl'];

  final groupUrl =
      group.exGroupImageURL.isNotEmpty ? group.exGroupImageURL : '';

  Dio dio = Dio();
  final response = await dio.get<List<int>>(
    ownerUrl,
    options: Options(responseType: ResponseType.bytes),
  );
  dynamic pdfImage, pdfImage1;
  if (response.statusCode == 200) {
    final Uint8List logoBytes = Uint8List.fromList(response.data!);

    pdfImage = pw.MemoryImage(logoBytes);
  }

  if (groupUrl.isNotEmpty) {
    final response1 = await dio.get<List<int>>(
      groupUrl,
      options: Options(responseType: ResponseType.bytes),
    );
    if (response.statusCode == 200) {
      final Uint8List groupBytes = Uint8List.fromList(response1.data!);

      pdfImage1 = pw.MemoryImage(groupBytes);
    }
  }

  final sectionTitleStyle = pw.TextStyle(
    fontSize: 18,
    fontWeight: pw.FontWeight.bold,
  );
  final tableHeaderStyle = pw.TextStyle(fontWeight: pw.FontWeight.bold);

  // Compute total settlements
  double totalSettlements = group.exGroupMembersSettlements.fold(
    0.0,
    (sum, s) => sum + (s['amount'] as double),
  );

  // Compute per member balances
  Map<String, double> perMemberTotal = {};
  for (var m in group.exGroupMembers) {
    perMemberTotal[m['userId']] =
        group.exGroupMembersBalance[m['userId']] ?? 0.0;
  }
  double totalExpenses =
  myExpenses.fold(0.0, (sum, e) {
            if (group.exGroupShared) {
              return sum + (e['expenseAmount'] as double);
            } else {
              if (e['expenseSpendType'] == 'income') {
                return sum + (e['expenseAmount'] as double);
              } else {
                return sum - (e['expenseAmount'] as double);
              }
            }
          });
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build:
          (context) => [
            // -------------------- Logo --------------------
            pw.Center(
              child: pw.Image(pw.MemoryImage(logo), width: 100, height: 100),
            ),
            pw.SizedBox(height: 10),
            // -------------------- Group Details --------------------
            pw.Text('Group Details', style: sectionTitleStyle),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
              columnWidths: {
                0: pw.FlexColumnWidth(1),
                1: pw.FlexColumnWidth(2),
              },
              children: [
                groupUrl.isNotEmpty
                    ? _buildRow(
                      'Group Name',
                      group.exGroupName,
                      header: true,
                      image: pdfImage1,
                    )
                    : _buildRow('Group Name', group.exGroupName, header: true),
                _buildRow(
                  'Created By',
                  group.exGroupOwnerId['userName'],
                  image: pdfImage,
                ),
                _buildRow(
                  'Created On',
                  formatDateString(group.exGroupCreatedOn),
                ),
                _buildRow(
                  'Type',
                  typeList.elementAt(int.parse(group.exGroupType)).name,
                ),
                if (group.exGroupShared)
                  _buildRow(
                    'Members',
                    group.exGroupMembers.map((e) => e['userName']).join(', '),
                  ),
                _buildRow(
                  group.exGroupShared
                      ? 'Total Expenses'
                      : 'Total Expenses (incomes - expenses)',
                  formatCurrency(totalExpenses, contexts),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // -------------------- Member Balances --------------------
            pw.Text('Member Balances', style: sectionTitleStyle),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: pw.FlexColumnWidth(2),
                1: pw.FlexColumnWidth(1),
              },
              children: [
                _buildRow('Member', 'Balance', header: true),
                ...group.exGroupMembers.map(
                  (m) => _buildRow(
                    m['userName'],
                    formatCurrency(perMemberTotal[m['userId']]!, contexts),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // -------------------- Settlements --------------------
            pw.Text('Settlements', style: sectionTitleStyle),
            pw.SizedBox(height: 8),
            pw.Table.fromTextArray(
              headers: ['From', 'To', 'Amount'],
              headerStyle: tableHeaderStyle,
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              cellAlignment: pw.Alignment.centerLeft,
              cellHeight: 25,
              data: List<List<String>>.generate(
                group.exGroupMembersSettlements.length,
                (index) {
                  final s = group.exGroupMembersSettlements[index];
                  final from =
                      group.exGroupMembers.firstWhere(
                        (m) => m['userId'] == s['fromUserId'],
                      )['userName'];
                  final to =
                      group.exGroupMembers.firstWhere(
                        (m) => m['userId'] == s['toUserId'],
                      )['userName'];
                  final amount = formatCurrency(s['amount'], contexts);
                  return [from, to, amount];
                },
              ),
              oddRowDecoration: const pw.BoxDecoration(
                color: PdfColors.grey100,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: pw.Text(
                'Total Settlement Amount: ${formatCurrency(totalSettlements, contexts)}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 20),

            // -------------------- Expenses --------------------
            pw.Text('Expenses', style: sectionTitleStyle),
            pw.SizedBox(height: 8),
            pw.Table.fromTextArray(
              headers:
                  group.exGroupShared
                      ? ['Description', 'Date', 'Amount', 'Paid By', 'Paid For']
                      : ['Description', 'Date', 'Category', 'Amount'],
              headerStyle: tableHeaderStyle,
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              cellAlignment: pw.Alignment.centerLeft,
              cellHeight: 25,
              data: List<List<String>>.generate(myExpenses.length, (index) {
                final e = myExpenses[index];
                final paidFor = e['expensePaidTo']
                    .map((p) => p['userName'])
                    .join(', ');
                return group.exGroupShared
                    ? [
                      e['expenseTitle'],
                      e['expenseDate'],
                      formatCurrency(e['expenseAmount'], contexts),
                      e['expensePaidBy']['userName'],
                      paidFor,
                    ]
                    : [
                      e['expenseTitle'],
                      e['expenseDate'],
                      '${e['expenseCategory']} | ${e['expenseSubCategory']}',
                      formatCurrency(
                        e['expenseSpendType'] == 'income'
                            ? e['expenseAmount']
                            : e['expenseAmount'] * -1,
                        contexts,
                      ),
                    ];
              }),
              oddRowDecoration: const pw.BoxDecoration(
                color: PdfColors.grey100,
              ),
            ),
          ],
    ),
  );
  api.removeLoading();
  return pdf.save();
}

// -------------------- Helper Function --------------------
pw.TableRow _buildRow(
  String key,
  String value, {
  bool header = false,
  final image,
}) {
  return pw.TableRow(
    decoration:
        header ? const pw.BoxDecoration(color: PdfColors.grey300) : null,
    children: [
      pw.Padding(
        padding: const pw.EdgeInsets.all(5),
        child: pw.Text(
          key,
          style: header ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null,
        ),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.all(5),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.start,
          children: [
            pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(width: 15.0),
            if (image != null)
              pw.ClipOval(
                child: pw.Image(
                  image,
                  width: 50,
                  height: 50,
                  fit: pw.BoxFit.cover, // Ensures the image fills the circle
                ),
              ),
          ],
        ),
      ),
    ],
  );
}
