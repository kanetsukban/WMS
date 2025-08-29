import 'package:flutter/material.dart';
import 'move_stock_page.dart';
import 'shift_stock_page.dart';

class StockPage extends StatelessWidget {
  const StockPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text("Stock Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        const Divider(height: 0),
        ListTile(
          leading: const Icon(Icons.sync_alt),
          title: const Text("Move Stock"),
          subtitle: const Text("ย้ายสต๊อกจากตำแหน่งหนึ่งไปอีกตำแหน่ง"),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MoveStockPage()),
          ),
        ),
        const Divider(height: 0),
        ListTile(
          leading: const Icon(Icons.swap_horiz),
          title: const Text("Shift Stock"),
          subtitle: const Text("ปรับย้าย/โยกย้ายสต๊อก (ตัวอย่าง)"),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ShiftStockPage()),
          ),
        ),
        const Divider(height: 0),
      ],
    );
  }
}
