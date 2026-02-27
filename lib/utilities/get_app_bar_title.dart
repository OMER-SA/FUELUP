import 'package:diet_app/utilities/string_extension.dart';

String getRouteTitle(String route, Map<String, String> routeTitles) {
  List<String> splitedpath = route.split('/');
  String lastPath = splitedpath.last;
  String? routeTitle = routeTitles.entries
      .where((entry) => route.contains(entry.key))
      .map((entry) => entry.value)
      .firstOrNull;

  if (routeTitle != null) {
    return routeTitle;
  }
  return lastPath.toCapitalized();
}
