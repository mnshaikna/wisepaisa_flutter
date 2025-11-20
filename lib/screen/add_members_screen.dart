import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wisepaise/providers/api_provider.dart';
import 'package:wisepaise/utils/utils.dart';

import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../utils/dialog_utils.dart';

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
  bool isSearching = false;
  List<Map<String, dynamic>> selectedContacts = [], searchedContacts = [];
  final _formKey = GlobalKey<FormState>();
  UserModel searchUser = UserModel.empty();

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
                      keyboardType: TextInputType.emailAddress,
                      onTap: () => setState(() => isSearching = true),
                      onChanged: (String search) {
                        setState(() {
                          searchedContacts =
                              api.showContactsList
                                  .where(
                                    (element) => element['userEmail']
                                        .toLowerCase()
                                        .contains(search.toLowerCase()),
                                  )
                                  .toList();
                        });
                        debugPrint('isSearching:::${isSearching.toString()}');
                        debugPrint('searchText:::${searchCont.text}');
                        debugPrint(
                          'searchedContacts:::${searchedContacts.length}',
                        );
                        debugPrint(
                          'listPresent?${isSearching && searchCont.text.isNotEmpty && searchedContacts.isNotEmpty}',
                        );
                      },
                      onSubmitted: (String search) {
                        if (searchCont.text.isNotEmpty) {
                          unfocusKeyboard();
                          ApiProvider api = Provider.of(context, listen: false);
                          api
                              .getUserByEmail(context, searchCont.text.trim())
                              .then((Response resp) {
                                setState(() {
                                  if (resp.statusCode == HttpStatus.ok) {
                                    searchUser = UserModel.fromJson(resp.data);
                                  } else {
                                    searchUser = UserModel.empty();
                                  }
                                  _showAddMemberBottomSheet(context);
                                });
                              });
                        }
                      },
                      suffixIcon: const Icon(Icons.clear),
                      suffixMode: OverlayVisibilityMode.editing,
                      placeholder: 'Search users by email...',
                      placeholderStyle: Theme.of(
                        context,
                      ).textTheme.titleSmall!.copyWith(
                        letterSpacing: 1.5,
                        color:
                            Theme.of(context).brightness == Brightness.light
                                ? Colors.black54
                                : Colors.white54,
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
                  : ((isSearching && searchCont.text.isNotEmpty)
                      ? searchedContacts.isNotEmpty
                      : api.showContactsList.isNotEmpty)
                  ? ListView.builder(
                    itemCount:
                        isSearching && searchCont.text.isNotEmpty
                            ? searchedContacts.length
                            : api.showContactsList.length,
                    itemBuilder: (context, index) {
                      Map<String, dynamic> contact =
                          isSearching && searchCont.text.isNotEmpty
                              ? searchedContacts.elementAt(index)
                              : api.showContactsList.elementAt(index);

                      bool isSelected = selectedContacts.any(
                        (element) =>
                            element['userEmail'] == contact['userEmail'],
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
                                selectedContacts.add(contact);
                              } else {
                                int ind = selectedContacts.indexWhere(
                                  (element) =>
                                      element['userEmail'] ==
                                      contact['userEmail'],
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
                            contact['userName'],
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(contact['userEmail']),
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
                                contact['userImageUrl'],
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
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Add Member',
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Divider(height: 1),
              searchUser.userId.isEmpty
                  ? Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: Text(
                        'Email ${searchCont.text.trim()} not found',
                        style: TextStyle(letterSpacing: 1.5),
                      ),
                    ),
                  )
                  : ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(searchUser.userImageUrl),
                    ),
                    title: Text(searchUser.userName),
                    subtitle: Text(searchUser.userEmail),
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
                          selectedContacts.add(searchUser.toJson());
                        });
                        unfocusKeyboard();
                        Navigator.of(context).pop();
                        Navigator.of(context).pop(selectedContacts);

                        debugPrint(
                          'selectedContacts:::${selectedContacts.length}',
                        );
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
