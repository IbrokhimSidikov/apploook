import 'dart:async';
import 'package:apploook/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:apploook/services/rahmat_pay_service.dart';
import 'package:provider/provider.dart';
import 'package:apploook/cart_provider.dart';

/// Service to handle Rahmat Pay transaction status checking
/// Similar to PaymeTransactionService but for Rahmat Pay
class RahmatPayTransactionService {
  /// Shows a dialog that polls for payment status
  /// Checks every 3 seconds for up to 5 minutes
  static void startPaymentStatusCheck(
    BuildContext context,
    String invoiceId,
    String branchName,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _PaymentStatusDialog(
        invoiceId: invoiceId,
        branchName: branchName,
        parentContext: context,
      ),
    );
  }
}

/// Dialog widget that displays payment status and polls for updates
class _PaymentStatusDialog extends StatefulWidget {
  final String invoiceId;
  final String branchName;
  final BuildContext parentContext;

  const _PaymentStatusDialog({
    required this.invoiceId,
    required this.branchName,
    required this.parentContext,
  });

  @override
  State<_PaymentStatusDialog> createState() => _PaymentStatusDialogState();
}

class _PaymentStatusDialogState extends State<_PaymentStatusDialog> {
  Timer? _statusCheckTimer;
  String _statusMessage = 'Waiting for payment...';
  bool _isChecking = false;
  int _checkCount = 0;
  static const int _maxChecks = 100; // 100 checks * 3 seconds = 5 minutes
  static const Duration _checkInterval = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _startStatusChecking();
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  void _startStatusChecking() {
    print('🔄 Starting Rahmat Pay status checking for invoice: ${widget.invoiceId}');
    
    // Start periodic status checks
    _statusCheckTimer = Timer.periodic(_checkInterval, (timer) async {
      if (_checkCount >= _maxChecks) {
        print('⏱️ Maximum check attempts reached (${_maxChecks})');
        _statusCheckTimer?.cancel();
        _handleTimeout();
        return;
      }

      _checkCount++;
      await _checkPaymentStatus();
    });

    // Also check immediately
    _checkPaymentStatus();
  }

