import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/category.dart';
import '../../providers/request_provider.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _eventNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _cardNameController = TextEditingController();
  final _offerDetailsController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _discountedPriceController = TextEditingController();
  final _eventUrlController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedCategory;
  String? _selectedPlatform;

  @override
  void dispose() {
    _eventNameController.dispose();
    _locationController.dispose();
    _quantityController.dispose();
    _cardNameController.dispose();
    _offerDetailsController.dispose();
    _originalPriceController.dispose();
    _discountedPriceController.dispose();
    _eventUrlController.dispose();
    super.dispose();
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

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }
    if (_selectedPlatform == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a platform'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final requestProvider = Provider.of<RequestProvider>(context, listen: false);
    final request = await requestProvider.createRequest(
      eventName: _eventNameController.text.trim(),
      location: _locationController.text.trim(),
      eventDate: _selectedDate,
      quantity: int.parse(_quantityController.text),
      cardName: _cardNameController.text.trim(),
      offerDetails: _offerDetailsController.text.trim(),
      originalPrice: double.parse(_originalPriceController.text),
      discountedPrice: double.parse(_discountedPriceController.text),
      eventUrl: _eventUrlController.text.trim().isNotEmpty
          ? _eventUrlController.text.trim()
          : null,
      category: _selectedCategory!,
      platform: _selectedPlatform!,
    );

    if (!mounted) return;

    if (request != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request created successfully!'),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(requestProvider.error ?? 'Failed to create request'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      appBar: AppBar(
        title: const Text('Create Request'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Category Selection
              _buildSectionTitle('Category'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: Category.categories.map((category) {
                  final isSelected = _selectedCategory == category.name;
                  return ChoiceChip(
                    label: Text(category.name),
                    avatar: Icon(
                      category.icon,
                      size: 18,
                      color: isSelected ? AppTheme.white : AppTheme.grey,
                    ),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryRed,
                    backgroundColor: AppTheme.white,
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.white : AppTheme.black,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? category.name : null;
                        _selectedPlatform = null;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Platform Selection
              if (_selectedCategory != null) ...[
                _buildSectionTitle('Platform'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: Category.getByName(_selectedCategory!)!
                      .platforms
                      .map((platform) {
                    final isSelected = _selectedPlatform == platform;
                    return ChoiceChip(
                      label: Text(platform),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryRed,
                      backgroundColor: AppTheme.white,
                      labelStyle: TextStyle(
                        color: isSelected ? AppTheme.white : AppTheme.black,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          _selectedPlatform = selected ? platform : null;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],

              // Event Name
              _buildSectionTitle('Event Details'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _eventNameController,
                decoration: const InputDecoration(
                  labelText: 'Event Name',
                  hintText: 'e.g., Avengers Movie, IPL Match',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter event name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Location
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'e.g., PVR Phoenix, Mumbai',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date Picker
              GestureDetector(
                onTap: _selectDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Event Date',
                      prefixIcon: const Icon(Icons.calendar_today_outlined),
                      hintText: '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    ),
                    controller: TextEditingController(
                      text: '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Quantity
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  prefixIcon: Icon(Icons.confirmation_number_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter quantity';
                  }
                  if (int.tryParse(value) == null || int.parse(value) < 1) {
                    return 'Please enter a valid quantity';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Card Details
              _buildSectionTitle('Card & Offer Details'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _cardNameController,
                decoration: const InputDecoration(
                  labelText: 'Card Name',
                  hintText: 'e.g., HDFC Credit Card, SBI Debit Card',
                  prefixIcon: Icon(Icons.credit_card_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter card name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _offerDetailsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Offer Details',
                  hintText: 'Describe the offer you want...',
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter offer details';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Pricing Section
              _buildSectionTitle('Pricing'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _originalPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Original Ticket Price (₹)',
                  hintText: 'What you would pay normally',
                  prefixIcon: Icon(Icons.currency_rupee),
                  helperText: 'This amount will be frozen from your wallet',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the original price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
                onChanged: (value) {
                  // Auto-calculate discounted price (default 70% of original)
                  if (value.isNotEmpty && double.tryParse(value) != null) {
                    final original = double.parse(value);
                    final discounted = (original * 0.7).round();
                    _discountedPriceController.text = discounted.toString();
                    setState(() {}); // Refresh to show profit info
                  }
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _discountedPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Discounted Price (₹)',
                  hintText: 'What buyer pays using their card',
                  prefixIcon: Icon(Icons.discount_outlined),
                  helperText: 'Price after card discount (buyer pays this)',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the discounted price';
                  }
                  final discounted = double.tryParse(value);
                  if (discounted == null) {
                    return 'Please enter a valid amount';
                  }
                  final original = double.tryParse(_originalPriceController.text);
                  if (original != null && discounted >= original) {
                    return 'Discounted price must be less than original';
                  }
                  return null;
                },
                onChanged: (value) => setState(() {}),
              ),
              
              // Show profit breakdown if both prices are entered
              if (_originalPriceController.text.isNotEmpty && 
                  _discountedPriceController.text.isNotEmpty &&
                  double.tryParse(_originalPriceController.text) != null &&
                  double.tryParse(_discountedPriceController.text) != null)
                _buildProfitBreakdown(),
              
              const SizedBox(height: 16),

              TextFormField(
                controller: _eventUrlController,
                decoration: const InputDecoration(
                  labelText: 'Event URL (Optional)',
                  hintText: 'Paste booking link here...',
                  prefixIcon: Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              Consumer<RequestProvider>(
                builder: (context, provider, child) {
                  return ElevatedButton(
                    onPressed: provider.isLoading ? null : _submitRequest,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: provider.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.white,
                            ),
                          )
                        : const Text(
                            'Submit Request',
                            style: TextStyle(fontSize: 16),
                          ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppTheme.black,
      ),
    );
  }

  Widget _buildProfitBreakdown() {
    final originalPrice = double.parse(_originalPriceController.text);
    final discountedPrice = double.parse(_discountedPriceController.text);
    
    // Calculate profit breakdown (same logic as backend)
    final buyerPayment = (originalPrice * 0.8).round();
    final clientRefund = (originalPrice * 0.2).round();
    final buyerProfit = buyerPayment - discountedPrice;
    
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.success.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profit Breakdown',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.success,
            ),
          ),
          const SizedBox(height: 12),
          _buildBreakdownRow('You Pay', '₹${originalPrice.toInt()}', AppTheme.black),
          _buildBreakdownRow('You Get Back', '₹$clientRefund', AppTheme.success),
          const Divider(height: 16),
          _buildBreakdownRow(
            'Your Net Cost', 
            '₹${originalPrice.toInt() - clientRefund}', 
            AppTheme.primaryRed,
            isBold: true,
          ),
          const SizedBox(height: 8),
          Text(
            'You save ₹$clientRefund! 🎉',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.success,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, String value, Color valueColor, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.darkGrey,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: valueColor,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
