import 'package:get/get.dart';

import 'dhikr_controller.dart';

class DhikrBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => DhikrController());
  }
}
