import 'package:get/get.dart';

import '../controllers/permission_intro_controller.dart';

class PermissionIntroBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PermissionIntroController>(() => PermissionIntroController());
  }
}
