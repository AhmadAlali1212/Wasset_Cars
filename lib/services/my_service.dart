import 'package:shared_preferences/shared_preferences.dart';

class MyService {
  late SharedPreferences sharedPreference;
  Future<MyService> init() async {
    // await Firebase.initializeApp();
    // await FirebaseMessaging.instance.requestPermission();

    sharedPreference = await SharedPreferences.getInstance();
    return this;
  }
}

// initialServices() async {
//   await Get.putAsync(() => MyService().init());
// }
