import 'package:get/get.dart';

import '../controllers/location_permission_controller.dart';

class LocationPermissionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LocationPermissionController>(
      () => LocationPermissionController(),
    );
  }
}
