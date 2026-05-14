/**
* Student Number:220019475, 224108179, 222016851, 223025046, 221030087, 221008989, 223058186
* Student Name  :Lindokuhle Thabethe, Jordan Davids, Vinolia Malejane, Mofokeng Thato, Khabonina Tshabalala, Lerato Twala, A Mkhungela
*/
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'viewmodels/login_viewmodel.dart';
import 'views/auth/login_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://bxqnrgnumyqmfbvzkbol.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ4cW5yZ251bXlxbWZidnprYm9sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg1NzYxODQsImV4cCI6MjA5NDE1MjE4NH0.RvxL0Qwbu1fq13PZKv06j6hrb9aFucanclZBANO6u9I',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoginViewModel(),
      child: MaterialApp(
        title: 'Student Assistant App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: const LoginView(),
      ),
    );
  }
}
