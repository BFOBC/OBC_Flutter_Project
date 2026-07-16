import 'package:flutter/widgets.dart';

class LoggingNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    print("NAV ▶ pushed: ${route.settings.name ?? route.runtimeType} | previous: ${previousRoute?.settings.name ?? previousRoute?.runtimeType}");
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    print("NAV ◀ popped: ${route.settings.name ?? route.runtimeType} | resumed: ${previousRoute?.settings.name ?? previousRoute?.runtimeType}");
    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    print("NAV ⨂ removed: ${route.settings.name ?? route.runtimeType}");
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    print("NAV ⇄ replaced ${oldRoute?.settings.name ?? oldRoute?.runtimeType} -> ${newRoute?.settings.name ?? newRoute?.runtimeType}");
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}
