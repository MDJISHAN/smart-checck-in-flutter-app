import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../screens/home_screen.dart';
import '../services/auth_service.dart';
import '../utils/device_utils.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _empIdCtrl = TextEditingController();
  final TextEditingController _pwdCtrl = TextEditingController();
  final _auth = AuthService();
  late ApiService api;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    api = ApiService(dotenv.env['WEBHOOK_URL']!);
  }

  Future<void> _login() async {
    final empId = _empIdCtrl.text.trim();
    final pwd = _pwdCtrl.text.trim();

    if (empId.isEmpty || pwd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Employee ID and Password required")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final deviceId = await getDeviceId();
      final res = await api.login(empId, pwd, deviceId);

      if (res['status'] == 200 &&
          res['body'] != null &&
          res['body']['token'] != null) {
        final token = res['body']['token'];
        final empId = res['body']['emp_id'];
        final name = res['body']['name'] ?? '';

        await _auth.saveLogin(token, empId, name);

        Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (context) => HomeScreen()),
);
      } else {
        final err = res['body']?['error'] ?? 'Login failed';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _empIdCtrl,
                decoration: InputDecoration(labelText: "Employee ID"),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _pwdCtrl,
                obscureText: true,
                decoration: InputDecoration(labelText: "Password"),
              ),
              SizedBox(height: 20),
              loading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _login,
                      child: Text("Login"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
