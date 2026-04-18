import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../l10n/app_localizations.dart';

/// Maps a numeric current_status_id to one of the 4 delivery stages (0-3).
/// Returns -1 for cancelled / unknown.
///   9  → received   (stage 0)
///  10  → production (stage 1)
///  12  → go/on-the-way (stage 2)
///  26  → delivered  (stage 3)
///  13  → cancelled  (-1)
int deliveryStageFromStatusId(int id) {
  switch (id) {
    case 9:
      return 0;
    case 10:
      return 1;
    case 12:
      return 2;
    case 26:
      return 3;
    case 13:
      return -1;
    default:
      return -1;
  }
}

/// Maps any raw API status string to one of the 4 delivery stages (0-3).
/// Returns -1 for cancelled / unknown.
int deliveryStageFromStatus(String raw) {
  switch (raw.toLowerCase().trim()) {
    // ── Stage 0 – Order received ──────────────────────────────────────────
    case 'new':
    case 'open':
    case 'pending':
    case 'accepted':
    case 'confirmed':
      return 0;

    // ── Stage 1 – Preparing ───────────────────────────────────────────────
    case 'cooking':
    case 'preparing':
    case 'production':
    case 'ready':
      return 1;

    // ── Stage 2 – Delivering ──────────────────────────────────────────────
    case 'on the way':
    case 'delivering':
    case 'on_the_way':
      return 2;

    // ── Stage 3 – Delivered ───────────────────────────────────────────────
    case 'delivered':
    case 'completed':
    case 'closed':
      return 3;

    // ── Cancelled ─────────────────────────────────────────────────────────
    case 'cancel':
    case 'cancelled':
    case 'canceled':
      return -1;

    default:
      return -1;
  }
}

class DeliveryStatusTimeline extends StatelessWidget {
  final String statusName;
  /// When provided, [statusId] takes precedence over [statusName] for stage resolution.
  final int? statusId;

  const DeliveryStatusTimeline({Key? key, required this.statusName, this.statusId})
      : super(key: key);

  static const _stageIcons = [
    Icons.receipt_long_rounded,
    Icons.soup_kitchen_rounded,
    Icons.delivery_dining_rounded,
    Icons.home_rounded,
  ];

  List<_Stage> _buildStages(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return [
      _Stage(icon: _stageIcons[0], label: loc.orderAccepted),
      _Stage(icon: _stageIcons[1], label: loc.orderCooking),
      _Stage(icon: _stageIcons[2], label: loc.orderOnTheWay),
      _Stage(icon: _stageIcons[3], label: loc.orderDelivered),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final currentStage = statusId != null
        ? deliveryStageFromStatusId(statusId!)
        : deliveryStageFromStatus(statusName);
    final isCancelled = currentStage == -1;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isCancelled)
            _buildCancelledBanner(context)
          else
            _buildTimeline(context, currentStage),
        ],
      ),
    );
  }

  // ── Cancelled banner ──────────────────────────────────────────────────────

  Widget _buildCancelledBanner(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.cancel_outlined, color: Colors.red.shade400, size: 18),
          const SizedBox(width: 8),
          Text(
            loc.orderCancelled,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.red.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Timeline ───────────────────────────────────────────────────────────────

  Widget _buildTimeline(BuildContext context, int currentStage) {
    final stages = _buildStages(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(stages.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Connector line
          final stageIndex = i ~/ 2;
          final lineCompleted = currentStage > stageIndex;
          final lineActive = currentStage == stageIndex + 1;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 15),
              child: _AnimatedLine(
                completed: lineCompleted,
                active: lineActive,
              ),
            ),
          );
        } else {
          // Stage node
          final stageIndex = i ~/ 2;
          final completed = currentStage > stageIndex;
          final active = currentStage == stageIndex;
          return _StageNode(
            stage: stages[stageIndex],
            completed: completed,
            active: active,
          );
        }
      }),
    );
  }
}

// ── Stage node ────────────────────────────────────────────────────────────────

class _StageNode extends StatelessWidget {
  final _Stage stage;
  final bool completed;
  final bool active;

  const _StageNode({
    required this.stage,
    required this.completed,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final Color circleColor;
    final Color iconColor;
    final Color labelColor;

    if (completed) {
      circleColor = AppColors.cxFEC700;
      iconColor = Colors.black;
      labelColor = Colors.grey.shade800;
    } else if (active) {
      circleColor = AppColors.cxFEC700.withOpacity(0.15);
      iconColor = AppColors.cxFEC700;
      labelColor = Colors.grey.shade900;
    } else {
      circleColor = Colors.grey.shade100;
      iconColor = Colors.grey.shade400;
      labelColor = Colors.grey.shade400;
    }

    return SizedBox(
      width: 60,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circle
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: circleColor,
              border: active
                  ? Border.all(color: AppColors.cxFEC700, width: 2)
                  : null,
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: AppColors.cxFEC700.withOpacity(0.35),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            child: completed
                ? const Icon(Icons.check_rounded, size: 18, color: Colors.black)
                : Icon(stage.icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 6),
          // Label
          Text(
            stage.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              height: 1.3,
              fontWeight: active || completed
                  ? FontWeight.w600
                  : FontWeight.w400,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Animated connector line ───────────────────────────────────────────────────

class _AnimatedLine extends StatelessWidget {
  final bool completed;
  final bool active;

  const _AnimatedLine({required this.completed, required this.active});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Stack(
        children: [
          // Background track
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Filled portion
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            height: 3,
            width: completed
                ? constraints.maxWidth
                : active
                    ? constraints.maxWidth * 0.5
                    : 0,
            decoration: BoxDecoration(
              color: AppColors.cxFEC700,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      );
    });
  }
}

// ── Data class ─────────────────────────────────────────────────────────────────

class _Stage {
  final IconData icon;
  final String label;

  const _Stage({required this.icon, required this.label});
}

