import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:wisepaise/models/group_model.dart';
import 'package:wisepaise/models/user_model.dart';
import 'package:wisepaise/providers/api_provider.dart';
import 'package:wisepaise/providers/auth_provider.dart';
import 'package:wisepaise/screen/add_members_screen.dart';
import '../models/type_model.dart';
import '../utils/dialog_utils.dart';
import '../utils/toast.dart';
import '../utils/utils.dart';
import 'package:intl/intl.dart';

import 'expense_group_details_page.dart';

class CreateExpenseGroupPage extends StatefulWidget {
  Map<String, dynamic> group;

  CreateExpenseGroupPage({super.key, required this.group});

  @override
  State<CreateExpenseGroupPage> createState() =>
      _CreateExpenseGroupPageState(group: group);
}

class _CreateExpenseGroupPageState extends State<CreateExpenseGroupPage> {
  Map<String, dynamic> group;

  _CreateExpenseGroupPageState({required this.group});

  bool isGroup = false, isError = false;
  Uint8List? imageBytes;
  int? selectedGroupTypeIndex;
  double verticalGap = 15.0;
  UserModel thisUser = UserModel.empty();
  List<Map<String, dynamic>> groupMembers = [];
  TextEditingController memberController = TextEditingController(),
      groupNameController = TextEditingController(),
      groupDescController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (group.isNotEmpty) {
      debugPrint('group:::$group');
      groupNameController.text = group['exGroupName'];
      groupDescController.text = group['exGroupDesc'];
      selectedGroupTypeIndex = int.tryParse(group['exGroupType']);
      isGroup = group['exGroupShared'];
      if (isGroup) {
        groupMembers = (group['exGroupMembers'] ?? []).toList();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        centerTitle: true,
        title: Text(group.isNotEmpty ? group['exGroupName'] : 'Create a group'),
      ),
      body: Consumer<ApiProvider>(
        builder: (_, api, __) {
          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 15.0,
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        physics: BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Row(
                              children: [
                                imageBytes == null &&
                                        (group['exGroupImageURL'] == null ||
                                            group['exGroupImageURL'].isEmpty)
                                    ? Card(
                                      elevation: 1.0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(
                                          12.0,
                                        ),
                                        onTap:
                                            () =>
                                                _showAttachmentOptions(context),
                                        splashColor: Colors.grey.shade500,
                                        child: Container(
                                          padding: EdgeInsets.all(15.0),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              12.0,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.add_a_photo_outlined,
                                          ),
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
                                              group['exGroupImageURL'] !=
                                                          null &&
                                                      group['exGroupImageURL']
                                                          .isNotEmpty
                                                  ? Image.network(
                                                    group['exGroupImageURL'],
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
                                    controller: groupNameController,
                                    textInputAction: TextInputAction.next,
                                    //autofocus: true,
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                    decoration: InputDecoration(
                                      labelText: 'Group name',
                                      border: buildOutlineInputBorder(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: verticalGap),
                            TextField(
                              maxLines: 3,
                              maxLength: 1000,
                              maxLengthEnforcement:
                                  MaxLengthEnforcement.enforced,
                              controller: groupDescController,
                              textInputAction: TextInputAction.newline,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                hintText: 'Group Desc (Optional)',
                                border: buildOutlineInputBorder(),
                              ),
                            ),
                            Text(
                              'Group Type',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17.5,
                                letterSpacing: 1.5,
                              ),
                              textAlign: TextAlign.left,
                            ),
                            SizedBox(height: 10.0),
                            Center(
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.start,
                                alignment: WrapAlignment.start,
                                direction: Axis.horizontal,
                                spacing: 10.0,
                                runSpacing: 10.0,
                                children: List.generate(typeList.length, (
                                  int index,
                                ) {
                                  GroupType thisType = typeList.elementAt(
                                    index,
                                  );
                                  return Card(
                                    //elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12.0),
                                      onTap: () {
                                        setState(() {
                                          selectedGroupTypeIndex = index;
                                        });
                                      },
                                      child: Container(
                                        width: 80.0,
                                        padding: EdgeInsets.all(15.0),
                                        decoration: BoxDecoration(
                                          color:
                                              selectedGroupTypeIndex == index
                                                  ? (Theme.of(
                                                            context,
                                                          ).brightness ==
                                                          Brightness.light
                                                      ? Colors.white70
                                                      : Colors.grey.shade800)
                                                  : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            12.0,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(thisType.icon),
                                            Text(thisType.name),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                            SizedBox(height: verticalGap),
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              title: Text(
                                'Shared Group',
                                style: TextStyle(
                                  fontSize: 17.5,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text('Group involves other people?'),
                              activeColor: Colors.blue,
                              value: isGroup,
                              onChanged: (bool value) {
                                setState(() {
                                  isGroup = value;
                                });
                                if (!isGroup && groupMembers.isNotEmpty) {
                                  DialogUtils.showGenericDialog(
                                    context: context,
                                    title: DialogUtils.titleText(
                                      'Remove Members?',
                                    ),
                                    message: Text(
                                      'Remove all ${groupMembers.length} added Members?',
                                      style: TextStyle(
                                        letterSpacing: 1.5,
                                        fontSize: 15.0,
                                      ),
                                    ),
                                    confirmColor: Colors.green,
                                    showCancel: true,
                                    cancelText: 'Remove',
                                    confirmText: 'Keep',
                                    onCancel: () {
                                      Navigator.of(context).pop();
                                      setState(() => groupMembers.clear());
                                      Toasts.show(
                                        context,
                                        'All members removed',
                                        type: ToastType.info,
                                      );
                                    },
                                    onConfirm:
                                        () => Navigator.of(context).pop(),
                                  );
                                } else if (isGroup) {
                                  AuthProvider authProv =
                                      Provider.of<AuthProvider>(
                                        context,
                                        listen: false,
                                      );
                                  setState(() {
                                    groupMembers.add(
                                      UserModel(
                                        userId: authProv.user!.id,
                                        userName: authProv.user!.displayName!,
                                        userEmail: authProv.user!.email,
                                        userImageUrl: authProv.user!.photoUrl!,
                                        userCreatedOn: "userCreatedOn",
                                      ).toJson(),
                                    );
                                  });
                                }
                              },
                            ),
                            SizedBox(height: verticalGap),
                            Visibility(
                              visible: isGroup,
                              child:
                                  groupMembers.isEmpty
                                      ? buildCreateDataBox(
                                        context,
                                        "Share Expenses with friends?\n\n➕ Add members to this group",
                                        () {
                                          //showAddMembersDialog(context);
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder:
                                                  (context) =>
                                                      AddMembersScreen(),
                                            ),
                                          );
                                        },
                                        LinearGradient(
                                          colors: [
                                            Color(0xFFEFEFBB),
                                            Color(0xFFD4D3DD),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      )
                                      : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Group Members',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 17.5,
                                              letterSpacing: 1.5,
                                            ),
                                            textAlign: TextAlign.left,
                                          ),
                                          SizedBox(height: verticalGap),
                                          Wrap(
                                            runSpacing: 10.0,
                                            spacing: 10.0,
                                            children:
                                                groupMembers.map<Widget>((e) {
                                                    debugPrint(
                                                      'e:::${e.toString()}',
                                                    );
                                                    return GestureDetector(
                                                      onLongPress: () {
                                                        if (group.isNotEmpty) {
                                                          Toasts.show(
                                                            context,
                                                            'Members can only be added',
                                                            type:
                                                                ToastType.info,
                                                          );
                                                        } else {
                                                          AuthProvider auth =
                                                              Provider.of<
                                                                AuthProvider
                                                              >(
                                                                context,
                                                                listen: false,
                                                              );
                                                          setState(() {
                                                            if (e['userId'] ==
                                                                auth.user!.id) {
                                                              Toasts.show(
                                                                context,
                                                                'Owner cannot be removed',
                                                                type:
                                                                    ToastType
                                                                        .info,
                                                              );
                                                            } else {
                                                              int
                                                              ind = groupMembers
                                                                  .indexWhere(
                                                                    (ele) =>
                                                                        ele['userId'] ==
                                                                        e['userId'],
                                                                  );
                                                              groupMembers
                                                                  .removeAt(
                                                                    ind,
                                                                  );
                                                              Toasts.show(
                                                                context,
                                                                'Member ${e['userName']} removed',
                                                                type:
                                                                    ToastType
                                                                        .info,
                                                              );
                                                            }
                                                          });
                                                        }
                                                      },
                                                      child: SizedBox(
                                                        width: 85.0,
                                                        child: Column(
                                                          children: [
                                                            CircleAvatar(
                                                              maxRadius: 30.0,
                                                              backgroundImage:
                                                                  NetworkImage(
                                                                    e['userImageUrl'],
                                                                  ),
                                                            ),
                                                            SizedBox(
                                                              height: 5.0,
                                                            ),
                                                            Text(
                                                              e['userName'],
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              softWrap: true,
                                                              maxLines: 2,
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  }).toList()
                                                  ..add(
                                                    GestureDetector(
                                                      onTap: () async {
                                                        /*showAddMembersDialog(
                                                          context,
                                                        );*/
                                                        List<
                                                          Map<String, dynamic>
                                                        >
                                                        selectedList =
                                                            await Navigator.of(
                                                              context,
                                                            ).push(
                                                              MaterialPageRoute(
                                                                builder:
                                                                    (context) =>
                                                                        AddMembersScreen(),
                                                              ),
                                                            ) ??
                                                            [];

                                                        if (selectedList
                                                            .isNotEmpty) {
                                                          setState(() {
                                                            groupMembers.addAll(
                                                              selectedList,
                                                            );
                                                          });
                                                          groupMembers =
                                                              groupMembers
                                                                  .fold<
                                                                    Map<
                                                                      String,
                                                                      Map<
                                                                        String,
                                                                        dynamic
                                                                      >
                                                                    >
                                                                  >(
                                                                    {},
                                                                    (
                                                                      map,
                                                                      item,
                                                                    ) =>
                                                                        map
                                                                          ..[item['userId']] =
                                                                              item,
                                                                  )
                                                                  .values
                                                                  .toList();
                                                          debugPrint(
                                                            'selectedList:::${selectedList.toString()}',
                                                          );
                                                        }
                                                      },
                                                      child: Column(
                                                        children: [
                                                          CircleAvatar(
                                                            maxRadius: 30.0,
                                                            child: Icon(
                                                              Icons.person_add,
                                                            ),
                                                          ),
                                                          SizedBox(height: 5.0),
                                                          Text('Add Members'),
                                                        ],
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
                    ),
                    SizedBox(height: verticalGap),
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
                              if (group.isEmpty) {
                                GroupModel group = GroupModel(
                                  exGroupId: '',
                                  exGroupName: groupNameController.text.trim(),
                                  exGroupDesc: groupDescController.text.trim(),
                                  exGroupImageURL: url.isNotEmpty ? url : '',
                                  exGroupType:
                                      selectedGroupTypeIndex.toString(),
                                  exGroupShared: isGroup,
                                  exGroupMembers: groupMembers,
                                  exGroupOwnerId:
                                      UserModel(
                                        userId: authProv.user!.id,
                                        userName: authProv.user!.displayName!,
                                        userEmail: authProv.user!.email,
                                        userImageUrl: authProv.user!.photoUrl!,
                                        userCreatedOn: '',
                                      ).toJson(),
                                  exGroupCreatedOn: DateFormat(
                                    'yyyy-MM-dd HH:mm:ss',
                                  ).format(DateTime.now()),
                                  expenses: [],
                                  exGroupExpenses: 0,
                                  exGroupIncome: 0,
                                  exGroupMembersBalance: {},
                                  exGroupMembersSettlements: [],
                                );
                                Map<String, dynamic> groupMap = group.toJson();
                                api.createGroup(context, groupMap).then((
                                  Response resp,
                                ) {
                                  Toasts.show(
                                    context,
                                    'Group ${group.exGroupName} created',
                                    type: ToastType.success,
                                  );
                                  clearForm();
                                  Navigator.of(context).pop();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder:
                                          (context) => ExpenseGroupDetailsPage(
                                            groupMap: resp.data,
                                          ),
                                    ),
                                  );
                                });
                              } else {
                                GroupModel group = GroupModel(
                                  exGroupId: this.group['exGroupId'],
                                  exGroupName: groupNameController.text.trim(),
                                  exGroupDesc: groupDescController.text.trim(),
                                  exGroupImageURL: url.isNotEmpty ? url : '',
                                  exGroupType:
                                      selectedGroupTypeIndex.toString(),
                                  exGroupShared: isGroup,
                                  exGroupMembers: groupMembers,
                                  exGroupOwnerId: this.group['exGroupOwnerId'],
                                  exGroupCreatedOn:
                                      this.group['exGroupCreatedOn'],
                                  expenses: this.group['expenses'].toList(),
                                  exGroupExpenses:
                                      this.group['exGroupExpenses'],
                                  exGroupIncome: this.group['exGroupIncome'],
                                  exGroupMembersBalance: {},
                                  exGroupMembersSettlements: [],
                                );
                                Map<String, dynamic> groupMap = group.toJson();
                                api.updateGroup(context, groupMap).then((
                                  Response resp,
                                ) {
                                  Toasts.show(
                                    context,
                                    'Group ${group.exGroupName} updated',
                                    type: ToastType.success,
                                  );
                                  clearForm();
                                  Navigator.pop(context, resp.data);
                                });
                              }
                            }
                          },
                          icon: Icon(
                            group.isNotEmpty
                                ? Icons.edit_outlined
                                : Icons.check,
                          ),
                          label: Text(
                            group.isNotEmpty ? 'Update Group' : 'Create Group',
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
                    SizedBox(height: verticalGap),
                  ],
                ),
              ),
              if (api.isAPILoading) buildLoadingContainer(context: context),
            ],
          );
        },
      ),
    );
  }

  OutlineInputBorder buildOutlineInputBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: BorderSide(width: 0.25),
    );
  }

  void showAddMembersDialog(BuildContext context) {
    memberController.clear();
    DialogUtils.showGenericDialog(
      context: context,
      title: Text(
        'Add Members',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 17.5,
          letterSpacing: 1.5,
        ),
        textAlign: TextAlign.left,
      ),
      message: Form(
        key: _formKey,
        child: TextFormField(
          validator: (String? str) {
            AuthProvider auth = Provider.of<AuthProvider>(
              context,
              listen: false,
            );
            if (str!.trim().isEmpty) {
              return 'Enter an email Id';
            }
            if ((str.trim().compareTo(auth.user!.email)) == 0) {
              return 'Owner cannot be a member';
            }
            return null;
          },
          controller: memberController,
          //autofocus: true,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.none,
          decoration: InputDecoration(
            hintText: 'abc@gmail.com',
            hintStyle: TextStyle(color: Colors.grey, letterSpacing: 1.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(width: 0.1, color: Colors.blue),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(width: 0.1, color: Colors.blue),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(width: 0.1, color: Colors.blue),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(width: 0.1, color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(width: 0.1, color: Colors.red),
            ),
          ),
        ),
      ),
      cancelText: 'Cancel',
      confirmText: 'Add',
      onCancel: () {
        memberController.clear();
        unfocusKeyboard();
        Navigator.of(context).pop();
      },
      onConfirm: () {
        if (_formKey.currentState!.validate()) {
          Navigator.of(context).pop();
          ApiProvider api = Provider.of(context, listen: false);
          api.getUserByEmail(context, memberController.text.trim()).then((
            Response resp,
          ) {
            setState(() {
              if (resp.statusCode == HttpStatus.ok) {
                thisUser = UserModel.fromJson(resp.data);
              } else {
                thisUser = UserModel.empty();
              }
              unfocusKeyboard();
              _showAddMemberBottomSheet(context);
            });
          });
        }
      },
      showCancel: true,
      confirmColor: Colors.lightBlue,
    );
  }

  bool checkForm() {
    if (groupNameController.text.isEmpty) {
      Toasts.show(context, 'Enter Group name', type: ToastType.error);
      return false;
    }
    if (selectedGroupTypeIndex == null) {
      Toasts.show(context, 'Select a Type', type: ToastType.error);
      return false;
    }
    if (isGroup) {
      if (group.isEmpty && groupMembers.isEmpty) {
        Toasts.show(context, 'Add members to group', type: ToastType.error);
        return false;
      } else if (group.isNotEmpty && groupMembers.length == 1) {
        Toasts.show(context, 'Add members to group', type: ToastType.error);
        return false;
      }
    }
    return true;
  }

  clearForm() {
    setState(() {
      groupDescController.clear();
      groupNameController.clear();
      isGroup = false;
      groupMembers = [];
      selectedGroupTypeIndex = null;
    });
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
                      group['exGroupImageURL'] = '';
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

  void _showAddMemberBottomSheet(BuildContext context) {
    showModalBottomSheet(
      showDragHandle: true,
      context: context,
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
                    'Add Member',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Divider(height: 1),
              thisUser.userId.isEmpty
                  ? Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: Text(
                        'Email ${memberController.text.trim()} not found',
                        style: TextStyle(letterSpacing: 1.5),
                      ),
                    ),
                  )
                  : ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(thisUser.userImageUrl),
                    ),
                    title: Text(thisUser.userName),
                    subtitle: Text(thisUser.userEmail),
                    trailing: IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          side: BorderSide(width: 0.25),
                        ),
                      ),
                      icon: Icon(Icons.check),
                      onPressed: () {
                        setState(() {
                          groupMembers.add(thisUser.toJson());
                        });
                        unfocusKeyboard();
                        Navigator.of(context).pop();

                        debugPrint('groupMembers:::${groupMembers.length}');
                      },
                    ),
                  ),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );
  }
}
