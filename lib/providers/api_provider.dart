import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../utils/constants.dart';
import '../utils/toast.dart';
import 'auth_provider.dart';

class ApiProvider extends ChangeNotifier {
  final dio = Dio();
  bool isAPILoading = false, isTimedOut = false;
  List<Map<String, dynamic>> groupList = [],
      expenseReminderList = [],
      userExpenseList = [],
      savingsGoalList = [],
      contactsWithEmail = [],
      allUsers = [],
      showContactsList = [];

  setLoading() {
    isAPILoading = true;
    notifyListeners();
  }

  removeLoading() {
    isAPILoading = false;
    notifyListeners();
  }

  setExpenseList(List<Map<String, dynamic>> list) {
    userExpenseList = list;
    notifyListeners();
  }

  setGroupList(List<Map<String, dynamic>> list) {
    groupList = list;
    notifyListeners();
  }

  Future<Response> getHttp(
    BuildContext context,
    String baseUrl,
    String method, {
    Map<String, dynamic>? requestBody,
  }) async {
    debugPrint('baseUrl:::$baseUrl');
    debugPrint('requestBody:::${requestBody.toString()}');
    debugPrint('httpMethod:::$method');
    setTimedOut(false);
    setLoading();
    Response? response;

    final credentials = base64Encode(utf8.encode('$username:$password'));
    final basicAuth = 'Basic $credentials';

    try {
      dio.options.connectTimeout = Duration(seconds: 15);
      response = await dio.request(
        baseUrl,
        data: requestBody ?? {},
        options: Options(
          sendTimeout: Duration(seconds: 15),
          receiveTimeout: Duration(seconds: 15),
          method: method,
          headers: {'Authorization': basicAuth},
          responseType: ResponseType.json,
        ),
      );

      debugPrint('Response from API:::${response.data.toString()}');
    } on DioException catch (e) {
      debugPrint(e.type.toString());
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        setTimedOut(true);
        Toasts.show(
          context,
          'Connection error occurred !!!',
          type: ToastType.error,
        );
      } else {
        debugPrint(e.response!.data.toString());
        response = e.response;
        debugPrint('Error occurred during API invocation');
        debugPrint('Error is :::${e.response?.toString() ?? e.toString()}');
      }
    } finally {
      removeLoading();
    }
    return Future.value(response);
  }

  Future<Response> createGroup(
    BuildContext context,
    Map<String, dynamic> body,
  ) async {
    var finalUrl = '$baseUrl/expenseGroup/create';
    Response resp = await getHttp(context, finalUrl, 'POST', requestBody: body);
    groupList.add(resp.data);
    notifyListeners();
    return resp;
  }

  Future<Response> updateGroup(
    BuildContext context,
    Map<String, dynamic> body,
  ) async {
    var finalUrl = '$baseUrl/expenseGroup/update';
    Response resp = await getHttp(context, finalUrl, 'PUT', requestBody: body);
    notifyListeners();
    return resp;
  }

  Future getGroups(String userId, BuildContext context) async {
    var finalUrl = '$baseUrl/expenseGroup/user/$userId';
    groupList = [];
    try {
      await getHttp(context, finalUrl, 'GET').then((Response resp) {
        debugPrint('resp:::${resp.data}');
        groupList = (resp.data as List).cast<Map<String, dynamic>>();
      });
    } catch (e) {
      debugPrint('Error Occurred:::$e');
    }
    debugPrint('groupList Length:::${groupList.length}');
    notifyListeners();
  }

  Future<Response> deleteGroups(String groupId, BuildContext context) async {
    var finalUrl = '$baseUrl/expenseGroup/delete/$groupId';
    Response resp = await getHttp(context, finalUrl, 'DELETE');
    notifyListeners();
    return resp;
  }

  Future getReminders(String userId, BuildContext context) async {
    var finalUrl = '$baseUrl/expenseReminder/user/$userId';
    expenseReminderList = [];
    try {
      await getHttp(context, finalUrl, 'GET').then((Response resp) {
        debugPrint('resp:::${resp.data}');
        expenseReminderList = (resp.data as List).cast<Map<String, dynamic>>();
        expenseReminderList.sort((a, b) {
          final dateA = DateTime.parse(a['reminderDate']);
          final dateB = DateTime.parse(b['reminderDate']);
          return dateA.compareTo(dateB);
        });
      });
    } catch (e) {
      debugPrint('Error Occurred:::$e');
    }
    debugPrint('expenseReminderList Length:::${expenseReminderList.length}');
    notifyListeners();
  }

  Future<Response> createReminder(
    BuildContext context,
    Map<String, dynamic> body,
  ) async {
    var finalUrl = '$baseUrl/expenseReminder/create';
    Response resp = await getHttp(context, finalUrl, 'POST', requestBody: body);
    expenseReminderList.add(body);
    notifyListeners();
    return resp;
  }

  Future<Response> deleteReminder(BuildContext context, String remId) async {
    var finalUrl = '$baseUrl/expenseReminder/delete/$remId';
    Response resp = await getHttp(context, finalUrl, 'DELETE');
    notifyListeners();
    return resp;
  }

  Future<Response> updateReminder(
    BuildContext context,
    Map<String, dynamic> body,
  ) async {
    debugPrint('updateReminder:::$body');
    var finalUrl = '$baseUrl/expenseReminder/update';
    Response resp = await getHttp(context, finalUrl, 'PUT', requestBody: body);
    notifyListeners();
    return resp;
  }

  updateRemindersList(List<Map<String, dynamic>> newList) {
    expenseReminderList = newList;
    notifyListeners();
  }

  Future getUserExpenses(String userId, BuildContext context) async {
    var finalUrl = '$baseUrl/expense/user/$userId';
    userExpenseList = [];
    try {
      await getHttp(context, finalUrl, 'GET').then((Response resp) {
        debugPrint('resp:::${resp.data}');
        userExpenseList = (resp.data as List).cast<Map<String, dynamic>>();
      });
    } catch (e) {
      debugPrint('Error Occurred:::$e');
    }
    debugPrint('userExpenseList Length:::${userExpenseList.length}');
    notifyListeners();
  }

  Future<Response> createExpense(
    BuildContext context,
    Map<String, dynamic> body,
  ) async {
    var finalUrl = '$baseUrl/expense/create';
    Response resp = await getHttp(context, finalUrl, 'POST', requestBody: body);
    userExpenseList.add(body);
    notifyListeners();
    return resp;
  }

  Future<Response> updateExpense(
    BuildContext context,
    Map<String, dynamic> body,
  ) async {
    var finalUrl = '$baseUrl/expense/update';
    Response resp = await getHttp(context, finalUrl, 'PUT', requestBody: body);
    userExpenseList.removeWhere((exp) => exp['expenseId'] == body['expenseId']);
    userExpenseList.add(body);
    notifyListeners();
    return resp;
  }

  Future<Response> deleteExpense(BuildContext context, String expId) async {
    var finalUrl = '$baseUrl/expense/delete/$expId';
    Response resp = await getHttp(context, finalUrl, 'DELETE');
    notifyListeners();
    return resp;
  }

  void setTimedOut(bool timedOut) {
    isTimedOut = timedOut;
    notifyListeners();
  }

  Future<Response> createUser(
    BuildContext context,
    Map<String, dynamic> body,
  ) async {
    var finalUrl = '$baseUrl/users/create';
    Response resp = await getHttp(context, finalUrl, 'POST', requestBody: body);
    notifyListeners();
    return resp;
  }

  Future<Response> updateUser(
    BuildContext context,
    Map<String, dynamic> body,
  ) async {
    var finalUrl = '$baseUrl/users/update';
    Response resp = await getHttp(context, finalUrl, 'PUT', requestBody: body);
    notifyListeners();
    return resp;
  }

  Future<Response> deleteUser(BuildContext context, String userId) async {
    var finalUrl = '$baseUrl/users/delete/$userId';
    Response resp = await getHttp(context, finalUrl, 'DELETE');
    notifyListeners();
    return resp;
  }

  Future<Response> getUserByEmail(BuildContext context, String emailId) async {
    var finalUrl = '$baseUrl/users/get/emailId/$emailId';
    Response resp = await getHttp(context, finalUrl, 'GET');
    notifyListeners();
    return resp;
  }

  Future<Response> getUserById(BuildContext context, String userId) async {
    var finalUrl = '$baseUrl/users/get/userId/$userId';
    Response resp = await getHttp(context, finalUrl, 'GET');
    notifyListeners();
    return resp;
  }

  Future<Response> getAllUsers(BuildContext context) async {
    var finalUrl = '$baseUrl/users/all';
    Response resp = await getHttp(context, finalUrl, 'GET');
    notifyListeners();
    return resp;
  }

  Future<Response> createGoal(
    BuildContext context,
    Map<String, dynamic> body,
  ) async {
    var finalUrl = '$baseUrl/savingsGoal/create';
    Response resp = await getHttp(context, finalUrl, 'POST', requestBody: body);
    notifyListeners();
    return resp;
  }

  Future getUserGoals(String userId, BuildContext context) async {
    var finalUrl = '$baseUrl/savingsGoal/user/$userId';
    savingsGoalList = [];
    try {
      await getHttp(context, finalUrl, 'GET').then((Response resp) {
        debugPrint('resp:::${resp.data}');
        savingsGoalList = (resp.data as List).cast<Map<String, dynamic>>();
      });
    } catch (e) {
      debugPrint('Error Occurred:::$e');
    }
    debugPrint('savingsGoalList Length:::${savingsGoalList.length}');
    notifyListeners();
  }

  Future<Response> updateGoal(
    BuildContext context,
    Map<String, dynamic> body,
  ) async {
    var finalUrl = '$baseUrl/savingsGoal/update';
    Response resp = await getHttp(context, finalUrl, 'PUT', requestBody: body);
    savingsGoalList.removeWhere(
      (exp) => exp['savingsGoalId'] == body['savingsGoalId'],
    );
    savingsGoalList.add(resp.data);
    notifyListeners();
    return resp;
  }

  Future<Response> deleteGoal(BuildContext context, String goalId) async {
    var finalUrl = '$baseUrl/savingsGoal/$goalId';
    Response resp = await getHttp(context, finalUrl, 'DELETE');
    savingsGoalList.removeWhere((exp) => exp['savingsGoalId'] == goalId);
    notifyListeners();
    return resp;
  }

  getGoogleUsers(BuildContext context) async {
    AuthProvider auth = Provider.of<AuthProvider>(context, listen: false);

    setLoading();
    try {
      await getContacts(context).then((List<Map<String, dynamic>> list) async {
        contactsWithEmail = list.toList();
        await getAllUsers(context).then((Response resp) {
          if (resp.statusCode == HttpStatus.ok) {
            allUsers =
                (resp.data as List<dynamic>)
                    .map((e) => e as Map<String, dynamic>)
                    .toList();

            if (allUsers.isEmpty || contactsWithEmail.isEmpty) {
              showContactsList = [];
            } else {
              for (Map<String, dynamic> googleContact in contactsWithEmail) {
                String googleEmail = googleContact['email'];
                if (allUsers.any((ele) => ele['userEmail'] == googleEmail)) {
                  Map<String, dynamic> dbUser = allUsers.firstWhere(
                    (ele) => ele['userEmail'] == googleEmail,
                    orElse: () => {},
                  );
                  showContactsList.add(
                    UserModel(
                      userId: dbUser['userId'],
                      userName: dbUser['userName'],
                      userEmail: dbUser['userEmail'],
                      userImageUrl: dbUser['userImageUrl'],
                      userCreatedOn: dbUser['userCreatedOn'],
                    ).toJson(),
                  );
                }
              }
            }
            showContactsList.removeWhere(
              (ele) => ele['userId'] == auth.thisUser!['userId'],
            );
          }
        });
      });
      removeLoading();
    } catch (e) {
      debugPrint(e.toString());
      removeLoading();
      Toasts.show(context, 'Error adding members', type: ToastType.error);
      Navigator.of(context).pop();
    }
  }

  Future<List<Map<String, dynamic>>> getContacts(BuildContext context) async {
    Dio dio = Dio();
    AuthProvider auth = Provider.of<AuthProvider>(context, listen: false);
    final header = await auth.user!.authHeaders;
    List<Map<String, dynamic>> allContacts = [];
    String? nextPageToken;

    do {
      final url =
          '$googleContactHost$googleContactPath'
          '${nextPageToken != null ? '&pageToken=$nextPageToken' : ''}';
      final response = await dio.request(
        url,
        options: Options(headers: header),
      );

      if (response.statusCode != 200) {
        debugPrint('Error fetching contacts: ${response.data}');
        break;
      }

      final data = response.data;

      final connections = data['connections'] as List<dynamic>? ?? [];

      // Filter only contacts with email
      final contactsWithEmail =
          connections
              .where(
                (p) =>
                    p['emailAddresses'] != null &&
                    p['emailAddresses'][0]['value']
                        .toString()
                        .toLowerCase()
                        .contains('gmail'),
              )
              .map((p) {
                debugPrint(p.toString());
                return {
                  'userName':
                      (p['names'] != null)
                          ? p['names'][0]['displayName']
                          : 'No Name',
                  'email': p['emailAddresses'][0]['value'],
                  'userImageUrl':
                      (p['photos'] != null) ? p['photos'][0]['url'] : null,
                };
              })
              .toList();

      allContacts.addAll(contactsWithEmail);

      // Get next page token
      nextPageToken = data['nextPageToken'];
    } while (nextPageToken != null);

    debugPrint('✅ Total contacts fetched: ${allContacts.length}');
    return Future.value(allContacts);
  }
}
