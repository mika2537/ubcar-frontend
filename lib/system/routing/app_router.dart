import 'package:flutter/material.dart';
import '../../screens/driver/create_route_screen.dart.dart';
import '../../screens/driver/driver_document_screen.dart';
import '../../screens/driver/driver_earnings_screen.dart';
import '../../screens/driver/driver_home_screen.dart';
import '../../screens/driver/driver_info_screen.dart';
import '../../screens/driver/live_tracking_screen.dart';
import '../../screens/driver/searching_driver_screen.dart';
import '../../screens/passenger/browse_routes_screen.dart';
import '../../screens/passenger/create_route_screen.dart';
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
import 'app_routes.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case AppRoutes.auth:
        final role = settings.arguments is String ? settings.arguments as String : 'passenger';
        return MaterialPageRoute(
          builder: (context) => AuthScreen(
            role: role,
            onBack: () => Navigator.of(context).pushReplacementNamed(AppRoutes.roleSelection),
            onComplete: () {
              final nextRoute = role == 'driver' ? AppRoutes.driverHome : AppRoutes.passengerHome;
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
        final role = settings.arguments is String ? settings.arguments as String : 'passenger';
        return MaterialPageRoute(
          builder: (context) => ProfileScreen(
            role: role,
            onBack: () {
              Navigator.of(context).pop();
            },
          ),
        );
      case AppRoutes.liveTracking:
      // Extract arguments if they exist
        final args = settings.arguments as Map<String, dynamic>?;

        return MaterialPageRoute(
          builder: (context) => LiveTrackingScreen( // Changed _ to context
            pickup: args?['pickup'] ?? 'Default Pickup',
            destination: args?['destination'] ?? 'Default Destination',
            rideStatus: args?['rideStatus'] ?? 'pending',
            onCancel: () {
              Navigator.of(context).pop(); // Wrapped in braces to fix 'void' return error
            },
          ),
        );

      case AppRoutes.wallet:
        return MaterialPageRoute(
          builder: (context) => WalletScreen(
            onBack: () => Navigator.of(context).pop(),
          ),
        );

      case AppRoutes.tripHistory:
        return MaterialPageRoute(
          builder: (context) => TripHistoryScreen(
            onBack: () => Navigator.of(context).pop(),
          ),
        );

    // Driver screens
      case AppRoutes.driverHome:
        return MaterialPageRoute(builder: (_) => const DriverHomeScreen());
      case AppRoutes.driverEarnings:
        return MaterialPageRoute(builder: (_) => const DriverEarningsScreen());
      case AppRoutes.driverDocument:
        return MaterialPageRoute(builder: (_) => const DriverDocumentScreen());
    // In app_router.dart
      case AppRoutes.savedDriverRoutes:
        return MaterialPageRoute(builder: (_) => const SavedRoutesScreen());
      case AppRoutes.driverInfo:
        return MaterialPageRoute(builder: (_) => const DriverInfoScreen());
      // This now points to the driver-centric saved routes screen
        return MaterialPageRoute(builder: (_) => const SavedRoutesScreen());
      case AppRoutes.driverRouteDetail:
        return MaterialPageRoute(builder: (_) => const RouteDetailScreen());

      case AppRoutes.chat:
        return MaterialPageRoute(builder: (_) => const ChatScreen());
      case AppRoutes.notificationCenter:
        return MaterialPageRoute(builder: (_) => const NotificationCenterScreen());
      case AppRoutes.passengerHome:
        return MaterialPageRoute(builder: (_) => const PassengerHomeScreen());
      case AppRoutes.searchLocation:
        return MaterialPageRoute(builder: (_) => const SearchLocationScreen());
      case AppRoutes.browseRoutes:
        return MaterialPageRoute(builder: (_) => const BrowseRoutesScreen());
      case AppRoutes.rideOptions:
        return MaterialPageRoute(builder: (_) => const RideOptionsScreen());
      case AppRoutes.tripCompleted:
        return MaterialPageRoute(builder: (_) => const TripCompletedScreen());
      case AppRoutes.searchingDriver:
        return MaterialPageRoute(builder: (_) => const SearchingDriverScreen());
      case AppRoutes.browseRoutes:
      // Extract arguments as a Map
        final args = settings.arguments as Map<String, dynamic>?;

        return MaterialPageRoute(
          builder: (_) => BrowseRoutesScreen(
            initialSeats: args?['seats'] ?? 1,
            initialPickup: args?['pickup'] ?? '',
            initialDropoff: args?['dropoff'] ?? '',
          ),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(body: Center(child: Text('Route not found'))),
        );
    }
  }
}