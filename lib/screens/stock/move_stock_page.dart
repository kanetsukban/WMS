import 'package:flutter/material.dart';

class MoveStockPage extends StatefulWidget {
  const MoveStockPage({super.key});

  @override
  State<MoveStockPage> createState() => _MoveStockPageState();
}

class _MoveStockPageState extends State<MoveStockPage> {
  final _formKey = GlobalKey<FormState>();
  final _itemCtrl = TextEditingController();
  final _fromLocCtrl = TextEditingController();
  final _toLocCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _itemCtrl.dispose();
    _fromLocCtrl.dispose();
    _toLocCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    // TODO: call API จริง (เช่น POST /api/stock/move) ตามระบบของคุณ
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    setState(() => _loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Moved ${_qtyCtrl.text} of ${_itemCtrl.text} from ${_fromLocCtrl.text} → ${_toLocCtrl.text}',
        ),
      ),
    );

    // เคลียร์ฟอร์ม (ถ้าต้องการ)
    _qtyCtrl.clear();
    _itemCtrl.clear();
    _fromLocCtrl.clear();
    _toLocCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Move Stock")),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _itemCtrl,
                    decoration: const InputDecoration(
                      labelText: "Item Code",
                      prefixIcon: Icon(Icons.qr_code_2),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'กรอก Item Code' : null,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _fromLocCtrl,
                    decoration: const InputDecoration(
                      labelText: "From Location",
                      prefixIcon: Icon(Icons.store_mall_directory),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'กรอก From Location' : null,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _toLocCtrl,
                    decoration: const InputDecoration(
                      labelText: "To Location",
                      prefixIcon: Icon(Icons.local_shipping),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'กรอก To Location' : null,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Quantity",
                      prefixIcon: Icon(Icons.onetwothree),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'กรอกจำนวน';
                      final n = int.tryParse(v);
                      if (n == null || n <= 0) return 'จำนวนต้องเป็นตัวเลขมากกว่า 0';
                      return null;
                    },
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _submit,
                      icon: const Icon(Icons.check),
                      label: const Text("Submit"),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_loading)
            Container(
              color: Colors.black.withOpacity(0.1),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
