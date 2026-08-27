import 'package:flutter/material.dart';
import 'package:corevia_mobile/l10n/app_localizations.dart';
import '../../domain/entities/patient_medication.dart';

class MedicationListCard extends StatelessWidget {
  final PatientMedication medication;
  final VoidCallback? onTap;

  const MedicationListCard({
    super.key,
    required this.medication,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasSchedules = medication.schedules.isNotEmpty;
    final scheduleCount = medication.schedules.length;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Pill icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: medication.isActive
                    ? const Color(0xFFEAF9F0)
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  _formEmoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medication.medicationName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1D1D1F),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (medication.dosageLabel != null &&
                      medication.dosageLabel!.isNotEmpty)
                    Text(
                      medication.dosageLabel!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (hasSchedules) ...[
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$scheduleCount prise${scheduleCount > 1 ? 's' : ''}/jour',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (medication.medicationForm != null) ...[
                        Icon(
                          Icons.category_outlined,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            medication.medicationForm!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Status + arrow
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: medication.isActive
                        ? const Color(0xFFE8FFF0)
                        : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    medication.isActive ? context.l10n.active : context.l10n.inactive,
                    style: TextStyle(
                      color: medication.isActive
                          ? const Color(0xFF34C759)
                          : const Color(0xFFFF9800),
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey.shade400,
                  size: 22,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String get _formEmoji {
    final form = (medication.medicationForm ?? '').toLowerCase();
    if (form.contains('comprimé') || form.contains('tablet')) return '💊';
    if (form.contains('gélule') || form.contains('capsule')) return '💊';
    if (form.contains('sirop') || form.contains('solution') || form.contains('buvable')) return '🧴';
    if (form.contains('injection') || form.contains('injectable')) return '💉';
    if (form.contains('crème') || form.contains('pommade') || form.contains('gel')) return '🧴';
    if (form.contains('collyre') || form.contains('goutte')) return '💧';
    if (form.contains('inhal') || form.contains('spray')) return '🌬️';
    if (form.contains('patch') || form.contains('timbre')) return '🩹';
    if (form.contains('suppo')) return '💊';
    return '💊';
  }
}
