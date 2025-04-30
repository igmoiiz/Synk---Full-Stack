import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/Controller/Api%20Services/api_services.dart';
import 'package:frontend/Controller/Local%20Storage/storage_services.dart';
import 'package:frontend/Controller/Scoket%20Services/socket_services.dart';
import 'package:frontend/View/Interface/home_page.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    //  Initializing Services
    final StorageService storageServices = StorageService();
    final ApiServices apiServices = ApiServices(
      baseUrl: dotenv.env['BASE_URL'],
      storageService: storageServices,
    );

    final SocketService socketServices = SocketService(
      baseUrl: dotenv.env['BASE_URL'],
      storageService: storageServices,
    );

    return MultiProvider(providers: []);
  }
}
