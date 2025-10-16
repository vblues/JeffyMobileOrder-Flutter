import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/sales_type_model.dart';
import '../../data/models/store_info_model.dart';
import '../../core/constants/storage_keys.dart';
import '../bloc/sales_type_bloc.dart';
import '../bloc/sales_type_event.dart';
import '../bloc/sales_type_state.dart';
import '../widgets/pager_number_dialog.dart';

class SalesTypePage extends StatelessWidget {
  const SalesTypePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SalesTypeBloc(),
      child: const _SalesTypePageView(),
    );
  }
}

class _SalesTypePageView extends StatelessWidget {
  const _SalesTypePageView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Order Type'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocConsumer<SalesTypeBloc, SalesTypeState>(
        listener: (context, state) {
          if (state is SalesTypeError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }

          if (state is SalesTypeConfirmed) {
            // Navigate to payment page
            // TODO: Implement payment page navigation
            context.push('/payment');
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              // Main content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Text(
                        'How would you like to receive your order?',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 24),

                      // Sales type options
                      _buildSalesTypeCard(
                        context,
                        SalesType.dineIn,
                        state.selectedSalesType == SalesType.dineIn,
                      ),
                      const SizedBox(height: 12),
                      _buildSalesTypeCard(
                        context,
                        SalesType.pickup,
                        state.selectedSalesType == SalesType.pickup,
                      ),

                      // Pager number section (only for dine-in)
                      if (state.selectedSalesType == SalesType.dineIn) ...[
                        const SizedBox(height: 32),
                        _buildPagerNumberSection(context, state),
                      ],

                      // Pickup time selector (only for pickup)
                      if (state.selectedSalesType == SalesType.pickup) ...[
                        const SizedBox(height: 32),
                        _buildPickupTimeSection(context, state),
                      ],
                    ],
                  ),
                ),
              ),

              // Continue button
              _buildContinueButton(context, state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSalesTypeCard(
    BuildContext context,
    SalesType salesType,
    bool isSelected,
  ) {
    return Card(
      elevation: isSelected ? 4 : 1,
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
        onTap: () {
          context.read<SalesTypeBloc>().add(SelectSalesType(salesType));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    salesType.icon,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      salesType.displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      salesType.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              // Selection indicator
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

  Widget _buildPagerNumberSection(BuildContext context, SalesTypeState state) {
    final hasPagerNumber = state.pagerNumber != null && state.pagerNumber!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pager Number',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),

        Card(
          elevation: hasPagerNumber ? 3 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: hasPagerNumber
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey[300]!,
              width: hasPagerNumber ? 2 : 1,
            ),
          ),
          child: InkWell(
            onTap: () async {
              // Get pager info from SharedPreferences
              final prefs = await SharedPreferences.getInstance();
              final storeInfoJson = prefs.getString(StorageKeys.storeInfo);
              PagerInfo? pagerInfo;

              if (storeInfoJson != null) {
                try {
                  final storeInfoData = json.decode(storeInfoJson) as Map<String, dynamic>;
                  final storeNoteJson = storeInfoData['storeNote'] ?? storeInfoData['store_note'];

                  if (storeNoteJson != null) {
                    final storeNote = json.decode(storeNoteJson) as Map<String, dynamic>;
                    final pagerData = storeNote['Pager'] as Map<String, dynamic>?;
                    if (pagerData != null) {
                      pagerInfo = PagerInfo.fromJson(pagerData);
                    }
                  }
                } catch (e) {
                  // Ignore parsing errors
                }
              }

              if (!context.mounted) return;

              final pagerNumber = await showPagerNumberDialog(
                context,
                initialPagerNumber: state.pagerNumber,
                pagerInfo: pagerInfo,
              );

              if (pagerNumber != null && context.mounted) {
                context.read<SalesTypeBloc>().add(SetPagerNumber(pagerNumber));
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.dialpad,
                    color: hasPagerNumber
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[600],
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enter Your Pager Number',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: hasPagerNumber
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasPagerNumber
                              ? 'Pager #${state.pagerNumber}'
                              : 'Tap to enter pager number',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: hasPagerNumber
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey[600],
                                    fontWeight: hasPagerNumber
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    hasPagerNumber ? Icons.check_circle : Icons.arrow_forward_ios,
                    color: hasPagerNumber
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[400],
                    size: hasPagerNumber ? 24 : 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPickupTimeSection(BuildContext context, SalesTypeState state) {
    final schedule = state.schedule;
    final isASAP = schedule?.isASAP ?? true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'When do you want to pick up?',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),

        // ASAP option
        Card(
          elevation: isASAP ? 3 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isASAP
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey[300]!,
              width: isASAP ? 2 : 1,
            ),
          ),
          child: InkWell(
            onTap: () {
              context.read<SalesTypeBloc>().add(ToggleASAP(true));
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.flash_on,
                    color: isASAP
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[600],
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'As Soon As Possible',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isASAP
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Typically ready in 15-20 minutes',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                      ],
                    ),
                  ),
                  if (isASAP)
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Schedule time option
        Card(
          elevation: !isASAP ? 3 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: !isASAP
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey[300]!,
              width: !isASAP ? 2 : 1,
            ),
          ),
          child: InkWell(
            onTap: () async {
              final now = DateTime.now();
              // Default to current time + 30 minutes
              final defaultTime = now.add(const Duration(minutes: 30));
              final initialTime = TimeOfDay(
                hour: defaultTime.hour,
                minute: defaultTime.minute,
              );

              final selectedTime = await showTimePicker(
                context: context,
                initialTime: initialTime,
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      timePickerTheme: TimePickerThemeData(
                        backgroundColor: Colors.white,
                        hourMinuteTextColor:
                            Theme.of(context).colorScheme.primary,
                        dayPeriodTextColor:
                            Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    child: child!,
                  );
                },
              );

              if (selectedTime != null && context.mounted) {
                final pickupTime = DateTime(
                  now.year,
                  now.month,
                  now.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );

                // Validate that selected time is not in the past
                if (pickupTime.isBefore(now)) {
                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pickup time cannot be earlier than current time'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 3),
                    ),
                  );
                  return;
                }

                // If time is in the past (in case of time zone issues), add one day
                final finalTime = pickupTime.isBefore(now)
                    ? pickupTime.add(const Duration(days: 1))
                    : pickupTime;

                context.read<SalesTypeBloc>().add(SetPickupTime(finalTime));
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    color: !isASAP
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[600],
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Schedule for Later',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: !isASAP
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          !isASAP && schedule != null
                              ? schedule.formattedDateTime
                              : 'Choose a pickup time',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: !isASAP
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey[600],
                                    fontWeight: !isASAP
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    !isASAP ? Icons.check_circle : Icons.arrow_forward_ios,
                    color: !isASAP
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[400],
                    size: !isASAP ? 24 : 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton(BuildContext context, SalesTypeState state) {
    final isEnabled = state.isSelectionComplete;

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
                      context.read<SalesTypeBloc>().add(ConfirmSalesType());
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
              ),
              child: const Text(
                'Continue to Payment',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
