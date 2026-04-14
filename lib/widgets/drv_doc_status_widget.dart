import 'package:flutter/material.dart';
import 'package:nabour_app/l10n/app_localizations.dart';
import 'package:nabour_app/models/driver_document_model.dart';
import 'package:intl/intl.dart';

/// Displays the review status of a single driver document with a premium Zen Cybertech aesthetic.
/// Shows a status indicator, rejection reason with glassmorphism, and expiry warnings.
class DriverDocumentStatusWidget extends StatelessWidget {
  final DriverDocument document;

  const DriverDocumentStatusWidget({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusRow(document: document),
          if (document.status == DriverDocumentStatus.rejected &&
              document.rejectionReason != null &&
              document.rejectionReason!.isNotEmpty)
            _RejectionReasonBanner(reason: document.rejectionReason!),
          if (document.isExpired)
            _ExpiryBanner(expired: true, expiryDate: document.expiryDate!)
          else if (document.isExpiringSoon && document.expiryDate != null)
            _ExpiryBanner(expired: false, expiryDate: document.expiryDate!),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final DriverDocument document;
  const _StatusRow({required this.document});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    // Premium Color Palette
    final (icon, color, label, iconBg) = switch (document.status) {
      DriverDocumentStatus.approved => (
          Icons.verified_rounded,
          const Color(0xFF10B981), // Emerald 500
          l10n.docStatusApproved,
          const Color(0xFF10B981).withValues(alpha: 0.1),
        ),
      DriverDocumentStatus.rejected => (
          Icons.gpp_bad_rounded,
          const Color(0xFFF43F5E), // Rose 500
          l10n.docStatusRejected,
          const Color(0xFFF43F5E).withValues(alpha: 0.1),
        ),
      DriverDocumentStatus.pending => (
          Icons.hourglass_top_rounded,
          const Color(0xFFF59E0B), // Amber 500
          l10n.docStatusPending,
          const Color(0xFFF59E0B).withValues(alpha: 0.1),
        ),
    };

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: iconBg,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 11,
            letterSpacing: 0.8,
          ),
        ),
        const Spacer(),
        if (document.expiryDate != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today_outlined, size: 10, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd.MM.yyyy').format(document.expiryDate!),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade600,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _RejectionReasonBanner extends StatelessWidget {
  final String reason;
  const _RejectionReasonBanner({required this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF43F5E).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFF43F5E).withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, size: 16, color: Color(0xFFF43F5E)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              reason,
              style: const TextStyle(
                color: Color(0xFFF43F5E),
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpiryBanner extends StatelessWidget {
  final bool expired;
  final DateTime expiryDate;
  const _ExpiryBanner({required this.expired, required this.expiryDate});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final baseColor = expired ? const Color(0xFFF43F5E) : const Color(0xFFF59E0B);
    final label = expired
        ? l10n.docExpiredLabel(DateFormat('dd.MM.yyyy').format(expiryDate))
        : l10n.docExpiringSoonLabel(DateFormat('dd.MM.yyyy').format(expiryDate));

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: baseColor.withValues(alpha: 0.15),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.report_problem_rounded, size: 14, color: baseColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: baseColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
