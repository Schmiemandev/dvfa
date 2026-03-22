import 'package:flutter/material.dart';

class TransferScreen extends StatefulWidget {
  final String? recipient;
  final String? amount;
  final bool autoExecute;

  const TransferScreen({
    super.key,
    this.recipient,
    this.amount,
    this.autoExecute = false,
  });

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final TextEditingController _recipientController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _recipientController.text = widget.recipient ?? '';
    _amountController.text = widget.amount ?? '';

    if (widget.autoExecute) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performTransfer();
      });
    }
  }

  void _performTransfer() {
    final String recipient = _recipientController.text;
    final String amount = _amountController.text;

    print("DEBUG [Transfer]: Executing transfer of \$$amount to $recipient");

    if (recipient.isNotEmpty && amount.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully transferred \$$amount to $recipient'),
          backgroundColor: Colors.greenAccent,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter recipient and amount'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fund Transfer'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _recipientController,
              decoration: InputDecoration(
                labelText: 'Recipient Account',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _performTransfer,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF778DA9),
                foregroundColor: const Color(0xFF0D1B2A),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'TRANSFER',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
