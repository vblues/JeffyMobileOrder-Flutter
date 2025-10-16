import 'package:flutter/material.dart';
import '../../data/models/store_info_model.dart';

/// Dialog for entering pager number with number pad
class PagerNumberDialog extends StatefulWidget {
  final String? initialPagerNumber;
  final PagerInfo? pagerInfo;

  const PagerNumberDialog({
    super.key,
    this.initialPagerNumber,
    this.pagerInfo,
  });

  @override
  State<PagerNumberDialog> createState() => _PagerNumberDialogState();
}

class _PagerNumberDialogState extends State<PagerNumberDialog> {
  String _pagerNumber = '';

  @override
  void initState() {
    super.initState();
    _pagerNumber = widget.initialPagerNumber ?? '';
  }

  void _onNumberPressed(String number) {
    if (_pagerNumber.length < 3) {
      setState(() {
        _pagerNumber += number;
      });
    }
  }

  void _onBackspace() {
    if (_pagerNumber.isNotEmpty) {
      setState(() {
        _pagerNumber = _pagerNumber.substring(0, _pagerNumber.length - 1);
      });
    }
  }

  void _onClear() {
    setState(() {
      _pagerNumber = '';
    });
  }

  void _onConfirm() {
    if (_pagerNumber.isNotEmpty) {
      Navigator.of(context).pop(_pagerNumber);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 400,
          maxHeight: 600,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Enter Pager Number',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Pager message
              if (widget.pagerInfo?.message != null) ...[
                Text(
                  widget.pagerInfo!.message!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],

              // Display
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    _pagerNumber.isEmpty ? '---' : _pagerNumber.padRight(3, '_'),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Number pad
              _buildNumberPad(),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _onClear,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      child: const Text('Clear'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _pagerNumber.isNotEmpty ? _onConfirm : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                      ),
                      child: const Text('Confirm'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberPad() {
    // Number pad buttons arranged in a grid
    final buttons = [
      '1', '2', '3',
      '4', '5', '6',
      '7', '8', '9',
      'back', '0', 'clear',
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: buttons.length,
      itemBuilder: (context, index) {
        final button = buttons[index];

        if (button == 'back') {
          return _buildSpecialButton(
            icon: Icons.backspace_outlined,
            onPressed: _onBackspace,
          );
        }

        if (button == 'clear') {
          return _buildSpecialButton(
            icon: Icons.clear,
            onPressed: _onClear,
          );
        }

        return _buildNumberButton(button);
      },
    );
  }

  Widget _buildNumberButton(String number) {
    return Material(
      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _onNumberPressed(number),
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Text(
            number,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Icon(
            icon,
            size: 32,
            color: Colors.grey[700],
          ),
        ),
      ),
    );
  }
}

/// Show pager number dialog
Future<String?> showPagerNumberDialog(
  BuildContext context, {
  String? initialPagerNumber,
  PagerInfo? pagerInfo,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: true,
    builder: (context) => PagerNumberDialog(
      initialPagerNumber: initialPagerNumber,
      pagerInfo: pagerInfo,
    ),
  );
}
