import 'package:flutter/material.dart';
import 'package:silvio/hive/adapters.dart';

abstract class Api {
  Account account;
  Api(this.account);

  Future<void> refreshProfilePicture(Person person) async {}
  Future<void> refreshCalendarEvents(Person person) async {}
  Future<void> refreshGrade(Person person, Grade grade) async {}
  Future<void> refreshSchoolYear(Person person, SchoolYear schoolYear,
      void Function(int completed, int total) progress) async {}
  Future<void> logout() async {}

  Widget buildLogin(BuildContext context);
  Widget? buildConfig(BuildContext context, {required Person person});
}