import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wisepaise/models/user_model.dart';
import 'package:wisepaise/providers/api_provider.dart';
import 'package:wisepaise/utils/utils.dart';

import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../utils/toast.dart';

class AddMembersScreen extends StatefulWidget {
  const AddMembersScreen({super.key});

  @override
  State<AddMembersScreen> createState() => _AddMembersScreenState();
}

class _AddMembersScreenState extends State<AddMembersScreen> {
  @override
  initState() {
    super.initState();
  }

  TextEditingController searchCont = TextEditingController();
  bool isShowHint = false;
  List<Map<String, dynamic>> selectedContacts = [];

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Consumer<ApiProvider>(
      builder: (_, api, __) {
        return Scaffold(
          appBar:
              api.isAPILoading
                  ? null
                  : AppBar(
                    title: CupertinoSearchTextField(
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
                      placeholder: 'Search users by email...',
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
          body:
              api.isAPILoading
                  ? buildLoadingContainer(context: context, showBgColor: true)
                  : api.showContactsList.isNotEmpty
                  ? ListView.builder(
                    itemCount: api.showContactsList.length,
                    itemBuilder: (context, index) {
                      bool isSelected = selectedContacts.any(
                        (element) =>
                            element['userEmail'] ==
                            api.showContactsList.elementAt(index)['userEmail'],
                      );
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5.0),
                        padding: const EdgeInsets.symmetric(vertical: 2.5),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          onTap: () {
                            setState(() {
                              if (!isSelected) {
                                selectedContacts.add(
                                  api.showContactsList.elementAt(index),
                                );
                              } else {
                                int ind = selectedContacts.indexWhere(
                                  (element) =>
                                      element['userEmail'] ==
                                      api.showContactsList.elementAt(
                                        index,
                                      )['userEmail'],
                                );
                                selectedContacts.removeAt(ind);
                              }
                            });
                          },
                          selected: isSelected,
                          selectedTileColor:
                              Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey.shade900
                                  : Colors.grey.shade200,
                          title: Text(
                            api.showContactsList.elementAt(index)['userName'],
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            api.showContactsList.elementAt(index)['userEmail'],
                          ),
                          trailing:
                              isSelected
                                  ? Icon(Icons.check)
                                  : SizedBox.shrink(),
                          leading: SizedBox(
                            width: 50,
                            height: 50,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12.0),
                              child: Image.network(
                                api.showContactsList.elementAt(
                                  index,
                                )['userImageUrl'],
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
                            ),
                          ),
                        ),
                      );
                    },
                  )
                  : Center(
                    child: noDataWidget(
                      'No Email Contacts available!',
                      'Search with EmailId',
                      context,
                    ),
                  ),
          floatingActionButton:
              selectedContacts.isNotEmpty
                  ? FloatingActionButton.extended(
                    onPressed:
                        () => Navigator.of(context).pop(selectedContacts),
                    label: Text(
                      '${selectedContacts.length} selected',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    //icon: Icon(Icons.person_add),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  )
                  : null,
        );
      },
    );
  }
}
