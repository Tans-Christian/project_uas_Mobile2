import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_page.dart';
import 'home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://lxlogvfyyjftgrcigoom.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx4bG9ndmZ5eWpmdGdyY2lnb29tIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzgzMzE1NTIsImV4cCI6MjA1MzkwNzU1Mn0.7tQBxc8N5QIREPipiLIRYAraiV1ReVehrdOM9M0enOI',
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Flutter Supabase Auth",
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AuthStateHandler(),
      routes: {
        '/login': (context) => AuthPage(),
        '/home': (context) => HomePage(),
      },
    );
  }
}

class AuthStateHandler extends StatefulWidget {
  const AuthStateHandler({super.key});

  @override
  _AuthStateHandlerState createState() => _AuthStateHandlerState();
}

class _AuthStateHandlerState extends State<AuthStateHandler> {
  final SupabaseClient supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = supabase.auth.currentSession;
        
        // Menampilkan HomePage jika user sudah login, jika tidak AuthPage
        return session != null ? HomePage() : AuthPage();
      },
    );
  }
}
