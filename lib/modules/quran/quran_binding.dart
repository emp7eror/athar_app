import 'package:get/get.dart';

import 'quran_controller.dart';

class QuranBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => QuranController());
  }
}
