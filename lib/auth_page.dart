import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'reset_password_page.dart';
import 'home_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLogin = true;
  bool isLoading = false;

  Future<void> authenticate() async {
    setState(() => isLoading = true);

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    // Validasi input kosong
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Email dan password tidak boleh kosong!")),
      );
      setState(() => isLoading = false);
      return;
    }

    try {
      if (isLogin) {
        final response = await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );

        if (response.user == null) {
          throw AuthException('Gagal login. Periksa email dan password.');
        }
      } else {
        final response = await supabase.auth.signUp(
          email: email,
          password: password,
        );

        if (response.user == null) {
          throw AuthException('Registrasi gagal. Coba lagi.');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Registrasi berhasil! Cek email untuk verifikasi.")),
        );
      }

      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage()));
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isLogin ? "Login" : "Register")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: "Email"),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 10),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : authenticate,
              child: isLoading ? CircularProgressIndicator() : Text(isLogin ? "Login" : "Register"),
            ),
            SizedBox(height: 10),
            TextButton(
              onPressed: () => setState(() => isLogin = !isLogin),
              child: Text(isLogin ? "Belum punya akun? Register" : "Sudah punya akun? Login"),
            ),
            if (isLogin)
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ResetPasswordPage()));
                },
                child: Text("Lupa Password?"),
              ),
          ],
        ),
      ),
    );
  }
}
