import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:wisepaise/models/reminder_model.dart';
import 'package:wisepaise/models/user_model.dart';
import 'package:wisepaise/providers/api_provider.dart';
import 'package:wisepaise/providers/auth_provider.dart';
import 'package:wisepaise/providers/settings_provider.dart';
import 'package:wisepaise/utils/toast.dart';
import 'package:wisepaise/utils/utils.dart';

import '../utils/calculator_bottom_sheet.dart';
import '../utils/constants.dart';
import 'home_page.dart';

class CreateReminderPage extends StatefulWidget {
  ReminderModel reminder;

  CreateReminderPage({required this.reminder});

  @override
  State<CreateReminderPage> createState() => _CreateReminderPageState();
}

class _CreateReminderPageState extends State<CreateReminderPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _recurrenceEndDateController =
      TextEditingController();
  final TextEditingController _recurrenceIntervalController =
      TextEditingController(text: '1');
  final TextEditingController _amountController = TextEditingController();
  bool _isExpense = true;
  String _recurrencePattern = 'NONE';
  bool _isRecurring = false;
  bool _isActive = true;

  double verticalGap = 15.0;

  @override
  void initState() {
    super.initState();

    _isExpense = widget.reminder.reminderAmountType == 'expense' ? true : false;

    _nameController.text =
        widget.reminder.reminderName.isNotEmpty
            ? widget.reminder.reminderName
            : '';

    _descController.text =
        widget.reminder.reminderDescription.isNotEmpty
            ? widget.reminder.reminderDescription
            : '';
    _amountController.text =
        widget.reminder.reminderAmount.isNotEmpty
            ? widget.reminder.reminderAmount
            : '';

    _dateController.text =
        widget.reminder.reminderDate.isNotEmpty
            ? widget.reminder.reminderDate
            : '';
    _isRecurring = widget.reminder.reminderIsRecurring;
    _isActive = widget.reminder.reminderIsActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _dateController.dispose();
    _recurrenceEndDateController.dispose();
    _recurrenceIntervalController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  OutlineInputBorder _outlineBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(width: 0.25),
    );
  }

  bool _validate() {
    if (_nameController.text.trim().isEmpty) {
      Toasts.show(context, 'Enter a name', type: ToastType.error);
      return false;
    }
    if (_amountController.text.trim().isEmpty ||
        _amountController.text.trim() == '0') {
      Toasts.show(context, 'Enter amount', type: ToastType.error);
      return false;
    }
    if (_dateController.text.trim().isEmpty) {
      Toasts.show(context, 'Pick a date', type: ToastType.error);
      return false;
    }
    return true;
  }

  Future<void> _submit() async {
    if (!_validate()) return;

    final auth = context.read<AuthProvider>();
    final api = context.read<ApiProvider>();

    final user = await auth.getSignedInUser();
    final now = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    if (widget.reminder.reminderId.isEmpty) {
      final model = ReminderModel(
        '',
        _nameController.text.trim(),
        _descController.text.trim(),
        _dateController.text.trim(),
        _recurrencePattern,
        _recurrenceEndDateController.text.trim(),
        _recurrenceIntervalController.text.trim(),
        now,
        _amountController.text.trim(),
        _isExpense ? 'expense' : 'income',
        UserModel(
          userId: user!.id,
          userName: user.displayName!,
          userEmail: user.email,
          userImageUrl: user.photoUrl!,
          userCreatedOn: '',
        ),
        _isRecurring,
        _isActive,
      );

      try {
        await api.createReminder(context, model.toJson()).then((Response resp) {
          if (mounted && resp.statusCode == HttpStatus.ok) {
            Toasts.show(
              context,
              'Reminder created successfully',
              type: ToastType.success,
            );
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => MyDashboardPage()),
              (Route<dynamic> route) => false,
            );
          }
        });
      } catch (e) {
        if (mounted) {
          Toasts.show(
            context,
            'Failed to create reminder',
            type: ToastType.error,
          );
        }
      }
    } else {
      final model = ReminderModel(
        widget.reminder.reminderId,
        _nameController.text.trim(),
        _descController.text.trim(),
        _dateController.text.trim(),
        _recurrencePattern,
        _recurrenceEndDateController.text.trim(),
        _recurrenceIntervalController.text.trim(),
        widget.reminder.reminderCreatedDate,
        _amountController.text.trim(),
        _isExpense ? 'expense' : 'income',
        widget.reminder.reminderUserId,
        _isRecurring,
        _isActive,
      );

      try {
        await api.updateReminder(context, model.toJson()).then((Response resp) {
          if (mounted && resp.statusCode == HttpStatus.ok) {
            Toasts.show(
              context,
              'Reminder updated successfully',
              type: ToastType.success,
            );
            api.expenseReminderList.removeWhere(
              (rem) => rem['reminderId'] == resp.data['reminderId'],
            );

            api.expenseReminderList.add(resp.data);
            Navigator.pop(context);
          }
        });
      } catch (e) {
        if (mounted) {
          Toasts.show(
            context,
            'Failed to create reminder',
            type: ToastType.error,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ApiProvider>(
      builder: (_, api, __) {
        return Consumer<SettingsProvider>(
          builder: (_, set, __) {
            return Scaffold(
              appBar: AppBar(
                centerTitle: true,
                title: Text(
                  'Create a reminder',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              body: Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15.0,
                            vertical: 8.0,
                          ),
                          child: SingleChildScrollView(
                            physics: BouncingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(height: 10.0),
                                // Expense/Income Toggle (copied style)
                                Card(
                                  elevation: 0.5,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      // color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: GestureDetector(
                                            onTap:
                                                () => setState(
                                                  () => _isExpense = true,
                                                ),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 14,
                                                  ),
                                              decoration: BoxDecoration(
                                                color:
                                                    _isExpense
                                                        ? Colors.green
                                                        : Colors.transparent,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  "Expense",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: GestureDetector(
                                            onTap:
                                                () => setState(
                                                  () => _isExpense = false,
                                                ),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 14,
                                                  ),
                                              decoration: BoxDecoration(
                                                color:
                                                    !_isExpense
                                                        ? Colors.green
                                                        : Colors.transparent,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  "Income",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _nameController,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    labelText: 'Reminder Name',
                                    labelStyle: labelStyle(context),
                                    border: _outlineBorder(),
                                  ),
                                  maxLines: 1,
                                ),
                                SizedBox(height: verticalGap),
                                TextField(
                                  controller: _descController,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    labelText: 'Description (Optional)',
                                    labelStyle: labelStyle(context),
                                    border: _outlineBorder(),
                                  ),
                                  maxLines: 2,
                                ),
                                SizedBox(height: verticalGap),
                                TextField(
                                  controller: _amountController,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    suffixIcon: IconButton(
                                      onPressed:
                                          () => _openCalculatorBottomSheet(),
                                      icon: Icon(Icons.calculate_outlined),
                                    ),
                                    prefixIcon: Icon(
                                      _isExpense ? Icons.remove : Icons.add,
                                      color:
                                          _isExpense
                                              ? Colors.red
                                              : Colors.green,
                                    ),
                                    hintText: set.currency,
                                    labelText: 'Amount',
                                    labelStyle: labelStyle(context),
                                    border: _outlineBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                                SizedBox(height: verticalGap),
                                TextField(
                                  controller: _dateController,
                                  readOnly: true,
                                  onTap:
                                      () => _pickDate(
                                        context,
                                        _dateController,
                                        isFirstDateToday: true,
                                      ),
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    labelText: 'Reminder Date',
                                    labelStyle: labelStyle(context),
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.calendar_today),
                                      onPressed:
                                          () => _pickDate(
                                            context,
                                            _dateController,
                                            isFirstDateToday: true,
                                          ),
                                    ),
                                    border: _outlineBorder(),
                                  ),
                                ),
                                SizedBox(height: verticalGap),
                                SwitchListTile.adaptive(
                                  contentPadding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  title: Text(
                                    'Recurring',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium!
                                        .copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    'Repeat this reminder?',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall!
                                        .copyWith(color: Colors.grey.shade500),
                                  ),
                                  activeColor: Colors.blue,
                                  value: _isRecurring,
                                  onChanged: (bool value) {
                                    setState(() => _isRecurring = value);
                                  },
                                ),
                                SizedBox(height: verticalGap),
                                Visibility(
                                  visible: _isRecurring,
                                  maintainState: true,
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: DropdownButtonFormField<
                                              String
                                            >(
                                              value: _recurrencePattern,
                                              decoration: InputDecoration(
                                                labelText: 'Recurrence Pattern',
                                                labelStyle: labelStyle(context),
                                                border: _outlineBorder(),
                                              ),
                                              items: [
                                                DropdownMenuItem(
                                                  value: 'NONE',
                                                  child: Text(
                                                    'None',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .labelLarge!
                                                        .copyWith(
                                                          letterSpacing: 1.5,
                                                        ),
                                                  ),
                                                ),
                                                DropdownMenuItem(
                                                  value: 'DAILY',
                                                  child: Text(
                                                    'Daily',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .labelLarge!
                                                        .copyWith(
                                                          letterSpacing: 1.5,
                                                        ),
                                                  ),
                                                ),
                                                DropdownMenuItem(
                                                  value: 'WEEKLY',
                                                  child: Text(
                                                    'Weekly',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .labelLarge!
                                                        .copyWith(
                                                          letterSpacing: 1.5,
                                                        ),
                                                  ),
                                                ),
                                                DropdownMenuItem(
                                                  value: 'MONTHLY',
                                                  child: Text(
                                                    'Monthly',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .labelLarge!
                                                        .copyWith(
                                                          letterSpacing: 1.5,
                                                        ),
                                                  ),
                                                ),
                                                DropdownMenuItem(
                                                  value: 'YEARLY',
                                                  child: Text(
                                                    'Yearly',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .labelLarge!
                                                        .copyWith(
                                                          letterSpacing: 1.5,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                              onChanged:
                                                  (v) => setState(
                                                    () =>
                                                        _recurrencePattern =
                                                            v ?? 'NONE',
                                                  ),
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: TextField(
                                              controller:
                                                  _recurrenceIntervalController,
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: InputDecoration(
                                                labelText: 'Interval',
                                                labelStyle: labelStyle(context),
                                                border: _outlineBorder(),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: verticalGap),
                                      TextField(
                                        controller:
                                            _recurrenceEndDateController,
                                        readOnly: true,
                                        onTap:
                                            () => _pickDate(
                                              context,
                                              _recurrenceEndDateController,
                                            ),
                                        decoration: InputDecoration(
                                          labelText: 'Recurrence End Date',
                                          labelStyle: labelStyle(context),
                                          suffixIcon: IconButton(
                                            icon: const Icon(
                                              Icons.calendar_today,
                                            ),
                                            onPressed:
                                                () => _pickDate(
                                                  context,
                                                  _recurrenceEndDateController,
                                                ),
                                          ),
                                          border: _outlineBorder(),
                                        ),
                                      ),
                                      SizedBox(height: verticalGap),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 25.0,
                            vertical: 10.0,
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _submit,
                            icon: Icon(
                              widget.reminder.reminderId.isEmpty
                                  ? Icons.check
                                  : FontAwesomeIcons.penToSquare,
                            ),
                            label: Text(
                              widget.reminder.reminderId.isEmpty
                                  ? 'Create Reminder'
                                  : 'Update Reminder',
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
                              ).textTheme.titleMedium!.copyWith(
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (api.isAPILoading) buildLoadingContainer(context: context),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _pickDate(
    BuildContext context,
    TextEditingController controller, {
    bool isFirstDateToday = false,
  }) {
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
            firstDate: isFirstDateToday ? DateTime.now() : DateTime(2000),
            lastDate: DateTime(2100),
            onDateChanged: (date) {
              Navigator.of(context).pop();
              controller.text = DateFormat('yyyy-MM-dd').format(date);
            },
          ),
        );
      },
    );
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
        _amountController.text = result.toStringAsFixed(2);
      });
    }
  }
}
