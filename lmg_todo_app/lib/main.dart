import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/todo_controller.dart';
import 'data/todo_repository.dart';
import 'pages/todo_list_page.dart';
import 'utils/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  final repository = TodoRepository();
  final controller = TodoController(repository);
  await controller.init();
  runApp(MyApp(controller: controller));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.controller});
  final TodoController controller;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: controller,
      child: MaterialApp(
        title: 'LMG TODO',
        scaffoldMessengerKey: NotificationService.instance.scaffoldMessengerKey,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.indigo,
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFF8F9FB),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            color: Colors.white,
            surfaceTintColor: Colors.white,
            shadowColor: Colors.black.withOpacity(0.06),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          ),
          chipTheme: const ChipThemeData(
            shape: StadiumBorder(),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            elevation: 3,
            shape: StadiumBorder(),
          ),
          visualDensity: VisualDensity.standard,
        ),
        home: const TodoListPage(),
      ),
    );
  }
}
