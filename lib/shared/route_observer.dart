import 'package:flutter/material.dart';

/// App-wide RouteObserver, registered on GetMaterialApp's navigatorObservers
/// (see main.dart) - lets any screen kept alive in a bottom-nav IndexedStack
/// (which never gets a fresh initState just from a route push/pop on top of
/// it) subscribe via RouteAware and react to didPopNext(), i.e. "a route
/// pushed on top of me was just popped, so I'm visible again". Used by
/// DietPlanScreen (diet_view.dart) to re-arm its scroll-to-current-serving-
/// time behavior whenever the patient returns to it - not just on a bottom
/// nav tab switch (see HomeController.selectedIndex-based re-arm in that
/// same file), but also after e.g. viewing Goal Journey and coming back,
/// which never changes the bottom nav's selected index at all since it's a
/// route pushed on top of the same shell.
final RouteObserver<PageRoute> appRouteObserver = RouteObserver<PageRoute>();
