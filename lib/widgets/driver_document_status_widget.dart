import 'package:flutter/material.dart';
import 'package:nabour_app/l10n/app_localizations.dart';
import 'package:nabour_app/models/driver_document_model.dart';
import 'package:intl/intl.dart';

/// Displays the review status of a single driver document.
/// Shows a status icon (pending / approved / rejected), rejection reason if
/// applicable, and expiry warnings / expired banners.
class DriverDocumentStatusWidget extends StatelessWidget {
  final DriverDocument document;

  const DriverDocumentStatusWidget({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    return Column(
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
    );
  }
}

class _StatusRow extends StatelessWidget {
  final DriverDocument document;
  const _StatusRow({required this.document});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (icon, color, label) = switch (document.status) {
      DriverDocumentStatus.approved => (
          Icons.check_circle,
          Colors.green,
          l10n.docStatusApproved,
        ),
      DriverDocumentStatus.rejected => (
          Icons.cancel,
          Colors.red,
          l10n.docStatusRejected,
        ),
      DriverDocumentStatus.pending => (
          Icons.access_time,
          Colors.orange,
          l10n.docStatusPending,
        ),
    };

    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        if (document.expiryDate != null) ...[
          const SizedBox(width: 8),
          Text(
            l10n.docExpiresOn(DateFormat('dd.MM.yyyy').format(document.expiryDate!)),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
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
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.red.shade700),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              reason,
              style: TextStyle(color: Colors.red.shade700, fontSize: 12),
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
    final color = expired ? Colors.red : Colors.orange;
    final bgColor = expired ? Colors.red.shade50 : Colors.orange.shade50;
    final borderColor = expired ? Colors.red.shade300 : Colors.orange.shade300;
    final dateStr = DateFormat('dd.MM.yyyy').format(expiryDate);
    final label = expired
        ? l10n.docExpiredLabel(dateStr)
        : l10n.docExpiringSoonLabel(dateStr);

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
