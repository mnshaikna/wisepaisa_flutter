import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:wisepaise/models/user_model.dart';
import 'package:wisepaise/providers/api_provider.dart';

import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../utils/toast.dart';
import '../utils/utils.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  TextEditingController nameController = TextEditingController(),
      emailController = TextEditingController(),
      dateController = TextEditingController();
  Uint8List? imageBytes;

  @override
  void initState() {
    super.initState();
    AuthProvider authProvider = Provider.of<AuthProvider>(
      context,
      listen: false,
    );

    if (authProvider.thisUser!.isNotEmpty) {
      nameController.text = authProvider.thisUser!['userName'];
      emailController.text = authProvider.thisUser!['userEmail'];
      dateController.text = authProvider.thisUser!['userCreatedOn'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Edit Profile',
          style: theme.textTheme.titleLarge!.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Consumer2<ApiProvider, AuthProvider>(
        builder: (_, api, authProvider, __) {
          return Stack(
            children: [
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height / 5.5,
                        ),
                        Stack(
                          children: [
                            Container(
                              height: 150.0,
                              width: 150.0,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  fit: BoxFit.cover,
                                  image:
                                      imageBytes != null
                                          ? MemoryImage(imageBytes!)
                                          : NetworkImage(
                                            authProvider
                                                .thisUser!['userImageUrl'],
                                          ),
                                ),
                              ),
                            ),
                            Container(
                              height: 150.0,
                              width: 150.0,

                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white10,
                              ),
                              child: IconButton(
                                style: IconButton.styleFrom(
                                  backgroundColor:
                                      theme.brightness == Brightness.dark
                                          ? Colors.black54
                                          : Colors.white70,
                                ),
                                onPressed:
                                    () => _showAttachmentOptions(context),
                                icon: Icon(Icons.edit),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 15.0),
                        TextField(
                          controller: nameController,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            labelText: 'Name',
                            labelStyle: labelStyle(context),
                            border: buildOutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 15.0),
                        TextField(
                          controller: emailController,
                          enabled: false,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: labelStyle(context),
                            border: buildOutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 15.0),
                        TextField(
                          controller: dateController,
                          enabled: false,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            labelText: 'Created On',
                            labelStyle: labelStyle(context),
                            border: buildOutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 20.0),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              ApiProvider api = Provider.of<ApiProvider>(
                                context,
                                listen: false,
                              );

                              String url = "";
                              if (checkForm()) {
                                if (imageBytes != null) {
                                  url = await uploadImage(
                                    imageBytes!,
                                    '${Random().nextInt(1000000)}',
                                    context,
                                  );
                                }
                                UserModel user = UserModel(
                                  userId: authProvider.thisUser!['userId'],
                                  userName: nameController.text,
                                  userEmail: emailController.text,
                                  userImageUrl:
                                      url.isEmpty
                                          ? authProvider
                                              .thisUser!['userImageUrl']
                                          : url,
                                  userCreatedOn: dateController.text,
                                );
                                api.updateUser(context, user.toJson()).then((
                                  Response resp,
                                ) {
                                  if (resp.statusCode == HttpStatus.ok) {
                                    Toasts.show(
                                      context,
                                      'User Data Updated',
                                      type: ToastType.info,
                                    );
                                    Navigator.of(context).pop(resp.data);
                                  }
                                });
                              }
                            },
                            icon: Icon(Icons.edit),
                            label: Text('Update User'),
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
                              textStyle: theme.textTheme.titleMedium!.copyWith(
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
      Toasts.show(context, 'Please enter name', type: ToastType.error);
      return false;
    }
    return true;
  }
}
