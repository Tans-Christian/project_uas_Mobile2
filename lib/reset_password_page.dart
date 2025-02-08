import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_page.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  _ResetPasswordPageState createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  bool isResetting = false; // Apakah pengguna dalam sesi reset password

  @override
  void initState() {
    super.initState();
    _checkResetSession();
  }

  Future<void> _checkResetSession() async {
    final session = supabase.auth.currentSession;
    if (session != null) {
      setState(() => isResetting = true);
    }
  }

  Future<void> sendResetEmail() async {
    try {
      await supabase.auth.resetPasswordForEmail(emailController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Cek email Anda untuk reset password")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> updatePassword() async {
    try {
      await supabase.auth.updateUser(UserAttributes(password: newPasswordController.text));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password berhasil diperbarui")),
      );
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isResetting ? "Setel Password Baru" : "Reset Password")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isResetting) ...[
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: "Email"),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: sendResetEmail,
                child: Text("Kirim Email Reset"),
              ),
            ] else ...[
              TextField(
                controller: newPasswordController,
                decoration: InputDecoration(labelText: "Password Baru"),
                obscureText: true,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: updatePassword,
                child: Text("Simpan Password Baru"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
