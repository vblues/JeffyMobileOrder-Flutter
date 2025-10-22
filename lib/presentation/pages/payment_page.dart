import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/storage_keys.dart';
import '../../core/utils/notification_helper.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/models/sales_type_model.dart';
import '../../data/models/store_info_model.dart';
import '../../data/models/order_history_model.dart';
import '../../data/repositories/payment_repository_impl.dart';
import '../../data/repositories/order_history_repository_impl.dart';
import '../bloc/payment_bloc.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';

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

  Future<void> _saveOrderToHistory({
    required String cloudOrderNumber,
    String? orderNumber,
    required int selectedPaymentMethodId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Find the selected payment method by payCode (selectedPaymentMethodId is actually the payCode)
      final paymentMethod = _paymentMethods.firstWhere(
        (method) => method.payCode == selectedPaymentMethodId.toString(),
        orElse: () => PayTypeInfo(id: 0, payName: 'Unknown', payCode: ''),
      );

      // Create order history item
      final orderHistoryItem = OrderHistoryItem(
        cloudOrderNumber: cloudOrderNumber,
        orderNumber: orderNumber,
        orderDate: DateTime.now(),
        items: _cartItems,
        salesTypeSelection: _salesTypeSelection!,
        paymentMethod: PaymentMethodInfo(
          id: paymentMethod.id,
          name: paymentMethod.payName,
          code: paymentMethod.payCode,
        ),
        totalPrice: _totalPrice,
      );

      // Save to history
      final repository = OrderHistoryRepository(prefs);
      await repository.saveOrder(orderHistoryItem);
    } catch (e) {
      // Ignore errors when saving order history - don't block order success flow
    }
  }

  Future<void> _clearOrderState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Clear all order-related state
      await prefs.remove(StorageKeys.cart);
      await prefs.remove(StorageKeys.salesTypeSelection);

      // Reset blocs to initial state
      if (mounted) {
        // Clear cart bloc - this will update all UI badges immediately
        context.read<CartBloc>().add(ClearCart());
        // Reset payment bloc
        context.read<PaymentBloc>().add(const ResetPayment());
      }
    } catch (e) {
      // Ignore errors when clearing state
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

      // Load payment methods from store info
      final storeInfoJson = prefs.getString(StorageKeys.storeInfo);
      if (storeInfoJson != null) {
        final storeData = json.decode(storeInfoJson) as Map<String, dynamic>;
        final payTypeList = storeData['payTypeInfo'] as List<dynamic>?;
        if (payTypeList != null) {
          _paymentMethods = payTypeList
              .map((e) => PayTypeInfo.fromJson(e as Map<String, dynamic>))
              .where((method) => method.id != 60) // Filter out credit card payment (id 60)
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
                  // Show error dialog for better visibility
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Order Failed'),
                      content: Text(state.message),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('OK'),
                        ),
                      ],
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
                  html.window.console.log('[PaymentPage] PaymentSuccess state detected - order: ${state.orderNumber}, cloud: ${state.cloudOrderNumber}');

                  // Save order to history before clearing state
                  if (state.selectedPaymentMethod != null) {
                    _saveOrderToHistory(
                      cloudOrderNumber: state.cloudOrderNumber,
                      orderNumber: state.orderNumber,
                      selectedPaymentMethodId: state.selectedPaymentMethod!,
                    );
                  }

                  // Clear all order state (cart, sales type, payment)
                  _clearOrderState();

                  // Use store order number if available, otherwise use cloud order number
                  final displayOrderNumber = state.orderNumber?.isNotEmpty == true
                      ? state.orderNumber!
                      : state.cloudOrderNumber;

                  html.window.console.log('[PaymentPage] Triggering notification for order: $displayOrderNumber');

                  // Show browser notification
                  NotificationHelper.showOrderSuccessNotification(
                    orderNumber: displayOrderNumber,
                  );

                  // Show success dialog
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => AlertDialog(
                      title: const Text('Order Successful'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Please proceed to the counter for payment.',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text('Your order is not confirmed until payment is received.'),
                          const SizedBox(height: 16),
                          Text(
                            'Order Number: $displayOrderNumber',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            context.go('/menu');
                          },
                          child: const Text('OK'),
                        ),
                      ],
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

                      // Find the selected payment method to get its pay_code
                      final selectedMethod = _paymentMethods.firstWhere(
                        (m) => m.id == state.selectedPaymentMethod,
                      );

                      // Diagnostic logging for payment submission

                      // Convert pay_code to int with error handling
                      int? paymentCode;
                      try {
                        paymentCode = int.parse(selectedMethod.payCode);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Invalid payment code: ${selectedMethod.payCode}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }


                      context.read<PaymentBloc>().add(
                            SubmitOrder(
                              cartItems: _cartItems,
                              salesTypeSelection: _salesTypeSelection!,
                              paymentMethodId: paymentCode,  // Use pay_code instead of id
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
