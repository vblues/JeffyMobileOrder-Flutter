import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/storage_keys.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/models/sales_type_model.dart';
import '../../data/models/store_info_model.dart';
import '../../data/repositories/payment_repository_impl.dart';
import '../bloc/payment_bloc.dart';

class PaymentPage extends StatelessWidget {
  const PaymentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PaymentBloc(
        PaymentRepository(),
      ),
      child: const _PaymentPageView(),
    );
  }
}

class _PaymentPageView extends StatefulWidget {
  const _PaymentPageView();

  @override
  State<_PaymentPageView> createState() => _PaymentPageViewState();
}

class _PaymentPageViewState extends State<_PaymentPageView> {
  List<CartItem> _cartItems = [];
  SalesTypeSelection? _salesTypeSelection;
  List<PayTypeInfo> _paymentMethods = [];
  double _totalPrice = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _clearCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(StorageKeys.cart);
    } catch (e) {
      // Ignore errors when clearing cart
    }
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load cart items
      final cartJson = prefs.getString(StorageKeys.cart);
      if (cartJson != null) {
        final cartData = json.decode(cartJson) as List<dynamic>;
        _cartItems = cartData.map((item) => CartItem.fromJson(item as Map<String, dynamic>)).toList();
      }

      // Calculate total price
      _totalPrice = _cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);

      // Load sales type selection
      final salesTypeJson = prefs.getString(StorageKeys.salesTypeSelection);
      if (salesTypeJson != null) {
        _salesTypeSelection = SalesTypeSelection.fromJson(
          json.decode(salesTypeJson) as Map<String, dynamic>,
        );
      }

      // Load payment methods from stored credentials
      final storeCredentialsJson = prefs.getString(StorageKeys.storeCredentials);
      if (storeCredentialsJson != null) {
        final storeData = json.decode(storeCredentialsJson) as Map<String, dynamic>;
        final payTypeList = storeData['payTypeInfo'] as List<dynamic>?;
        if (payTypeList != null) {
          _paymentMethods = payTypeList
              .map((e) => PayTypeInfo.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading payment data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : BlocConsumer<PaymentBloc, PaymentState>(
              listener: (context, state) {
                if (state is PaymentError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }

                if (state is PaymentSubmitted && state.requiresGateway) {
                  // Navigate to payment gateway page
                  // TODO: Implement payment gateway integration
                  context.push('/processing', extra: {
                    'sessionId': state.sessionId,
                    'cloudOrderNumber': state.cloudOrderNumber,
                  });
                }

                if (state is PaymentSuccess) {
                  // Clear cart manually since we don't have CartBloc here
                  _clearCart();
                  // Navigate to success page (placeholder for now)
                  context.go('/menu');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Order placed successfully! Order #: ${state.cloudOrderNumber}'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              },
              builder: (context, state) {
                final isSubmitting = state is PaymentSubmitting;

                return Column(
                  children: [
                    // Order Summary
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Sales Type Info
                            if (_salesTypeSelection != null) ...[
                              _buildSalesTypeCard(),
                              const SizedBox(height: 16),
                            ],

                            // Total Price
                            Card(
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total Price',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    Text(
                                      '\$${_totalPrice.toStringAsFixed(2)}',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Payment Methods
                            Text(
                              'Select Payment Method',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            ..._paymentMethods.map((method) => _buildPaymentMethodCard(
                                  context,
                                  method,
                                  state.selectedPaymentMethod == method.id,
                                  isSubmitting,
                                )),
                          ],
                        ),
                      ),
                    ),

                    // Confirm Button
                    _buildConfirmButton(context, state, isSubmitting),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildSalesTypeCard() {
    if (_salesTypeSelection == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _salesTypeSelection!.salesType.icon,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  _salesTypeSelection!.salesType.displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            if (_salesTypeSelection!.schedule != null) ...[
              const SizedBox(height: 8),
              Text(
                'Pickup Time: ${_salesTypeSelection!.schedule!.formattedDateTime}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (_salesTypeSelection!.pagerNumber != null &&
                _salesTypeSelection!.pagerNumber!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Pager Number: ${_salesTypeSelection!.pagerNumber}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard(
    BuildContext context,
    PayTypeInfo method,
    bool isSelected,
    bool isSubmitting,
  ) {
    // Determine payment method display
    String methodName;
    IconData methodIcon;

    if (method.id == 23) {
      methodName = 'Pay at Counter';
      methodIcon = Icons.store;
    } else if (method.id == 60) {
      methodName = 'Pay by Credit Card';
      methodIcon = Icons.credit_card;
    } else {
      methodName = method.payName;
      methodIcon = Icons.payment;
    }

    return Card(
      elevation: isSelected ? 4 : 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: isSubmitting
            ? null
            : () {
                context.read<PaymentBloc>().add(SelectPaymentMethod(method.id));
              },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                methodIcon,
                size: 32,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[600],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  methodName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmButton(
    BuildContext context,
    PaymentState state,
    bool isSubmitting,
  ) {
    final isEnabled = state.selectedPaymentMethod != null && !isSubmitting;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: isEnabled
                  ? () {
                      if (_salesTypeSelection == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Sales type information is missing'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      context.read<PaymentBloc>().add(
                            SubmitOrder(
                              cartItems: _cartItems,
                              salesTypeSelection: _salesTypeSelection!,
                              paymentMethodId: state.selectedPaymentMethod!,
                            ),
                          );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
              ),
              child: isSubmitting
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Confirm Payment',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
