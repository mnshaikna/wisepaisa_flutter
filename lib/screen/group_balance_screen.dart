import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wisepaise/providers/api_provider.dart';
import 'package:wisepaise/utils/utils.dart';

class GroupBalanceScreen extends StatefulWidget {
  Map<String, dynamic> group;

  GroupBalanceScreen({super.key, required this.group});

  @override
  State<GroupBalanceScreen> createState() =>
      _GroupBalanceScreenState(group: group);
}

class _GroupBalanceScreenState extends State<GroupBalanceScreen> {
  Map<String, dynamic> group;

  _GroupBalanceScreenState({required this.group});

  Map<String, dynamic> balances = {};
  List<Map<String, dynamic>> users = [];

  List<dynamic> settlements = [], groupMembers = [], remainingMembers = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  init() async {
    setState(() {
      isLoading = true;
    });
    balances = group['exGroupMembersBalance'] ?? {};
    settlements = group['exGroupMembersSettlements'] ?? [];
    groupMembers = group['exGroupMembers'] ?? [];
    await Future.microtask(() async {
      ApiProvider api = Provider.of<ApiProvider>(context, listen: false);
      balances.keys.map((userId) async {
        Map<String, dynamic> myUser = api.allUsers.firstWhere(
          (ele) => ele['userId'] == userId,
          orElse: () => {},
        );
        users.add(myUser);
      }).toList();
    });

    groupMembers.map((ele) {
      if (!balances.containsKey(ele['userId'])) {
        remainingMembers.add(ele);
      }
    }).toList();

    setState(() {
      isLoading = false;
    });

    debugPrint('balances:::$balances');
    debugPrint('settlements:::${settlements.toString()}');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ApiProvider>(
      builder: (_, api, __) {
        if (api.isAPILoading || isLoading) {
          return buildLoadingContainer(context: context);
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Balances'), centerTitle: true),
          body:
              (remainingMembers.isEmpty &&
                      balances.isEmpty &&
                      settlements.isEmpty)
                  ? Center(
                    child: noDataWidget(
                      'No Settlements',
                      'Settlements and balances not available',
                      context,
                    ),
                  )
                  : ListView(
                    physics: BouncingScrollPhysics(),
                    children: [
                      if (balances.isNotEmpty)
                        Column(
                          children:
                              balances.keys.map((key) {
                                Map<String, dynamic> thisUser = users
                                    .firstWhere(
                                      (ele) => ele['userId'] == key,
                                      orElse: () => {},
                                    );

                                final double amount = balances[key];
                                final bool isPositive = amount > 0;

                                return ExpansionTile(
                                  tilePadding: EdgeInsets.symmetric(
                                    horizontal: 15.0,
                                    vertical: 5.0,
                                  ),
                                  leading:
                                      thisUser['userImageUrl'] != null
                                          ? CircleAvatar(
                                            backgroundImage: NetworkImage(
                                              thisUser['userImageUrl'],
                                            ),
                                            radius: 25.0,
                                          )
                                          : Container(
                                            height: 25.0,
                                            width: 25.0,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade500,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                  title: Text(
                                    thisUser['userName'] ?? '',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium!
                                        .copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    isPositive
                                        ? 'gets back ${formatCurrency(amount, context)}'
                                        : 'owes ${formatCurrency((amount * -1), context)}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelMedium!.copyWith(
                                      color:
                                          isPositive
                                              ? Colors.green
                                              : Colors.red,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.25,
                                    ),
                                  ),
                                  childrenPadding: EdgeInsets.only(left: 25.0),
                                  minTileHeight: 75.0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),

                                  children:
                                      settlements.map<Widget>((settle) {
                                        String fromUser = settle['fromUserId'];
                                        String toUser = settle['toUserId'];
                                        double amount = settle['amount'];

                                        if (fromUser == key || toUser == key) {
                                          Map<String, dynamic> fromUserMap =
                                              users.firstWhere(
                                                (ele) =>
                                                    ele['userId'] == fromUser,
                                                orElse: () => {},
                                              );

                                          Map<String, dynamic> toUserMap = users
                                              .firstWhere(
                                                (ele) =>
                                                    ele['userId'] == toUser,
                                                orElse: () => {},
                                              );

                                          return ListTile(
                                            leading:
                                                toUserMap['userImageUrl'] !=
                                                            null &&
                                                        fromUserMap['userImageUrl'] !=
                                                            null
                                                    ? CircleAvatar(
                                                      radius: 15.0,
                                                      backgroundImage: NetworkImage(
                                                        key == fromUser
                                                            ? toUserMap['userImageUrl']
                                                            : fromUserMap['userImageUrl'],
                                                      ),
                                                    )
                                                    : Container(
                                                      height: 15.0,
                                                      width: 15.0,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color:
                                                            Colors
                                                                .grey
                                                                .shade500,
                                                      ),
                                                    ),
                                            title: RichText(
                                              text: TextSpan(
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelMedium!
                                                    .copyWith(
                                                      color:
                                                          Colors.grey.shade500,
                                                    ),
                                                children: [
                                                  TextSpan(
                                                    text:
                                                        '${fromUserMap['userName']} owes ',
                                                  ),
                                                  TextSpan(
                                                    text: formatCurrency(
                                                      amount,
                                                      context,
                                                    ),
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium!
                                                        .copyWith(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              Colors.blueAccent,
                                                        ),
                                                  ),
                                                  TextSpan(
                                                    text:
                                                        ' to ${toUserMap['userName']}',
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }
                                        return SizedBox.shrink();
                                      }).toList(),
                                );
                              }).toList(),
                        ),
                      if (remainingMembers.isNotEmpty)
                        Column(
                          children:
                              remainingMembers.map<Widget>((ele) {
                                return ExpansionTile(
                                  tilePadding: EdgeInsets.symmetric(
                                    horizontal: 15.0,
                                    vertical: 5.0,
                                  ),
                                  leading:
                                      ele['userImageUrl'] != null
                                          ? CircleAvatar(
                                            backgroundImage: NetworkImage(
                                              ele['userImageUrl'],
                                            ),
                                            radius: 25.0,
                                          )
                                          : Container(
                                            height: 25.0,
                                            width: 25.0,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade500,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                  title: Text(
                                    ele['userName'] ?? '',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium!
                                        .copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    'No balance',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelMedium!.copyWith(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.normal,
                                      letterSpacing: 1.25,
                                    ),
                                  ),
                                  childrenPadding: EdgeInsets.only(left: 25.0),
                                  minTileHeight: 75.0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                );
                              }).toList(),
                        ),
                    ],
                  ),
        );
      },
    );
  }
}
