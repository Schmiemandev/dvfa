import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:encrypt/encrypt.dart' as enc;
import 'package:shared_preferences/shared_preferences.dart';
import 'notes_screen.dart';
import 'dev_menu_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final String _balance = '\$12,450.00';
  final String _accountId = '88888888';
  int _tapCount = 0;
  DateTime? _lastTap;

  @override
  void initState() {
    super.initState();
    _fetchBalance();
  }

  Future<void> _fetchBalance() async {
    try {
      final response = await http.get(Uri.parse('http://api.dvfa.local/v1/balance'));
      if (response.statusCode == 200) {
        // In a real app, parse the JSON response here.
      }
    } catch (e) {
      // Silence errors to maintain the UI in this demo scenario.
    }
  }

  void _handleDevMenuTap() {
    final now = DateTime.now();
    if (_lastTap != null && now.difference(_lastTap!) > const Duration(seconds: 2)) {
      _tapCount = 1;
    } else {
      _tapCount++;
    }
    _lastTap = now;

    if (_tapCount >= 5) {
      _tapCount = 0;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const DevMenuScreen()),
      );
    }
  }

  void _exportStatement() {
    const String plainText = 'Account: 88888888, Balance: \$12,450.00, Type: Savings';
    
    final key = enc.Key.fromUtf8('DVFA_STATIC_KEY_8899001122334455');
    final iv = enc.IV.fromUtf8('DVFA_STATIC_IV__');

    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: iv);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Encrypted Statement'),
        content: SelectableText(encrypted.base64),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkVipStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isVip = prefs.getBool('is_vip') ?? false;

    if (isVip) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Platinum Lounge'),
            content: const Text(
              'Welcome to the Platinum Lounge! Your pre-approved limit is \$50,000.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access Denied. VIP status required.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.credit_card),
            onPressed: _checkVipStatus,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportStatement,
          ),
          IconButton(
            icon: const Icon(Icons.note_add),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const NotesScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account Number',
              style: TextStyle(fontSize: 16, color: Color(0xFF778DA9)),
            ),
            Text(
              _accountId,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE0E1DD),
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Total Balance',
              style: TextStyle(fontSize: 16, color: Color(0xFF778DA9)),
            ),
            GestureDetector(
              onTap: _handleDevMenuTap,
              child: Text(
                _balance,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE0E1DD),
                ),
              ),
            ),
            const SizedBox(height: 48),
            const Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE0E1DD),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: const [
                  _TransactionItem(
                    title: 'Starbucks Coffee',
                    date: 'March 21, 2026',
                    amount: '-\$5.45',
                    icon: Icons.coffee,
                  ),
                  _TransactionItem(
                    title: 'Salary Deposit',
                    date: 'March 20, 2026',
                    amount: '+\$4,200.00',
                    icon: Icons.work,
                    isPositive: true,
                  ),
                  _TransactionItem(
                    title: 'Amazon.com',
                    date: 'March 18, 2026',
                    amount: '-\$120.50',
                    icon: Icons.shopping_cart,
                  ),
                  _TransactionItem(
                    title: 'Gym Membership',
                    date: 'March 15, 2026',
                    amount: '-\$45.00',
                    icon: Icons.fitness_center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final String title;
  final String date;
  final String amount;
  final IconData icon;
  final bool isPositive;

  const _TransactionItem({
    required this.title,
    required this.date,
    required this.amount,
    required this.icon,
    this.isPositive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1B263B),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF415A77),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        subtitle: Text(date, style: const TextStyle(color: Color(0xFF778DA9))),
        trailing: Text(
          amount,
          style: TextStyle(
            color: isPositive ? Colors.greenAccent : Colors.redAccent,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