  Future<void> _checkPaymentStatus() async {
    if (_isChecking || !mounted) return;

    if (mounted) {
      setState(() {
        _isChecking = true;
        _statusMessage = 'Checking payment status... (${_checkCount}/${_maxChecks})';
      });
    }

    try {
      print('🔍 Checking payment status (attempt ${_checkCount}/${_maxChecks})');
      
      final result = await RahmatPayService.checkPaymentStatus(widget.invoiceId, widget.branchName);
      
      if (!mounted) return;
      
      if (result['success'] == true) {
        final status = result['status'] as String?;
        print('✅ Payment status: $status');
        
        if (status == 'success' || status == 'paid' || status == 'completed') {
          // Payment successful!
          _statusCheckTimer?.cancel();
          _handlePaymentSuccess();
        } else if (status == 'failed' || status == 'cancelled' || status == 'error') {
          // Payment failed
          _statusCheckTimer?.cancel();
          _handlePaymentFailure(status);
        } else {
          // Still pending, continue checking
          if (mounted) {
            setState(() {
              _statusMessage = 'Payment status: $status\nWaiting for completion...';
            });
          }
        }
      } else {
        // Error checking status, but continue trying
        print('⚠️ Error checking status: ${result['error']}');
        if (mounted) {
          setState(() {
            _statusMessage = 'Checking payment...\n(${_checkCount}/${_maxChecks})';
          });
        }
      }
    } catch (e) {
      print('❌ Exception checking payment status: $e');
      if (mounted) {
        setState(() {
          _statusMessage = 'Checking payment...\n(${_checkCount}/${_maxChecks})';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  void _handlePaymentSuccess() async {
    print('✅ Payment successful! Clearing cart and navigating to home');
    
    // Clear pending payment
    await RahmatPayService.clearPendingCardPayment();
    
    // Clear the cart
    if (widget.parentContext.mounted) {
      final cartProvider = Provider.of<CartProvider>(widget.parentContext, listen: false);
      cartProvider.clearCart();
    }
    
    // Close the status dialog
    if (mounted) {
      Navigator.of(context).pop();
    }
    
    // Show success dialog
    if (widget.parentContext.mounted) {
      showDialog(
        context: widget.parentContext,
        barrierDismissible: false,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.green[50]!,
                  Colors.white,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success icon with animation effect
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green[100],
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green[600],
                    size: 60,
                  ),
                ),
                SizedBox(height: 24),
                
                // Title
                Text(
                  'Payment Successful!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                
                // Message
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        color: Colors.green[600],
                        size: 32,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Your payment has been processed successfully!',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Your order has been placed.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                
                // OK button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close success dialog
                      // Navigate to home
                      Navigator.of(widget.parentContext).pushNamedAndRemoveUntil(
                        '/homeNew',
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      'Continue Shopping',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  void _handlePaymentFailure(String? status) async {
    print('❌ Payment failed with status: $status');
    
    // Clear pending payment
    await RahmatPayService.clearPendingCardPayment();
    
    // Close the status dialog
    if (mounted) {
      Navigator.of(context).pop();
    }
    
    // Show failure dialog
    if (widget.parentContext.mounted) {
      showDialog(
        context: widget.parentContext,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.red[50]!,
                  Colors.white,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Error icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red[100],
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.cancel,
                    color: Colors.red[600],
                    size: 60,
                  ),
                ),
                SizedBox(height: 24),
                
                // Title
                Text(
                  status == 'cancelled' ? 'Payment Cancelled' : 'Payment Failed',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                
                // Message
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        status == 'cancelled' 
                          ? Icons.info_outline 
                          : Icons.error_outline,
                        color: Colors.red[600],
                        size: 32,
                      ),
                      SizedBox(height: 12),
                      Text(
                        status == 'cancelled'
                          ? 'You have cancelled the payment.'
                          : 'Your payment could not be processed.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Status: ${status ?? "unknown"}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[800],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Please try again or use a different payment method.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                
                // Try Again button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      'Try Again',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  void _handleTimeout() async {
    print('⏱️ Payment status check timed out');
    
    // Close the status dialog
    if (mounted) {
      Navigator.of(context).pop();
    }
    
    // Show timeout dialog
    if (widget.parentContext.mounted) {
      showDialog(
        context: widget.parentContext,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.orange[50]!,
                  Colors.white,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Warning icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.orange[100],
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.access_time_rounded,
                    color: Colors.orange[700],
                    size: 60,
                  ),
                ),
                SizedBox(height: 24),
                
                // Title
                Text(
                  'Payment Status Unknown',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                
                // Message
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.help_outline,
                        color: Colors.orange[700],
                        size: 32,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'We could not verify your payment status.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 12),
                      Divider(color: Colors.orange[100]),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.check_circle_outline, 
                            color: Colors.green[600], size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'If you completed the payment, your order will be processed.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.support_agent, 
                            color: Colors.blue[600], size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Check your order history or contact support if needed.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                
                // OK button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      'I Understand',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  void _handleCancel() {
    _statusCheckTimer?.cancel();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back button
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 8,
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey[50]!,
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFEC700).withOpacity(0.1),
                  border: Border.all(
                    color: Color(0xFFFEC700),
                    width: 3,
                  ),
                ),
                child: Center(
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFEC700)),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24),
              
              // Title
              Text(
                AppLocalizations.of(context).processingPayment,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 12),
              
              // Status message
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue[100]!,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue[700],
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        AppLocalizations.of(context).waitingForConfirmation,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[900],
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              
              // Instructions
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Color(0xFFFEC700),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '1',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context).completeBrowserTitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Color(0xFFFEC700),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '2',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context).returnToApp,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              
              // Progress bar
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context).checkingStatus,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${_checkCount}/${_maxChecks}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: _checkCount / _maxChecks,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFEC700)),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              
              // Cancel button
              TextButton(
                onPressed: _handleCancel,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context).cancelButton,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
