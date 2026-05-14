import 'package:flutter/material.dart';
import '../../screens/driver/create_route_screen.dart.dart';
import '../../screens/driver/driver_document_screen.dart';
import '../../screens/driver/driver_earnings_screen.dart';
import '../../screens/driver/driver_home_screen.dart';
import '../../screens/driver/driver_info_screen.dart';
import '../../screens/driver/live_tracking_screen.dart';
import '../../screens/driver/searching_driver_screen.dart';
import '../../screens/passenger/browse_routes_screen.dart';
import '../../screens/passenger/passenger_home_screen.dart';
import '../../screens/passenger/ride_options_screen.dart';
import '../../screens/driver/route_detail_screen.dart';
import '../../screens/driver/saved_routes_screen.dart';
import '../../screens/passenger/search_location_screen.dart';
import '../../screens/shared/auth_screen.dart';
import '../../screens/shared/chat_screen.dart';
import '../../screens/shared/notification_center_screen.dart';
import '../../screens/shared/profile_screen.dart';
import '../../screens/shared/role_selection_screen.dart';
import '../../screens/shared/splash_screen.dart';
import '../../screens/shared/trip_completed_screen.dart';
import '../../screens/shared/trip_history_screen.dart';
import '../../screens/shared/wallet_screen.dart';
import '../localization/app_localizations.dart';
import '../models/route_model.dart';
import '../services/backend_api_service.dart';
import 'app_routes.dart';

class RouteArguments {
  const RouteArguments({this.role, this.data});

  final String? role;
  final Map<String, dynamic>? data;

