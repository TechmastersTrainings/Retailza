import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../services/customer_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({Key? key}) : super(key: key);

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final CustomerService _customerService = CustomerService();

  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await _customerService.createCustomer(
        _nameController.text.trim(),
        _mobileController.text.trim().isNotEmpty ? _mobileController.text.trim() : null,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Customer added to Khata book!"), backgroundColor: AppColors.success),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.debtRed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Customer (नया ग्राहक)"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                label: "Customer Name (ग्राहक का नाम) *",
                hint: "e.g. Ramesh Patel",
                controller: _nameController,
                validator: (v) => (v == null || v.trim().isEmpty) ? "Customer name is required" : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: "Mobile Number (मोबाइल नंबर)",
                hint: "9876543210 (Optional for SMS / WhatsApp reminders)",
                controller: _mobileController,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: "Save Customer (ग्राहक जोड़ें)",
                isLoading: _isSaving,
                onPressed: _handleSave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
