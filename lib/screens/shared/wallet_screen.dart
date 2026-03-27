import 'package:flutter/material.dart';

enum _PaymentType { visa, mastercard, amex }
enum _TxType { debit, credit }

class _Transaction {
  final String transactionId;
  final _TxType type;
  final String title;
  final String description;
  final double amount;
  final String timestamp;
  final String status;

  const _Transaction({
    required this.transactionId,
    required this.type,
    required this.title,
    required this.description,
    required this.amount,
    required this.timestamp,
    required this.status,
  });
}

class _PaymentCard {
  final String id;
  final _PaymentType type;
  final String lastFour;
  final bool isDefault;

  const _PaymentCard({
    required this.id,
    required this.type,
    required this.lastFour,
    required this.isDefault,
  });
}

class WalletScreen extends StatefulWidget {
  final double balance;
  final String role; // 'passenger' | 'driver'
  final VoidCallback? onBack;

  const WalletScreen({
    super.key,
    this.balance = 2451,
    this.role = 'passenger',
    this.onBack,
  });

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late List<_Transaction> transactions;
  late List<_PaymentCard> cards;
  late double currentBalance;
  String activeTab = 'transactions';

  @override
  void initState() {
    super.initState();
    currentBalance = widget.balance;

    // --- ROLE BASED MOCK DATA ---
    if (widget.role == 'driver') {
      transactions = [
        const _Transaction(
          transactionId: 'd1',
          type: _TxType.credit,
          title: 'Ride Earnings',
          description: 'Trip #8821',
          amount: 450,
          timestamp: 'Today, 4:00 PM',
          status: 'completed',
        ),
        const _Transaction(
          transactionId: 'd2',
          type: _TxType.debit,
          title: 'Bank Withdrawal',
          description: 'HDFC Bank',
          amount: 2000,
          timestamp: 'Yesterday',
          status: 'completed',
        ),
      ];
    } else {
      transactions = [
        const _Transaction(
          transactionId: '1',
          type: _TxType.debit,
          title: 'Ride to Mall Road',
          description: 'Via RidePool',
          amount: 249,
          timestamp: 'Today, 2:30 PM',
          status: 'completed',
        ),
        const _Transaction(
          transactionId: '2',
          type: _TxType.credit,
          title: 'Wallet Top Up',
          description: 'Added via UPI',
          amount: 1000,
          timestamp: 'Today, 10:15 AM',
          status: 'completed',
        ),
      ];
    }

    cards = [
      const _PaymentCard(id: '1', type: _PaymentType.visa, lastFour: '4532', isDefault: true),
      const _PaymentCard(id: '2', type: _PaymentType.mastercard, lastFour: '8721', isDefault: false),
    ];
  }

  // --- ACTIONS ---

