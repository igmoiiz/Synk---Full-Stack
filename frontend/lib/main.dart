import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/Controller/Api%20Services/api_services.dart';
import 'package:frontend/Controller/Local%20Storage/storage_services.dart';
import 'package:frontend/Controller/Providers/auth_provider.dart';
import 'package:frontend/Controller/Providers/chat_provider.dart';
import 'package:frontend/Controller/Scoket%20Services/socket_services.dart';
import 'package:frontend/View/Authentication/login_page.dart';
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
    // Initializing Services
    final StorageService storageServices = StorageService();
    final ApiServices apiServices = ApiServices(
      baseUrl: dotenv.env['BASE_URL'] ?? "http://10.89.167.188:5000",
      storageService: storageServices,
    );

    final SocketService socketServices = SocketService(
      baseUrl: dotenv.env['BASE_URL'] ?? "http://10.89.167.188:5000",
      storageService: storageServices,
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            apiService: apiServices,
            storageService: storageServices,
          ),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ChatProvider>(
          create: (_) => ChatProvider(
            apiService: apiServices,
            socketService: socketServices,
          ),
          update: (_, auth, previousChat) {
            if (auth.isAuthenticated) {
              socketServices.initSocket();
            }
            return previousChat ??
                ChatProvider(
                  apiService: apiServices,
                  socketService: socketServices,
                );
          },
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Synk Chat',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6200EE),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6200EE),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            if (authProvider.status == AuthStatus.initial) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            } else if (authProvider.isAuthenticated) {
              return const HomePage();
            } else {
              return const LoginPage();
            }
          },
        ),
      ),
    );
  }
}
