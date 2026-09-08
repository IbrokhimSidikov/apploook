import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shimmer/shimmer.dart';

import 'package:apploook/constants/app_colors.dart';
import 'package:apploook/features/loyalty_qr/application/qr_pay_controller.dart';
import 'package:apploook/features/loyalty_qr/domain/loyalty_qr_token.dart';
import 'package:apploook/l10n/app_localizations.dart';

/// Full-screen payment code, reached from the wallet.
///
/// The QR sits on pure white at a generous size because that is what till
/// scanners are calibrated for. The countdown is drawn openly - a code that
/// visibly renews itself reads as "secure", the same code forever reads as
/// "screenshot me".
class QrPayPage extends StatelessWidget {
  const QrPayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => QrPayController()..start(),
      child: const _QrPayView(),
    );
  }
}

class _QrPayView extends StatelessWidget {
  const _QrPayView();

  static final _money = NumberFormat('#,##0', 'en_US');

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<QrPayController>();
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          l10n.qrPayTitle,
          style: TextStyle(
            fontSize: 17.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.cx0B0B0B,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.cx0B0B0B),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: _body(context, controller, l10n),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    QrPayController controller,
    AppLocalizations l10n,
  ) {
    switch (controller.state) {
      case QrPayState.signedOut:
        return _Message(
          icon: Icons.lock_outline_rounded,
          text: l10n.walletSignInRequired,
          buttonLabel: l10n.signIn,
          onPressed: () => Navigator.pushNamed(context, '/signin'),
        );
      case QrPayState.error:
        return _Message(
          icon: Icons.wifi_off_rounded,
          text: l10n.qrPayError,
          buttonLabel: l10n.qrPayRetry,
          onPressed: controller.retry,
        );
      case QrPayState.loading:
      case QrPayState.showing:
        final token = controller.token;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: token == null
                  ? _QrShimmer(size: 240.w)
                  : QrImageView(
                      data: token.qrPayload,
                      version: QrVersions.auto,
                      size: 240.w,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: AppColors.cx0B0B0B,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: AppColors.cx0B0B0B,
                      ),
                    ),
            ),
            SizedBox(height: 16.h),
            if (token != null) _Countdown(token: token, label: l10n.qrPayUpdatesIn),
            SizedBox(height: 24.h),
            if (token != null) ...[
              Text(
                '${_money.format(token.spendable)} ${l10n.currency}',
                style: TextStyle(
                  fontSize: 26.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.cx0B0B0B,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                l10n.walletAvailable,
                style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600),
              ),
              SizedBox(height: 20.h),
            ],
            Text(
              l10n.qrPayHint,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade700),
            ),
          ],
        );
    }
  }
}

class _Countdown extends StatelessWidget {
  final LoyaltyQrToken token;
  final String label;

  const _Countdown({required this.token, required this.label});

  @override
  Widget build(BuildContext context) {
    final int left = token.secondsLeft;
    final int ttl = token.ttlSeconds;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 16.w,
          height: 16.w,
          child: CircularProgressIndicator(
            value: ttl == 0 ? 0 : left / ttl,
            strokeWidth: 2.4,
            color: AppColors.cxFEC700,
            backgroundColor: Colors.grey.shade300,
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          '$label ${left}s',
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey.shade600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _QrShimmer extends StatelessWidget {
  final double size;
  const _QrShimmer({required this.size});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String text;
  final String buttonLabel;
  final VoidCallback onPressed;

  const _Message({
    required this.icon,
    required this.text,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 40.sp, color: Colors.grey.shade400),
        SizedBox(height: 12.h),
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade700),
        ),
        SizedBox(height: 16.h),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.cxFEC700,
            foregroundColor: AppColors.cx0B0B0B,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 12.h),
          ),
          onPressed: onPressed,
          child: Text(
            buttonLabel,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.sp),
          ),
        ),
      ],
    );
  }
}