  void _showAddMoneySheet() {
    final TextEditingController amountController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 24, right: 24, top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            Text(widget.role == 'driver' ? 'Add Credits' : 'Top Up Wallet',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '₹ ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  final double? amt = double.tryParse(amountController.text);
                  if (amt != null && amt > 0) {
                    setState(() {
                      currentBalance += amt;
                      transactions.insert(0, _Transaction(
                        transactionId: DateTime.now().toString(),
                        type: _TxType.credit,
                        title: widget.role == 'driver' ? 'Bonus Credit' : 'Wallet Top Up',
                        description: 'Manual entry',
                        amount: amt,
                        timestamp: 'Just Now',
                        status: 'completed',
                      ));
                    });
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                child: const Text('Confirm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWithdrawSheet() {
    final TextEditingController amountController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 24, right: 24, top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Withdraw to Bank', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text('Current Balance: ₹${currentBalance.toStringAsFixed(0)}', style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '₹ ',
                hintText: 'Max: ₹${currentBalance.toInt()}',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  final double? amt = double.tryParse(amountController.text);
                  if (amt != null && amt > 0 && amt <= currentBalance) {
                    setState(() {
                      currentBalance -= amt;
                      transactions.insert(0, _Transaction(
                        transactionId: DateTime.now().toString(),
                        type: _TxType.debit,
                        title: 'Withdrawal',
                        description: 'To Bank',
                        amount: amt,
                        timestamp: 'Just Now',
                        status: 'completed',
                      ));
                    });
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                child: const Text('Withdraw Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addNewCard() {
    setState(() {
      cards.add(_PaymentCard(
        id: DateTime.now().toString(),
        type: cards.length % 2 == 0 ? _PaymentType.mastercard : _PaymentType.visa,
        lastFour: (1000 + (cards.length * 243)).toString(),
        isDefault: false,
      ));
    });
  }

  void _removeCard(String id) {
    setState(() {
      cards.removeWhere((c) => c.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDriver = widget.role == 'driver';

    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back),
                    style: IconButton.styleFrom(backgroundColor: Colors.grey.shade100, shape: const CircleBorder()),
                  ),
                  const SizedBox(width: 8),
                  const Text('Wallet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                ],
              ),
            ),

            // Balance Card
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.indigo, Colors.indigo.shade800], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isDriver ? 'Total Earnings' : 'Available Balance',
                        style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text('₹${currentBalance.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white)),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _BalanceBtn(
                            label: isDriver ? 'Add Money' : 'Top Up',
                            isPrimary: false,
                            onTap: _showAddMoneySheet
                        ),
                        // ONLY SHOW WITHDRAW FOR DRIVERS
                        if (isDriver) ...[
                          const SizedBox(width: 12),
                          _BalanceBtn(label: 'Withdraw', isPrimary: true, onTap: _showWithdrawSheet),
                        ],
                      ],
                    )
                  ],
                ),
              ),
            ),

            _TabSwitcher(activeTab: activeTab, onChanged: (val) => setState(() => activeTab = val)),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                children: [
                  if (activeTab == 'transactions') ...[
                    for (final tx in transactions) _TransactionTile(tx: tx),
                  ] else ...[
                    _AddCardTile(onTap: _addNewCard),
                    for (final card in cards) _PaymentCardWidget(
                      card: card,
                      startColor: card.type == _PaymentType.visa ? Colors.blue.shade700 : Colors.orange.shade600,
                      endColor: card.type == _PaymentType.visa ? Colors.blue.shade900 : Colors.red.shade700,
                      onDelete: () => _removeCard(card.id),
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Internal Helper Widgets ---

class _BalanceBtn extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;
  const _BalanceBtn({required this.label, required this.isPrimary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isPrimary ? Colors.white : Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(label, style: TextStyle(color: isPrimary ? Colors.indigo : Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

class _TabSwitcher extends StatelessWidget {
  final String activeTab;
  final ValueChanged<String> onChanged;
  const _TabSwitcher({required this.activeTab, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            _TabBtn(label: 'Transactions', active: activeTab == 'transactions', onTap: () => onChanged('transactions')),
            _TabBtn(label: 'Methods', active: activeTab == 'cards', onTap: () => onChanged('cards')),
          ],
        ),
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TabBtn({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(color: active ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(12)),
          child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: active ? Colors.indigo : Colors.black54)),
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final _Transaction tx;
  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isCredit = tx.type == _TxType.credit;
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isCredit ? Colors.green.withOpacity(0.1) : Colors.grey.shade100,
            child: Icon(isCredit ? Icons.add : Icons.remove, color: isCredit ? Colors.green : Colors.black54),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tx.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(tx.timestamp, style: const TextStyle(fontSize: 12, color: Colors.black45)),
            ]),
          ),
          Text('${isCredit ? '+' : '-'}₹${tx.amount.toInt()}', style: TextStyle(fontWeight: FontWeight.bold, color: isCredit ? Colors.green : Colors.black87)),
        ],
      ),
    );
  }
}

class _AddCardTile extends StatelessWidget {
  final VoidCallback onTap;
  const _AddCardTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.indigo.withOpacity(0.2), style: BorderStyle.solid)),
        child: const Row(
          children: [
            Icon(Icons.add_circle_outline, color: Colors.indigo),
            SizedBox(width: 12),
            Text('Add New Payment Method', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
          ],
        ),
      ),
    );
  }
}

class _PaymentCardWidget extends StatelessWidget {
  final _PaymentCard card;
  final Color startColor;
  final Color endColor;
  final VoidCallback onDelete;

  const _PaymentCardWidget({required this.card, required this.startColor, required this.endColor, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [startColor, endColor], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.credit_card, color: Colors.white, size: 30),
              IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline, color: Colors.white, size: 24)),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Card Number', style: TextStyle(color: Colors.white70, fontSize: 12)),
          Text('•••• •••• •••• ${card.lastFour}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2)),
          if (card.isDefault) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
              child: const Text('DEFAULT', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            )
          ]
        ],
      ),
    );
  }
}
