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
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width > 600;
    final isMobile = screenSize.width < 400;

    // Calculate appropriate dialog width
    final dialogWidth = isDesktop ? 420.0 : (isMobile ? screenSize.width * 0.9 : 360.0);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxHeight: screenSize.height * 0.85, // Allow dialog to use up to 85% of screen height
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(isDesktop ? 24.0 : 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Enter Pager Number',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: isDesktop ? 24 : 20,
                            ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      iconSize: 24,
                    ),
                  ],
                ),
                SizedBox(height: isDesktop ? 16 : 12),

                // Pager message
                if (widget.pagerInfo?.message != null) ...[
                  Text(
                    widget.pagerInfo!.message!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[700],
                        ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isDesktop ? 16 : 12),
                ],

                // Display
                Container(
                  height: isDesktop ? 80 : 70,
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
                            fontSize: isDesktop ? 36 : 32,
                          ),
                    ),
                  ),
                ),
                SizedBox(height: isDesktop ? 20 : 16),

                // Number pad
                _buildNumberPad(dialogWidth, isDesktop),
                SizedBox(height: isDesktop ? 24 : 20),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _onClear,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: isDesktop ? 16 : 14),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        child: Text('Clear', style: TextStyle(fontSize: isDesktop ? 16 : 14)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _pagerNumber.isNotEmpty ? _onConfirm : null,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: isDesktop ? 16 : 14),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[300],
                        ),
                        child: Text('Confirm', style: TextStyle(fontSize: isDesktop ? 16 : 14)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberPad(double dialogWidth, bool isDesktop) {
    // Calculate button size based on available width
    final horizontalPadding = isDesktop ? 48.0 : 40.0;
    final availableWidth = dialogWidth - horizontalPadding;
    final buttonSpacing = isDesktop ? 12.0 : 10.0;
    final buttonWidth = (availableWidth - (2 * buttonSpacing)) / 3;
    final buttonHeight = isDesktop ? 60.0 : 56.0;

    // Number pad buttons arranged in rows
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Row 1: 1, 2, 3
        _buildButtonRow(['1', '2', '3'], buttonWidth, buttonHeight, buttonSpacing),
        SizedBox(height: buttonSpacing),

        // Row 2: 4, 5, 6
        _buildButtonRow(['4', '5', '6'], buttonWidth, buttonHeight, buttonSpacing),
        SizedBox(height: buttonSpacing),

        // Row 3: 7, 8, 9
        _buildButtonRow(['7', '8', '9'], buttonWidth, buttonHeight, buttonSpacing),
        SizedBox(height: buttonSpacing),

        // Row 4: backspace, 0, clear
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSpecialButton(
              icon: Icons.backspace_outlined,
              onPressed: _onBackspace,
              width: buttonWidth,
              height: buttonHeight,
            ),
            SizedBox(width: buttonSpacing),
            _buildNumberButton('0', buttonWidth, buttonHeight),
            SizedBox(width: buttonSpacing),
            _buildSpecialButton(
              icon: Icons.clear,
              onPressed: _onClear,
              width: buttonWidth,
              height: buttonHeight,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildButtonRow(List<String> numbers, double buttonWidth, double buttonHeight, double spacing) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < numbers.length; i++) ...[
          if (i > 0) SizedBox(width: spacing),
          _buildNumberButton(numbers[i], buttonWidth, buttonHeight),
        ],
      ],
    );
  }

  Widget _buildNumberButton(String number, double width, double height) {
    return SizedBox(
      width: width,
      height: height,
      child: Material(
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
                    fontSize: 28,
                  ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialButton({
    required IconData icon,
    required VoidCallback onPressed,
    required double width,
    required double height,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Icon(
              icon,
              size: 28,
              color: Colors.grey[700],
            ),
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
