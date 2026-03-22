import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _accountIdController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStoredCredentials();
  }

  Future<void> _loadStoredCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _accountIdController.text = prefs.getString('account_id') ?? '';
      _pinController.text = prefs.getString('pin') ?? '';
    });
  }

  Future<void> _handleLogin() async {
    final String accountId = _accountIdController.text;
    final String pin = _pinController.text;

    print("DEBUG [Auth]: Attempting login for account $accountId with PIN: $pin");

    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    final String hashedPin = digest.toString();

    if (accountId == "88888888" && 
        hashedPin == "03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4") {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('account_id', accountId);
      await prefs.setString('pin', pin);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid Account ID or PIN.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.account_balance_rounded,
                size: 80,
                color: Color(0xFFE0E1DD),
              ),
              const SizedBox(height: 24),
              const Text(
                'DVFA FinTech',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE0E1DD),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _accountIdController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Account ID',
                  hintText: 'Enter your 8-digit ID',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'PIN',
                  hintText: 'Enter your 4-digit PIN',
                  prefixIcon: const Icon(Icons.lock_person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF778DA9),
                  foregroundColor: const Color(0xFF0D1B2A),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'LOGIN',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
