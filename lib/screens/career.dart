import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:gemairo/widgets/bottom_sheet.dart';
import 'package:gemairo/widgets/global/skeletons.dart';
import 'package:intl/intl.dart';
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
        StaggeredGridTile.extent(
            mainAxisExtent: 100,
            crossAxisCellCount: 2,
            child: FactCard(
                title: AppLocalizations.of(context)!
                    .percentSufficient
                    .capitalize(),
                value:
                    "${grades.where((grade) => grade.isSufficient).length}/${grades.length}",
                extra: FactCardProgress(
                  value: grades.getPresentageSufficient() / 100,
                ))),
        ...grades.useable
            .generateFactsList(context,
                Provider.of<AccountProvider>(context, listen: false).person)
            .skip(2)
            .map((e) => StaggeredGridTile.extent(
                mainAxisExtent: 100,
                crossAxisCellCount: 1,
                child: FactCard(
                    title: e.title.capitalize(),
                    value: e.value,
                    onTap: e.onTap))),
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
      ],
    ];

    return ScaffoldSkeleton(
        appBar: GemairoAppBar(
            enableYearSwitcher: false,
            title: Text(AppLocalizations.of(context)!.searchStatistics)),
        onRefresh: () async {
          await acP.account.api.refreshAll(acP.person);
          acP.changeAccount(null);
        },
        children: [
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
          ),
          ...grades.sortByDate((e) => e.addedDate, doNotSort: true).entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(children: [
                    ListTile(
                      title: Text(e.key,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.primary)),
                      dense: true,
                    ),
                    ...e.value.map((e) => GradeTile(
                          grade: e,
                          grades: grades,
                          onTap: () => showGemairoModalBottomSheet(children: [
                            GradeInformation(
                              context: context,
                              grade: e,
                              grades: grades,
                              showGradeCalculate: true,
                            )
                          ], context: context),
                        ))
                  ]),
                ),
              )
        ]);
  }
}
