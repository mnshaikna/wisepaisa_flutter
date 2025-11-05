import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:wisepaise/models/savings_goal_model.dart';
import 'package:wisepaise/models/user_model.dart';
import 'package:wisepaise/providers/api_provider.dart';
import 'package:wisepaise/providers/settings_provider.dart';

import '../providers/auth_provider.dart';
import '../utils/toast.dart';
import '../utils/utils.dart';
import 'home_page.dart';

class CreateSavingsGoalPage extends StatefulWidget {
  Map<String, dynamic> goal;

  CreateSavingsGoalPage({super.key, required this.goal});

  @override
  State<CreateSavingsGoalPage> createState() =>
      _CreateSavingsGoalPageState(goal: goal);
}

class _CreateSavingsGoalPageState extends State<CreateSavingsGoalPage> {
  Map<String, dynamic> goal;

  _CreateSavingsGoalPageState({required this.goal});

  final TextEditingController nameController = TextEditingController();
  final TextEditingController targetAmountController = TextEditingController();
  final TextEditingController savedAmountController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  Uint8List? imageBytes;

  @override
  void initState() {
    super.initState();
    if (goal.isNotEmpty) {
      nameController.text = goal['savingsGoalName'];
      targetAmountController.text = goal['savingsGoalTargetAmount'].toString();
      savedAmountController.text = goal['savingsGoalCurrentAmount'].toString();
      dateController.text = goal['savingsGoalTargetDate'];
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    targetAmountController.dispose();
    savedAmountController.dispose();
    dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SettingsProvider, ApiProvider>(
      builder: (_, set, api, __) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              goal.isNotEmpty ? goal['savingsGoalName'] : 'Create Savings Goal',
            ),
            centerTitle: true,
          ),
          body: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 15.0,
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              imageBytes == null &&
                                      (goal['savingsGoalImageUrl'] == null ||
                                          goal['savingsGoalImageUrl'].isEmpty)
                                  ? Card(
                                    elevation: 1.0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12.0),
                                      onTap:
                                          () => _showAttachmentOptions(context),
                                      splashColor: Colors.grey.shade500,
                                      child: Container(
                                        padding: EdgeInsets.all(15.0),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            12.0,
                                          ),
                                        ),
                                        child: Icon(Icons.add_a_photo_outlined),
                                      ),
                                    ),
                                  )
                                  : GestureDetector(
                                    onTap:
                                        () => _showAttachmentOptions(context),
                                    child: Container(
                                      height: 60.0,
                                      width: 60.0,
                                      padding: EdgeInsets.all(0.0),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          12.0,
                                        ),
                                        border: Border.all(
                                          width: 0.0,
                                          color:
                                              Theme.of(context).brightness ==
                                                      Brightness.light
                                                  ? Colors.black54
                                                  : Colors.white54,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          12.0,
                                        ),
                                        child:
                                            goal['savingsGoalImageUrl'] !=
                                                        null &&
                                                    goal['savingsGoalImageUrl']
                                                        .isNotEmpty
                                                ? Image.network(
                                                  goal['savingsGoalImageUrl'],
                                                  fit: BoxFit.cover,
                                                )
                                                : Image.memory(
                                                  imageBytes as Uint8List,
                                                  fit: BoxFit.cover,
                                                ),
                                      ),
                                    ),
                                  ),
                              SizedBox(width: 5.0),
                              Expanded(
                                child: TextField(
                                  controller: nameController,
                                  textInputAction: TextInputAction.next,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  decoration: InputDecoration(
                                    labelText: 'Goal name',
                                    border: buildOutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: targetAmountController,
                            decoration: InputDecoration(
                              labelText: 'Target amount',
                              border: buildOutlineInputBorder(),
                              hintText: set.currency,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: savedAmountController,
                            enabled: goal.isEmpty,
                            decoration: InputDecoration(
                              labelText: 'Saved so far (optional)',
                              border: buildOutlineInputBorder(),
                              hintText: set.currency,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: dateController,
                            readOnly: true,
                            onTap:
                                () => _pickDate(
                                  context,
                                  dateController,
                                  isFirstDateToday: true,
                                ),
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: 'Target Date',
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.calendar_today),
                                onPressed:
                                    () => _pickDate(
                                      context,
                                      dateController,
                                      isFirstDateToday: true,
                                    ),
                              ),
                              border: buildOutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            String url = "";
                            AuthProvider authProv = Provider.of<AuthProvider>(
                              context,
                              listen: false,
                            );
                            if (checkForm()) {
                              if (imageBytes != null) {
                                url = await uploadImage(
                                  imageBytes!,
                                  '${Random().nextInt(1000000)}',
                                  context,
                                );
                              }

                              if (goal.isEmpty) {
                                SavingsGoalModel savings = SavingsGoalModel(
                                  savingsGoalId: '',
                                  savingsGoalName: nameController.text.trim(),
                                  savingsGoalTargetAmount: double.parse(
                                    targetAmountController.text,
                                  ),
                                  savingsGoalCurrentAmount:
                                      savedAmountController.text.isEmpty
                                          ? 0.0
                                          : double.parse(
                                            savedAmountController.text,
                                          ),
                                  savingsGoalTargetDate:
                                      dateController.text.trim(),
                                  savingsGoalImageUrl: url,
                                  savingsGoalUser:
                                      UserModel(
                                        userId: authProv.user!.id,
                                        userName: authProv.user!.displayName!,
                                        userEmail: authProv.user!.email,
                                        userImageUrl: authProv.user!.photoUrl!,
                                        userCreatedOn: '',
                                      ).toJson(),
                                  savingsGoalCreatedOn: formatDate(
                                    DateTime.now(),
                                  ),
                                  savingsGoalTransactions: [],
                                );
                                ApiProvider api = Provider.of<ApiProvider>(
                                  context,
                                  listen: false,
                                );
                                await api
                                    .createGoal(context, savings.toJson())
                                    .then((Response resp) {
                                      if (mounted &&
                                          resp.statusCode == HttpStatus.ok) {
                                        Toasts.show(
                                          context,
                                          'Goal created successfully',
                                          type: ToastType.success,
                                        );

                                        Navigator.pushAndRemoveUntil(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) => MyDashboardPage(),
                                          ),
                                          (Route<dynamic> route) => false,
                                        );
                                      }
                                    });
                              } else {
                                SavingsGoalModel savings = SavingsGoalModel(
                                  savingsGoalId: goal['savingsGoalId'],
                                  savingsGoalName: nameController.text.trim(),
                                  savingsGoalTargetAmount: double.parse(
                                    targetAmountController.text,
                                  ),
                                  savingsGoalCurrentAmount:
                                      savedAmountController.text.isEmpty
                                          ? 0.0
                                          : double.parse(
                                            savedAmountController.text,
                                          ),
                                  savingsGoalTargetDate:
                                      dateController.text.trim(),
                                  savingsGoalImageUrl:
                                      url.isNotEmpty
                                          ? url
                                          : goal['savingsGoalImageUrl'],
                                  savingsGoalUser: goal['savingsGoalUser'],
                                  savingsGoalCreatedOn:
                                      goal['savingsGoalCreatedOn'],
                                  savingsGoalTransactions:
                                      goal['savingsGoalTransactions'].toList(),
                                );
                                ApiProvider api = Provider.of<ApiProvider>(
                                  context,
                                  listen: false,
                                );
                                await api
                                    .updateGoal(context, savings.toJson())
                                    .then((Response resp) {
                                      if (mounted &&
                                          resp.statusCode == HttpStatus.ok) {
                                        Toasts.show(
                                          context,
                                          'Goal updated successfully',
                                          type: ToastType.success,
                                        );

                                        Navigator.of(context).pop(resp.data);
                                      }
                                    });
                              }
                            }
                          },
                          icon: Icon(
                            goal.isNotEmpty ? Icons.edit : Icons.check,
                          ),
                          label: Text(
                            goal.isNotEmpty ? 'Update Goal' : 'Create Goal',
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
                            textStyle: TextStyle(
                              fontSize: 15.0,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10.0),
                  ],
                ),
              ),
              if (api.isAPILoading) buildLoadingContainer(context: context),
            ],
          ),
        );
      },
    );
  }

  OutlineInputBorder buildOutlineInputBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: BorderSide(width: 0.25),
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
                    // open gallery picker
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
                      goal['savingsGoalImageUrl'] = '';
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

  bool checkForm() {
    if (nameController.text.trim().isEmpty) {
      Toasts.show(context, 'Enter Goal name', type: ToastType.error);
      return false;
    }
    if (targetAmountController.text.trim().isEmpty ||
        targetAmountController.text.trim() == '0') {
      Toasts.show(context, 'Enter Goal amount', type: ToastType.error);
      return false;
    }

    if (dateController.text.trim().isEmpty) {
      Toasts.show(context, 'Pick Goal date', type: ToastType.error);
      return false;
    }
    return true;
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
}
