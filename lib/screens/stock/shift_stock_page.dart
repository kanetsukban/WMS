import 'package:flutter/material.dart';

class ShiftStockPage extends StatefulWidget {
  const ShiftStockPage({super.key});

  @override
  State<ShiftStockPage> createState() => _ShiftStockPageState();
}

class _ShiftStockPageState extends State<ShiftStockPage> {
  final _formKey = GlobalKey<FormState>();
  final _itemCtrl = TextEditingController();
  final _remarkCtrl = TextEditingController();

  @override
  void dispose() {
    _itemCtrl.dispose();
    _remarkCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Shifted ${_itemCtrl.text} (${_remarkCtrl.text})')),
    );
    _itemCtrl.clear();
    _remarkCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Shift Stock")),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _itemCtrl,
                decoration: const InputDecoration(
                  labelText: "Item Code",
                  prefixIcon: Icon(Icons.qr_code),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'กรอก Item Code' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _remarkCtrl,
                decoration: const InputDecoration(
                  labelText: "Remark (optional)",
                  prefixIcon: Icon(Icons.note_alt_outlined),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.check),
                  label: const Text("Submit"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
