import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../domain/entities/medication_schedule.dart';
import '../../domain/entities/patient_medication.dart';
import '../providers/pillbox_provider.dart';

class MedicationDetailScreen extends StatefulWidget {
  final String medicationId;

  const MedicationDetailScreen({
    super.key,
    required this.medicationId,
  });

  @override
  State<MedicationDetailScreen> createState() => _MedicationDetailScreenState();
}

class _MedicationDetailScreenState extends State<MedicationDetailScreen> {
  PatientMedication? _medication;
  bool _loading = true;
  String? _error;

  static const _green = Color(0xFF34C759);
  static const _dark = Color(0xFF1D1D1F);
  static const _grey = Color(0xFF6B7280);
  static const _bg = Color(0xFFF8F9FB);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final data = await context
        .read<PillboxProvider>()
        .getMedicationDetail(widget.medicationId);
    if (!mounted) return;
    setState(() {
      _medication = data;
      _loading = false;
      if (data == null) _error = context.l10n.medicationNotFound;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _green),
            )
          : _error != null
              ? _buildErrorState()
              : _buildBody(),
    );
  }

  Widget _buildErrorState() {
    return CustomScrollView(
      slivers: [
        _buildAppBar(),
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    size: 36,
                    color: Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _dark,
                  ),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh_rounded, color: _green),
                  label: Text(
                    context.l10n.retry,
                    style: const TextStyle(
                      color: _green,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    final medication = _medication!;
    return CustomScrollView(
      slivers: [
        _buildAppBar(),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            child: Column(
              children: [
                _buildHeroCard(medication),
                const SizedBox(height: 16),
                _buildInfoCard(medication),
                const SizedBox(height: 16),
                _buildSchedulesCard(medication),
                const SizedBox(height: 16),
                _buildActionsCard(medication),
              ],
            ),
          ),
        ),
      ],
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            size: 20, color: _dark),
        onPressed: () {
          if (Navigator.of(context).canPop()) {
            context.pop();
          } else {
            context.go('/pillbox');
          }
        },
      ),
      title: Text(
        context.l10n.medicationDetails,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: _dark,
          letterSpacing: -0.5,
        ),
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFF0F0F0)),
      ),
    );
  }

  // ── Hero card ──────────────────────────────────────────────────────────────

  Widget _buildHeroCard(PatientMedication medication) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: medication.isActive
                  ? const Color(0xFFEAF9F0)
                  : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Center(
              child: Text(
                _formEmoji(medication),
                style: const TextStyle(fontSize: 36),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            medication.medicationName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _dark,
            ),
            textAlign: TextAlign.center,
          ),
          if (medication.medicationForm != null) ...[
            const SizedBox(height: 4),
            Text(
              medication.medicationForm!,
              style: const TextStyle(
                fontSize: 14,
                color: _grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 12),
          _statusBadge(medication.isActive),
        ],
      ),
    );
  }

  // ── Info card ──────────────────────────────────────────────────────────────

  Widget _buildInfoCard(PatientMedication medication) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.information,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _dark,
            ),
          ),
          const SizedBox(height: 14),
          _infoRow(
            Icons.medication_rounded,
            context.l10n.dosage,
            medication.dosageLabel ?? context.l10n.notProvided,
          ),
          _divider(),
          _infoRow(
            Icons.description_outlined,
            context.l10n.instructions,
            medication.instructions ?? context.l10n.noInstruction,
          ),
          _divider(),
          _infoRow(
            Icons.calendar_today_rounded,
            context.l10n.start,
            _formatDateFr(medication.startDate),
          ),
          if (medication.endDate != null) ...[
            _divider(),
            _infoRow(
              Icons.event_rounded,
              context.l10n.end,
              _formatDateFr(medication.endDate!),
            ),
          ],
          if (medication.activeSubstances.isNotEmpty) ...[
            _divider(),
            _infoRow(
              Icons.science_outlined,
              context.l10n.activeSubstances,
              medication.activeSubstances.join(', '),
            ),
          ],
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _editMedication,
              icon: const Icon(Icons.edit_rounded, size: 16, color: _green),
              label: Text(
                context.l10n.edit,
                style: const TextStyle(
                  color: _green,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4F8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: _grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _dark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Divider(
      color: Colors.grey.shade200,
      height: 1,
    );
  }

  // ── Schedules card ─────────────────────────────────────────────────────────

  Widget _buildSchedulesCard(PatientMedication medication) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.scheduleTimes,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _dark,
                ),
              ),
              GestureDetector(
                onTap: _addSchedule,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF9F0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 16, color: _green),
                      SizedBox(width: 4),
                      Text(
                        context.l10n.add,
                        style: const TextStyle(
                          color: _green,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (medication.schedules.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(Icons.schedule_rounded,
                      size: 32, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.noScheduleConfigured,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.addScheduleToTrack,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          else
            ...medication.schedules
                .map((schedule) => _buildScheduleTile(schedule)),
        ],
      ),
    );
  }

  Widget _buildScheduleTile(MedicationSchedule schedule) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF9F0),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_momentIcon(schedule.intakeMoment),
                    color: _green, size: 18),
                const SizedBox(height: 1),
                Text(
                  schedule.intakeTime.length >= 5
                      ? schedule.intakeTime.substring(0, 5)
                      : schedule.intakeTime,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: _green,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _momentLabel(context, schedule.intakeMoment),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _dark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _scheduleSubtitle(schedule),
                  style: const TextStyle(
                    fontSize: 13,
                    color: _grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _iconBtn(
            Icons.edit_rounded,
            const Color(0xFF007AFF),
            () => _editSchedule(schedule),
          ),
          const SizedBox(width: 4),
          _iconBtn(
            Icons.delete_outline_rounded,
            const Color(0xFFEF4444),
            () => _deleteSchedule(schedule.id),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  // ── Actions card ───────────────────────────────────────────────────────────

  Widget _buildActionsCard(PatientMedication medication) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.actions,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _dark,
            ),
          ),
          const SizedBox(height: 14),
          _actionButton(
            icon: medication.isActive
                ? Icons.pause_circle_outline_rounded
                : Icons.play_circle_outline_rounded,
            label: medication.isActive
                ? context.l10n.disableMedication
                : context.l10n.enableMedication,
            color: medication.isActive
                ? const Color(0xFFFF9500)
                : _green,
            bgColor: medication.isActive
                ? const Color(0xFFFFF3E0)
                : const Color(0xFFEAF9F0),
            onTap: _toggleActive,
          ),
          const SizedBox(height: 10),
          _actionButton(
            icon: Icons.delete_outline_rounded,
            label: context.l10n.deleteMedication,
            color: const Color(0xFFEF4444),
            bgColor: const Color(0xFFFEE2E2),
            onTap: _deleteMedication,
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  // ── Status badge ───────────────────────────────────────────────────────────

  Widget _statusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFEAF9F0) : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? _green : const Color(0xFFFF9500),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? context.l10n.active : context.l10n.inactive,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: isActive ? const Color(0xFF1E7E44) : const Color(0xFFE68600),
            ),
          ),
        ],
      ),
    );
  }

  // ── Edit medication (bottom sheet) ─────────────────────────────────────────

  Future<void> _editMedication() async {
    final medication = _medication;
    if (medication == null) return;

    final dosageController =
        TextEditingController(text: medication.dosageLabel ?? '');
    final instructionsController =
        TextEditingController(text: medication.instructions ?? '');
    DateTime startDate = medication.startDate;
    DateTime? endDate = medication.endDate;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.editMedication,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _dark,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _sheetTextField(
                    controller: dosageController,
                    label: context.l10n.dosage,
                    icon: Icons.medication_rounded,
                  ),
                  const SizedBox(height: 14),
                  _sheetTextField(
                    controller: instructionsController,
                    label: context.l10n.instructions,
                    icon: Icons.description_outlined,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 14),
                  _datePickerTile(
                    context: context,
                    label: context.l10n.start,
                    date: startDate,
                    onPick: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setModalState(() => startDate = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  _datePickerTile(
                    context: context,
                    label: context.l10n.end,
                    date: endDate,
                    placeholder: context.l10n.none,
                    onPick: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: endDate ?? startDate,
                        firstDate: startDate,
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setModalState(() => endDate = picked);
                      }
                    },
                    onClear: endDate != null
                        ? () => setModalState(() => endDate = null)
                        : null,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context, false),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              context.l10n.cancel,
                              style: const TextStyle(
                                color: _grey,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _green,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              context.l10n.save,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (saved != true || !mounted) return;

    final payload = <String, dynamic>{
      'dosageLabel': _nullableText(dosageController.text),
      'instructions': _nullableText(instructionsController.text),
      'startDate': _formatDate(startDate),
      'endDate': endDate == null ? null : _formatDate(endDate!),
    };

    try {
      await context
          .read<PillboxProvider>()
          .updateMedication(medication.id, payload);
      await _load();
    } catch (e) {
      debugPrint('MedicationDetail updateMedication error: $e');
    }
  }

  // ── Upsert schedule (bottom sheet) ─────────────────────────────────────────

  Future<void> _addSchedule() async {
    final medication = _medication;
    if (medication == null) return;
    await _upsertSchedule(patientMedicationId: medication.id);
  }

  Future<void> _editSchedule(MedicationSchedule schedule) async {
    await _upsertSchedule(schedule: schedule);
  }

  Future<void> _upsertSchedule({
    String? patientMedicationId,
    MedicationSchedule? schedule,
  }) async {
    TimeOfDay selectedTime = _parseTime(schedule?.intakeTime ?? '08:00');
    final quantityController = TextEditingController(
      text: schedule?.quantity != null
          ? _formatQuantity(schedule!.quantity!)
          : '1',
    );
    final unitController = TextEditingController(text: schedule?.unit ?? '');
    final notesController = TextEditingController(text: schedule?.notes ?? '');
    String intakeMoment = schedule?.intakeMoment ?? 'MORNING';

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    schedule == null
                        ? context.l10n.addSchedule
                        : context.l10n.modifySchedule,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _dark,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Time picker
                  GestureDetector(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (picked != null) {
                        setModalState(() => selectedTime = picked);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_rounded,
                              size: 20, color: _grey),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.timeOfIntake,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: _dark,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          const Icon(Icons.chevron_right_rounded,
                              color: _grey, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Intake moment chips
                  Text(
                    context.l10n.momentOfDay,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _momentChip('MORNING', context.l10n.morning, Icons.wb_sunny_rounded,
                          intakeMoment, (v) {
                        setModalState(() => intakeMoment = v);
                      }),
                      _momentChip('NOON', context.l10n.noon,
                          Icons.wb_twilight_rounded, intakeMoment, (v) {
                        setModalState(() => intakeMoment = v);
                      }),
                      _momentChip('EVENING', context.l10n.evening,
                          Icons.nights_stay_rounded, intakeMoment, (v) {
                        setModalState(() => intakeMoment = v);
                      }),
                      _momentChip('BEDTIME', context.l10n.bedtime,
                          Icons.bedtime_rounded, intakeMoment, (v) {
                        setModalState(() => intakeMoment = v);
                      }),
                      _momentChip('CUSTOM', context.l10n.custom,
                          Icons.more_horiz_rounded, intakeMoment, (v) {
                        setModalState(() => intakeMoment = v);
                      }),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _sheetTextField(
                          controller: quantityController,
                          label: context.l10n.quantity,
                          icon: Icons.numbers_rounded,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _sheetTextField(
                          controller: unitController,
                          label: context.l10n.unitExamples,
                          icon: Icons.straighten_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _sheetTextField(
                    controller: notesController,
                    label: context.l10n.notesOptional,
                    icon: Icons.note_outlined,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context, false),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              context.l10n.cancel,
                              style: const TextStyle(
                                color: _grey,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _green,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              context.l10n.save,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (saved != true || !mounted) return;

    final provider = context.read<PillboxProvider>();
    final timeStr =
        '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
    final body = <String, dynamic>{
      'intakeTime': timeStr,
      'intakeMoment': intakeMoment,
      'quantity': _nullableText(quantityController.text),
      'unit': _nullableText(unitController.text),
      'notes': _nullableText(notesController.text),
    };

    try {
      if (schedule == null) {
        await provider.createSchedule({
          'patientMedicationId': patientMedicationId,
          ...body,
        }..removeWhere((key, value) => value == null));
      } else {
        await provider
            .updateSchedule(schedule.id, body..removeWhere((k, v) => v == null));
      }
      await _load();
    } catch (e) {
      debugPrint('MedicationDetail upsertSchedule error: $e');
    }
  }

  // ── Delete schedule ────────────────────────────────────────────────────────

  Future<void> _deleteSchedule(String scheduleId) async {
    final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: Text(
              context.l10n.deleteScheduleConfirm,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            content: Text(
              context.l10n.irreversibleAction,
              style: const TextStyle(color: _grey),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  context.l10n.cancel,
                  style: const TextStyle(color: _grey, fontWeight: FontWeight.w700),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  context.l10n.delete,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirm || !mounted) return;

    try {
      await context.read<PillboxProvider>().deleteSchedule(scheduleId);
      await _load();
    } catch (e) {
      debugPrint('MedicationDetail deleteSchedule error: $e');
    }
  }

  // ── Toggle active ──────────────────────────────────────────────────────────

  Future<void> _toggleActive() async {
    final medication = _medication;
    if (medication == null) return;
    try {
      await context.read<PillboxProvider>().updateMedication(
            medication.id,
            {'isActive': !medication.isActive},
          );
      await _load();
    } catch (e) {
      debugPrint('MedicationDetail toggleActive error: $e');
    }
  }

  // ── Delete medication ──────────────────────────────────────────────────────

  Future<void> _deleteMedication() async {
    final medication = _medication;
    if (medication == null) return;
    final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: Text(
              context.l10n.confirmDeleteMedication,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            content: Text(
              context.l10n.medicationDeleteWarning,
              style: const TextStyle(color: _grey),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  context.l10n.cancel,
                  style: const TextStyle(color: _grey, fontWeight: FontWeight.w700),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  context.l10n.delete,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirm || !mounted) return;

    try {
      await context.read<PillboxProvider>().deleteMedication(medication.id);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('MedicationDetail deleteMedication error: $e');
    }
  }

  // ── Shared widgets ─────────────────────────────────────────────────────────

  Widget _sheetTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: _grey,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(icon, size: 20, color: _grey),
        filled: true,
        fillColor: const Color(0xFFF8F9FB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _green, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _datePickerTile({
    required BuildContext context,
    required String label,
    DateTime? date,
    String? placeholder,
    required VoidCallback onPick,
    VoidCallback? onClear,
  }) {
    return GestureDetector(
      onTap: onPick,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, size: 20, color: _grey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date != null
                        ? _formatDateFr(date)
                        : (placeholder ?? context.l10n.none),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: date != null ? _dark : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close_rounded, size: 18, color: _grey),
              ),
          ],
        ),
      ),
    );
  }

  Widget _momentChip(String value, String label, IconData icon,
      String current, ValueChanged<String> onSelect) {
    final selected = current == value;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _green : const Color(0xFFF8F9FB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _green : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16, color: selected ? Colors.white : _grey),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : _grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String? _nullableText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _formatDateFr(DateTime date) {
    const months = [
      '', 'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
    ];
    return '${date.day} ${months[date.month]} ${date.year}';
  }

  String _formatQuantity(double value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toString();
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 8,
      minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
    );
  }

  String _momentLabel(BuildContext context, String moment) {
    switch (moment.toUpperCase()) {
      case 'MORNING':
        return context.l10n.morning;
      case 'NOON':
        return context.l10n.noon;
      case 'EVENING':
        return context.l10n.evening;
      case 'BEDTIME':
        return context.l10n.bedtime;
      default:
        return context.l10n.custom;
    }
  }

  IconData _momentIcon(String moment) {
    switch (moment.toUpperCase()) {
      case 'MORNING':
        return Icons.wb_sunny_rounded;
      case 'NOON':
        return Icons.wb_twilight_rounded;
      case 'EVENING':
        return Icons.nights_stay_rounded;
      case 'BEDTIME':
        return Icons.bedtime_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  String _scheduleSubtitle(MedicationSchedule schedule) {
    final parts = <String>[];
    if (schedule.quantity != null) {
      parts.add(_formatQuantity(schedule.quantity!));
    }
    if (schedule.unit != null && schedule.unit!.isNotEmpty) {
      parts.add(schedule.unit!);
    }
    if (schedule.notes != null && schedule.notes!.isNotEmpty) {
      parts.add(schedule.notes!);
    }
    return parts.isEmpty ? context.l10n.noDetails : parts.join(' - ');
  }

  String _formEmoji(PatientMedication medication) {
    final form = (medication.medicationForm ?? '').toLowerCase();
    if (form.contains('comprime') || form.contains('tablet')) return '💊';
    if (form.contains('gelule') || form.contains('capsule')) return '💊';
    if (form.contains('sirop') || form.contains('solution') || form.contains('buvable')) return '🧴';
    if (form.contains('injection') || form.contains('injectable')) return '💉';
    if (form.contains('creme') || form.contains('pommade') || form.contains('gel')) return '🧴';
    if (form.contains('collyre') || form.contains('goutte')) return '💧';
    if (form.contains('inhal') || form.contains('spray')) return '🌬️';
    if (form.contains('patch') || form.contains('timbre')) return '🩹';
    if (form.contains('suppo')) return '💊';
    return '💊';
  }
}
