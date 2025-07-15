/*import 'package:firebase_core/firebase_core.dart';*/
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memora/providers/notion_provider.dart';
import 'package:memora/providers/task_provider.dart';
import 'package:memora/screens/home_screen.dart';
/*import 'package:memora/services/firebase_service.dart';*/
import 'package:memora/services/local_storage_service.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  /*await Firebase.initializeApp();*/

  final notionProvider = NotionProvider();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: notionProvider),
        ChangeNotifierProvider(
          create: (context) => TaskProvider(
            /*FirebaseService(),*/
            notionProvider,
            LocalStorageService(),
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: MyApp.navigatorKey,
      title: 'Memora',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: GoogleFonts.getTextTheme('Noto Sans KR'),
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: GoogleFonts.getTextTheme(
          'Noto Sans KR',
        ).apply(bodyColor: Colors.white, displayColor: Colors.white),
        brightness: Brightness.dark,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.black,
        cardColor: Colors.grey[900],
        dialogTheme: DialogThemeData(backgroundColor: Colors.grey[900]),
      ),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
