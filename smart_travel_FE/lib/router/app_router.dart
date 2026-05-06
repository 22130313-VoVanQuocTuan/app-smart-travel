import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_travel/presentation/blocs/adminTour/tour_bloc.dart';
import 'package:smart_travel/presentation/blocs/adminTour/tour_detail_bloc.dart';
import 'package:smart_travel/presentation/blocs/adminTour/tour_event.dart';
import 'package:smart_travel/presentation/blocs/admin_audio/audio_bloc.dart';
import 'package:smart_travel/presentation/blocs/admin_audio/audio_event.dart';
import 'package:smart_travel/presentation/blocs/admin_user/admin_user_bloc.dart';
import 'package:smart_travel/presentation/blocs/homestay/homestay_bloc.dart';
import 'package:smart_travel/presentation/blocs/homestay/homestay_detail_bloc.dart';
import 'package:smart_travel/presentation/screens/auth/forgot_password_screen.dart';
import 'package:smart_travel/presentation/screens/auth/login_screen.dart';
import 'package:smart_travel/presentation/screens/auth/register_screen.dart';
import 'package:smart_travel/presentation/screens/destination/detail_destination_screen.dart';
import 'package:smart_travel/presentation/screens/explore/explore_screen.dart';
import 'package:smart_travel/presentation/screens/home/home_screen.dart';
import 'package:smart_travel/presentation/screens/homestay/detail_homestay_screen.dart';
import 'package:smart_travel/presentation/screens/homestay/homestay_list_screen.dart';
import 'package:smart_travel/presentation/screens/homestay/homestay_detail_screen.dart';
import 'package:smart_travel/presentation/screens/splash/splash_screen.dart';
import 'package:smart_travel/presentation/screens/profile/profile_screen.dart';
import 'package:smart_travel/presentation/screens/profile/edit_profile_screen.dart';
import 'package:smart_travel/presentation/screens/profile/change_password_screen.dart';
import 'package:smart_travel/presentation/screens/profile/settings_screen.dart';
import 'package:smart_travel/presentation/screens/profile/account_management_screen.dart';
import 'package:smart_travel/presentation/screens/profile/user_level_screen.dart';
import 'package:smart_travel/presentation/screens/tour/tour_list_screen.dart';
import 'package:smart_travel/presentation/screens/chat/ai_chat_screen.dart';
import 'package:smart_travel/router/route_names.dart';
import '../injection_container.dart' as di;
import '../presentation/blocs/admin_invoice/admin_invoice_bloc.dart';
import '../presentation/blocs/admin_voucher/voucher_bloc.dart';
import '../presentation/blocs/admin_voucher/voucher_event.dart';
import '../presentation/screens/admin/admin_dashboard.dart';
import '../presentation/screens/admin/invoice/admin_invoice_screen.dart';
import '../presentation/screens/admin/voucher/voucher_management_screen.dart';
import '../presentation/screens/invoice/my_invoices_screen.dart';
class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      //Admin
      case RouteNames.dashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());

      case RouteNames.adminInvoices:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => di.sl<AdminInvoiceBloc>()..add(LoadAdminInvoices()),
            child: const AdminInvoiceScreen(),
          ),
        );
      //Voucher
        case RouteNames.adminVoucher:
          return MaterialPageRoute(
            // Vì bên trong VoucherManagementScreen bạn đã bọc BlocProvider rồi
            // nên ở đây chỉ cần gọi màn hình là được.
            builder: (_) => BlocProvider(
              create: (_) => di.sl<VoucherBloc>()..add(LoadAllVoucher()),
              child: const VoucherManagementScreen(),
            ),
          );


      //User
      case RouteNames.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case RouteNames.splashScreen:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case RouteNames.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case RouteNames.register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case RouteNames.forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      case RouteNames.destinationDetail:
        return MaterialPageRoute(
          builder: (context) => DetailDestinationScreen(),
          settings: settings,
        );
      case RouteNames.explore:
        return MaterialPageRoute(builder: (_) => const ExploreScreen());

      // Tour
      case RouteNames.tourList:
        return MaterialPageRoute(builder: (_) => const TourListScreen());
        
      // AI Chat
      case RouteNames.aiChat:
        return MaterialPageRoute(builder: (_) => const AIChatScreen());

    // Hotel
      case RouteNames.homestayList:
        return MaterialPageRoute(
          builder:
              (context) => BlocProvider(
            create: (_) => di.sl<HotelBloc>(),
            child: const HomestayListScreen(),
          ),
          settings: settings,
        );
      case RouteNames.hotelDetail:
        return MaterialPageRoute(
          builder:
              (context) => BlocProvider(
            create: (_) => di.sl<HotelDetailBloc>(),
            child: const DetailHomestayScreen(),
          ),
          settings: settings,
        );

      // Profile
      case RouteNames.profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case RouteNames.editProfile:
        return MaterialPageRoute(builder: (_) => const EditProfileScreen());
      case RouteNames.changePassword:
        return MaterialPageRoute(builder: (_) => const ChangePasswordScreen());
      case RouteNames.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case RouteNames.accountManagement:
        return MaterialPageRoute(builder: (_) => const AccountManagementScreen());
      case RouteNames.userLevel:
        return MaterialPageRoute(builder: (_) => const UserLevelScreen());
      case RouteNames.myInvoices:
        return MaterialPageRoute(builder: (_) => const MyInvoicesScreen(),);
      default:
        return MaterialPageRoute(
          builder:
              (_) => const Scaffold(
                body: Center(child: Text('404 - Page not found')),
              ),
        );
    }
  }
}