  static RouteArguments? fromSettings(RouteSettings settings) {
    final args = settings.arguments;
    if (args is RouteArguments) {
      return args;
    }
    if (args is String) {
      return RouteArguments(role: args);
    }
    if (args is Map<String, dynamic>) {
      return RouteArguments(data: args);
    }
    return null;
  }
}

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final routeArguments = RouteArguments.fromSettings(settings);
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case AppRoutes.auth:
        final role = routeArguments?.role ?? 'passenger';
        return MaterialPageRoute(
          builder: (context) => AuthScreen(
            role: role,
            onBack: () => Navigator.of(
              context,
            ).pushReplacementNamed(AppRoutes.roleSelection),
            onComplete: () {
              final nextRoute = role == 'driver'
                  ? AppRoutes.driverHome
                  : AppRoutes.passengerHome;
              Navigator.of(context).pushReplacementNamed(nextRoute);
            },
          ),
        );
      case AppRoutes.createDriverRoute:
        return MaterialPageRoute(builder: (_) => const CreateRouteScreen());

      case AppRoutes.roleSelection:
        return MaterialPageRoute(
          builder: (context) => RoleSelectionScreen(
            onSelectRole: (role) {
              Navigator.of(context).pushNamed(AppRoutes.auth, arguments: role);
            },
          ),
        );

      // Shared
      case AppRoutes.profile:
        final role = settings.arguments is String
            ? settings.arguments as String
            : 'passenger';
        return MaterialPageRoute(
          builder: (context) => ProfileScreen(
            role: role,
            onBack: () {
              Navigator.of(context).pop();
            },
          ),
        );
      case AppRoutes.liveTracking:
        final args = routeArguments?.data;

        return MaterialPageRoute(
          builder: (context) => LiveTrackingScreen(
            pickup: args?['pickup'] ?? '',
            destination: args?['destination'] ?? '',
            rideStatus: args?['rideStatus'] ?? 'pending',
            demoRequests:
                (args?['demoRequests'] as List<dynamic>?)
                    ?.whereType<Map<String, dynamic>>()
                    .toList() ??
                const [],
            onCancel: () {
              Navigator.of(context).pop();
            },
          ),
        );

      case AppRoutes.wallet:
        return MaterialPageRoute(
          builder: (context) =>
              WalletScreen(onBack: () => Navigator.of(context).pop()),
        );

      case AppRoutes.tripHistory:
        return MaterialPageRoute(
          builder: (context) =>
              TripHistoryScreen(onBack: () => Navigator.of(context).pop()),
        );

      // Driver screens
      case AppRoutes.driverHome:
        final args = routeArguments?.data;
        return MaterialPageRoute(
          builder: (_) => DriverHomeScreen(
            isOnline: args?['isOnline'] as bool? ?? false,
            publishedRouteRequest:
                args?['publishedRouteRequest'] as Map<String, dynamic>?,
          ),
        );
      case AppRoutes.driverEarnings:
        return MaterialPageRoute(builder: (_) => const DriverEarningsScreen());
      case AppRoutes.driverDocument:
        return MaterialPageRoute(builder: (_) => const DriverDocumentScreen());
      // In app_router.dart
      case AppRoutes.savedDriverRoutes:
        return MaterialPageRoute(builder: (_) => const SavedRoutesScreen());
      case AppRoutes.driverInfo:
        final args = routeArguments?.data;
        return MaterialPageRoute(
          builder: (_) => DriverInfoScreen(
            driverId: args?['driverId'] as String?,
            driverName: args?['driverName'] as String?,
            driverPhone: args?['driverPhone'] as String?,
            pickup: args?['pickup'] as String? ?? '',
            destination: args?['destination'] as String? ?? '',
            fare: (args?['fare'] as num?)?.toDouble() ?? 0,
            seatsRequested: args?['seatsRequested'] as int? ?? 1,
          ),
        );
      case AppRoutes.driverRouteDetail:
        final route = settings.arguments;
        return MaterialPageRoute(
          builder: (_) =>
              RouteDetailScreen(route: route is RouteModel ? route : null),
        );

      case AppRoutes.chat:
        final args = routeArguments?.data;
        return MaterialPageRoute(
          builder: (_) => ChatScreen(
            role: args?['role'] as String? ?? 'passenger',
            contactName: args?['contactName'] as String? ?? '',
            contactRole: args?['contactRole'] as String?,
            rideId: args?['rideId'] as String?,
            tripInfo: args?['tripInfo'] as String?,
          ),
        );
      case AppRoutes.notificationCenter:
        return MaterialPageRoute(
          builder: (_) => const NotificationCenterScreen(),
        );
      case AppRoutes.passengerHome:
        return MaterialPageRoute(builder: (_) => const PassengerHomeScreen());
      case AppRoutes.searchLocation:
        return MaterialPageRoute(builder: (_) => const SearchLocationScreen());
      case AppRoutes.browseRoutes:
        final args = routeArguments?.data;

        return MaterialPageRoute(
          builder: (_) => BrowseRoutesScreen(
            initialSeats: args?['seats'] ?? 1,
            initialPickup: args?['pickup'] ?? '',
            initialDropoff: args?['dropoff'] ?? '',
          ),
        );
      case AppRoutes.rideOptions:
        return MaterialPageRoute(builder: (_) => const RideOptionsScreen());
      case AppRoutes.tripCompleted:
        final args = routeArguments?.data;
        return MaterialPageRoute(
          builder: (context) => TripCompletedScreen(
            driverName: args?['driverName'] as String? ?? '',
            fare: (args?['fare'] as num?)?.toDouble() ?? 0,
            tripDistance: args?['tripDistance'] as String? ?? '',
            tripDuration: args?['tripDuration'] as String? ?? '',
            seatsUsed: args?['seatsUsed'] as int? ?? 1,
            onClose: () {
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.passengerHome,
                (route) => false,
              );
            },
          ),
        );
      case AppRoutes.searchingDriver:
        final args = routeArguments?.data;
        return MaterialPageRoute(
          builder: (context) => SearchingDriverScreen(
            pickup: args?['pickup'] as String? ?? '',
            destination: args?['destination'] as String? ?? '',
            routeName: args?['routeName'] as String? ?? '',
            driverName: args?['driverName'] as String? ?? '',
            seatsRequested: args?['seatsRequested'] as int? ?? 1,
            onAccepted: () async {
              final navigator = Navigator.of(context);
              final tripId = args?['tripId'] as String? ?? '';
              if (tripId.isNotEmpty) {
                try {
                  await BackendApiService().updateTripStatus(
                    tripId: tripId,
                    status: 'accepted',
                  );
                } catch (_) {
                  // Keep the fake demo flow moving even if the status sync fails.
                }
              }
              navigator.pushReplacementNamed(
                AppRoutes.tripCompleted,
                arguments: {
                  'driverName': args?['driverName'] as String? ?? 'Driver',
                  'fare': (args?['fare'] as num?)?.toDouble() ?? 6500,
                  'tripDistance': args?['tripDistance'] as String? ?? '5.0 km',
                  'tripDuration': args?['tripDuration'] as String? ?? '18 min',
                  'seatsUsed': args?['seatsRequested'] as int? ?? 1,
                },
              );
            },
          ),
        );

      default:
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Center(child: Text(context.l10n.text('routeNotFound'))),
          ),
        );
    }
  }
}
