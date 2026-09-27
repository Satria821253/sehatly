import 'package:get/get.dart';

import '../bindings/address_picker_binding.dart';
import '../bindings/home_binding.dart';
import '../bindings/location_permission_binding.dart';
import '../bindings/splash_binding.dart';
import '../../pages/address_picker_page.dart';
import '../../pages/home_page.dart';
import '../../pages/location_permission_page.dart';
import '../../pages/splash_page.dart';
import 'app_routes.dart';

class AppPages {
  static final routes = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashPage(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.locationPermission,
      page: () => const LocationPermissionPage(),
      binding: LocationPermissionBinding(),
    ),
    GetPage(
      name: AppRoutes.addressPicker,
      page: () => const AddressPickerPage(),
      binding: AddressPickerBinding(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomePage(),
      binding: HomeBinding(),
    ),
  ];
}
