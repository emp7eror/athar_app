import 'package:get/get.dart';
import '../sadaqah/sadaqah_controller.dart';
import 'home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => HomeController());
    // The صدقة section under the practices.
    Get.lazyPut(() => SadaqahController());
  }
}
