import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/category.dart';
import '../../providers/chat_provider.dart';

class CreateOfferScreen extends StatefulWidget {
  const CreateOfferScreen({super.key});

  @override
  State<CreateOfferScreen> createState() => _CreateOfferScreenState();
}

class _CreateOfferScreenState extends State<CreateOfferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _eventNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _platformController = TextEditingController();
  final _cardNameController = TextEditingController();
  final _offerDetailsController = TextEditingController();
  final _offerAmountController = TextEditingController();
  final _discountPercentController = TextEditingController(text: '30');
  
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedCategory = 'Movies';
  bool _isLoading = false;
  double _discountedPrice = 0;

  @override
  void dispose() {
    _eventNameController.dispose();
    _locationController.dispose();
    _quantityController.dispose();
    _platformController.dispose();
    _cardNameController.dispose();
    _offerDetailsController.dispose();
    _offerAmountController.dispose();
    _discountPercentController.dispose();
    super.dispose();
  }

  void _calculateDiscountedPrice() {
    final offerText = _offerAmountController.text;
    final discountText = _discountPercentController.text;
    
    if (offerText.isNotEmpty && discountText.isNotEmpty) {
      final offerAmount = double.tryParse(offerText);
      final discountPercent = double.tryParse(discountText);
      
      if (offerAmount != null && discountPercent != null && discountPercent >= 0 && discountPercent <= 100) {
        setState(() {
          _discountedPrice = (offerAmount * (100 - discountPercent) / 100);
        });
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryRed,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitOffer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final discountPercent = double.tryParse(_discountPercentController.text) ?? 30;
    
    final success = await chatProvider.createOffer(
      eventName: _eventNameController.text.trim(),
      location: _locationController.text.trim(),
      eventDate: _selectedDate,
      quantity: int.parse(_quantityController.text),
      category: _selectedCategory,
      platform: _platformController.text.trim(),
      cardName: _cardNameController.text.trim().isNotEmpty 
          ? _cardNameController.text.trim() 
          : null,
      offerDetails: _offerDetailsController.text.trim().isNotEmpty 
          ? _offerDetailsController.text.trim() 
          : null,
      offerAmount: double.parse(_offerAmountController.text),
      discountPercent: discountPercent,
    );

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offer posted successfully!'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post offer: ${chatProvider.error}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        title: const Text('Post Event Offer'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.info.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppTheme.info,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Post an event deal you can provide. All clients will be able to see and accept your offer.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.info,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Event Name
              _buildLabel('Event Name *'),
              TextFormField(
                controller: _eventNameController,
                decoration: _inputDecoration('e.g., Avengers: Secret Wars'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Event name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Category
              _buildLabel('Category *'),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: _inputDecoration(''),
                items: Category.categories.map((category) {
                  return DropdownMenuItem(
                    value: category.name,
                    child: Row(
                      children: [
                        Icon(category.icon, size: 20, color: AppTheme.grey),
                        const SizedBox(width: 12),
                        Text(category.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Location
              _buildLabel('Location *'),
              TextFormField(
                controller: _locationController,
                decoration: _inputDecoration('e.g., PVR Phoenix Mall, Mumbai'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Location is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Date & Quantity Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Event Date *'),
                        InkWell(
                          onTap: _selectDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.lightGrey),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, 
                                    size: 20, color: AppTheme.grey),
                                const SizedBox(width: 12),
                                Text(
                                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Tickets *'),
                        TextFormField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration('1'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            final qty = int.tryParse(value);
                            if (qty == null || qty < 1) {
                              return 'Min 1';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Platform
              _buildLabel('Platform *'),
              TextFormField(
                controller: _platformController,
                decoration: _inputDecoration('e.g., BookMyShow, Paytm'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Platform is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Card Name (Optional)
              _buildLabel('Card Name (Optional)'),
              TextFormField(
                controller: _cardNameController,
                decoration: _inputDecoration('e.g., HDFC Regalia, SBI Elite'),
              ),
              const SizedBox(height: 20),

              // Offer Details (Optional)
              _buildLabel('Offer Details (Optional)'),
              TextFormField(
                controller: _offerDetailsController,
                maxLines: 3,
                decoration: _inputDecoration(
                  'e.g., Buy 1 Get 1 Free, 25% discount, etc.',
                ),
              ),
              const SizedBox(height: 20),

              // Offer Amount
              _buildLabel('Your Offer Price *'),
              TextFormField(
                controller: _offerAmountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '0',
                  prefixText: '₹ ',
                  filled: true,
                  fillColor: AppTheme.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.lightGrey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.lightGrey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primaryRed),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Offer amount is required';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
                onChanged: (value) => _calculateDiscountedPrice(),
              ),
              const SizedBox(height: 20),

              // Discount Percentage
              _buildLabel('Discount Percentage *'),
              TextFormField(
                controller: _discountPercentController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '30',
                  suffixText: '%',
                  filled: true,
                  fillColor: AppTheme.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.lightGrey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.lightGrey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primaryRed),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Discount percentage is required';
                  }
                  final percent = double.tryParse(value);
                  if (percent == null || percent < 0 || percent > 100) {
                    return 'Enter a valid percentage (0-100)';
                  }
                  return null;
                },
                onChanged: (value) => _calculateDiscountedPrice(),
              ),
              const SizedBox(height: 16),

              // Price Breakdown
              if (_discountedPrice > 0)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryRed.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Price Breakdown',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildPriceRow(
                        'Offer Amount (Client Pays)',
                        '₹${double.tryParse(_offerAmountController.text)?.toStringAsFixed(0) ?? '0'}',
                      ),
                      const SizedBox(height: 8),
                      _buildPriceRow(
                        'Your Card Purchase (${_discountPercentController.text}% off)',
                        '₹${_discountedPrice.toStringAsFixed(0)}',
                      ),
                      const SizedBox(height: 8),
                      _buildPriceRow(
                        'You Receive (80%)',
                        '₹${((double.tryParse(_offerAmountController.text) ?? 0) * 0.8).toStringAsFixed(0)}',
                      ),
                      const Divider(height: 16),
                      _buildPriceRow(
                        'Potential Earnings',
                        '₹${(((double.tryParse(_offerAmountController.text) ?? 0) * 0.8) - _discountedPrice).toStringAsFixed(0)}',
                        isHighlighted: true,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitOffer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRed,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Post Offer',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.darkGrey,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppTheme.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.lightGrey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.lightGrey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryRed),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.error),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isHighlighted ? 15 : 14,
            color: isHighlighted ? AppTheme.primaryRed : AppTheme.darkGrey,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlighted ? 16 : 14,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
            color: isHighlighted ? AppTheme.primaryRed : AppTheme.black,
          ),
        ),
      ],
    );
  }
}
