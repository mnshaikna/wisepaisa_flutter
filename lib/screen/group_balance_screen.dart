import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wisepaise/providers/api_provider.dart';
import 'package:wisepaise/providers/auth_provider.dart';
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
  List<dynamic> settlements = [];
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
    debugPrint('group:::$group');
    balances = group['exGroupMembersBalance'] ?? {};
    settlements = group['exGroupMembersSettlements'] ?? [];
    await Future.microtask(() async {
      ApiProvider api = Provider.of<ApiProvider>(context, listen: false);
      balances.keys.map((userId) async {
        await api.getUserById(context, userId).then((Response resp) {
          users.add(resp.data);
        });
      }).toList();
    });
    setState(() {
      isLoading = false;
    });
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
              (balances.isEmpty || settlements.isEmpty)
                  ? Center(
                    child: noDataWidget(
                      'No Settlements',
                      'Settlements and balances not available',
                      context,
                    ),
                  )
                  : ListView(
                    physics: const BouncingScrollPhysics(),
                    children:
                        balances.keys.map((key) {
                          debugPrint('key:::$key');
                          Map<String, dynamic> thisUser = users.firstWhere(
                            (ele) => ele['userId'] == key,
                          );
                          debugPrint('thisUser:::$thisUser');

                          final double amount = balances[key];
                          final bool isPositive = amount > 0;

                          return ExpansionTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(
                                thisUser['userImageUrl'],
                              ),
                              radius: 25.0,
                            ),
                            title: Text(
                              thisUser['userName'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17.5,
                              ),
                            ),
                            subtitle: Text(
                              isPositive
                                  ? 'gets back ${formatCurrency(amount, context)}'
                                  : 'owes ${formatCurrency((amount * -1), context)}',
                              style: TextStyle(
                                color: isPositive ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.25,
                                fontSize: 13.0,
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
                                    Map<String, dynamic> fromUserMap = users
                                        .firstWhere(
                                          (ele) => ele['userId'] == fromUser,
                                        );

                                    Map<String, dynamic> toUserMap = users
                                        .firstWhere(
                                          (ele) => ele['userId'] == toUser,
                                        );

                                    return ListTile(
                                      leading: CircleAvatar(
                                        radius: 15.0,
                                        backgroundImage: NetworkImage(
                                          key == fromUser
                                              ? toUserMap['userImageUrl']
                                              : fromUserMap['userImageUrl'],
                                        ),
                                      ),
                                      title: RichText(
                                        text: TextSpan(
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12.5,
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
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blueAccent,
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
        );
      },
    );
  }
}
