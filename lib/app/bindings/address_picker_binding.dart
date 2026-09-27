import 'package:get/get.dart';

import '../controllers/address_picker_controller.dart';

class AddressPickerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AddressPickerController>(() => AddressPickerController());
  }
}
