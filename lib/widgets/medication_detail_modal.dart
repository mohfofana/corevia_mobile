import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../l10n/app_localizations.dart';
import './pill_shadow.dart';

class MedicationDetailModal extends StatelessWidget {
  final String medicationName;
  final String dosage;
  final String frequency;
  final String time;
  final String description;
  final String prescribedBy;
  final String startDate;
  final String endDate;
  final String instructions;
  final String? intakeId;
  final String? intakeStatus;
  final VoidCallback? onTaken;
  final VoidCallback? onSkipped;

  const MedicationDetailModal({
    super.key,
    required this.medicationName,
    required this.dosage,
    required this.frequency,
    required this.time,
    required this.description,
    required this.prescribedBy,
    required this.startDate,
    required this.endDate,
    required this.instructions,
    this.intakeId,
    this.intakeStatus,
    this.onTaken,
    this.onSkipped,
  });

  bool get _isTaken => intakeStatus?.toUpperCase() == 'TAKEN';
  bool get _isSkipped => intakeStatus?.toUpperCase() == 'SKIPPED';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // --- Contenu du dialog ---
          Container(
            margin: const EdgeInsets.only(top: 75), // laisse la place à l'image
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20), // espace sous l'image

                  // Header
                  Row(
                    children: [
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              medicationName,
                              style: const TextStyle(
                                fontSize: 35,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$dosage . $time',
                                  style: const TextStyle(color: Colors.black),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  _buildInfoRow(
                      LucideIcons.repeat, context.l10n.frequency, frequency),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                      LucideIcons.calendar, context.l10n.start, startDate),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                      LucideIcons.calendarCheck, context.l10n.end, endDate),

                  const SizedBox(height: 24),
                  Text(
                    context.l10n.description,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),

                  const SizedBox(height: 16),
                  Text(
                    context.l10n.instructions,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    instructions,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),

                  const SizedBox(height: 24),
                  if (_isTaken || _isSkipped)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        _isTaken
                            ? context.l10n.intakeAlreadyTaken(medicationName)
                            : context.l10n.intakeSkipped(medicationName),
                        style: TextStyle(
                          color: _isTaken ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(LucideIcons.check, color: Colors.white),
                      label: Text(
                        context.l10n.markAsTaken,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF34C759),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        if (onTaken != null) {
                          onTaken!();
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                context.l10n.markedAsTaken(medicationName)),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        if (onSkipped != null) {
                          onSkipped!();
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                context.l10n.skippedMedication(medicationName)),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFFE0E0E0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(context.l10n.skip),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- Image centrée sur la bordure du haut ---
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: PillShadow(
                assetPath: 'assets/pill2.png',
                widthValue: 150,
                heightValue: 150,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: Colors.grey.shade700),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            Text(value,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}

// Pour l'utiliser dans votre app :
// showDialog(
//   context: context,
//   builder: (context) => MedicationDetailModal(
//     medicationName: "Paracetamol",
//     dosage: "500mg",
//     frequency: "2x daily",
//     time: "8:00 AM",
//     description: "Pain relief medication",
//     prescribedBy: "Dr. Smith",
//     startDate: "Jan 1, 2024",
//     endDate: "Jan 15, 2024",
//     instructions: "Take with food",
//   ),
// );
