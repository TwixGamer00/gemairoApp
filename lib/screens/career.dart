import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart';
import 'package:gemairo/widgets/ads.dart';
import 'package:gemairo/widgets/appbar.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:gemairo/apis/account_manager.dart';
import 'package:gemairo/hive/adapters.dart';
import 'package:gemairo/hive/extentions.dart';

import 'package:gemairo/widgets/card.dart';
import 'package:gemairo/widgets/charts/linechart_monthly_average.dart';
import 'package:gemairo/widgets/facts_header.dart';
import 'package:gemairo/widgets/filter.dart';
import 'package:gemairo/widgets/charts/barchart_frequency.dart';
import 'package:gemairo/widgets/charts/linechart_grades.dart';
import 'package:gemairo/widgets/cards/list_grade.dart';

class CareerOverview extends StatefulWidget {
  const CareerOverview({super.key});

  @override
  State<CareerOverview> createState() => _CareerOverview();
}

class _CareerOverview extends State<CareerOverview> {
  void addOrRemoveBadge(bool value, GradeListBadges badge) {
    if (value == true) {
      config.activeBadges.add(badge);
    } else {
      config.activeBadges.remove(badge);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final AccountProvider acP = Provider.of<AccountProvider>(context);
    List<Grade> allGrades = acP.person.allGrades
      ..sort((Grade a, Grade b) => b.addedDate.millisecondsSinceEpoch
          .compareTo(a.addedDate.millisecondsSinceEpoch));
    List<Grade> grades = allGrades.onlyFilterd(acP.person.activeFilters);

    List<Widget> widgets = [
      if (grades.isNotEmpty) ...[
        if (grades.numericalGrades.length > 1)
          StaggeredGridTile.fit(
              crossAxisCellCount: 2,
              child: GemairoCard(
                child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: LineChartGrades(
                      grades: grades,
                      showAverage: true,
                    )),
              )),
        if (grades.numericalGrades.isNotEmpty)
          StaggeredGridTile.fit(
              crossAxisCellCount: 2,
              child: GemairoCard(
                  title: Text(AppLocalizations.of(context)!.histogram),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: BarChartFrequency(
                      grades: grades,
                    ),
                  ))),
        if (grades.numericalGrades.isNotEmpty &&
            grades
                    .map((g) => DateTime.parse(
                        DateFormat('yyyy-MM-01').format(g.addedDate)))
                    .toList()
                    .unique()
                    .length >
                1)
          StaggeredGridTile.fit(
              crossAxisCellCount: 2,
              child: GemairoCard(
                  title: Text(AppLocalizations.of(context)!.monthlyAverage),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    child: MonthlyLineChartGrades(
                      grades: grades,
                      showAverage: true,
                    ),
                  ))),
        StaggeredGridTile.fit(
            crossAxisCellCount: 4,
            child: GemairoCard(
                title: Text(AppLocalizations.of(context)!.grades),
                trailing: GradeListOptions(
                  addOrRemoveBadge: addOrRemoveBadge,
                ),
                child: GradeList(
                    showGradeCalculate: true,
                    grades: grades
                        .where((grade) => grade.type == GradeType.grade)
                        .toList())))
      ],
    ];

    return Scaffold(
      appBar: GemairoAppBar(
          enableYearSwitcher: false,
          title: AppLocalizations.of(context)!.searchStatistics),
      body: RefreshIndicator(
          onRefresh: () async {
            await acP.account.api.refreshAll(acP.person);
            acP.changeAccount(null);
          },
          child: BottomBanner(
            child: ListView(children: [
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: FactsHeader(
                    grades: grades.useable,
                  )),
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: FilterChips(
                    isGlobal: true,
                    grades: allGrades,
                  )),
              GemairoCardList(
                maxCrossAxisExtent: 250,
                children: widgets,
              )
            ]),
          )),
    );
  }
}
