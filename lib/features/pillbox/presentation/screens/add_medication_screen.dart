import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../domain/entities/medication_search_result.dart';
import '../providers/medication_search_provider.dart';
import '../providers/pillbox_provider.dart';

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _unitController = TextEditingController(text: 'comprime');

  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);
  String _intakeMoment = 'MORNING';
  MedicationSearchResult? _selectedSearchResult;

  static const _green = Color(0xFF34C759);
  static const _dark = Color(0xFF1D1D1F);
  static const _grey = Color(0xFF6B7280);
  static const _bg = Color(0xFFF8F9FB);

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _dosageController.dispose();
    _instructionsController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchProvider = context.watch<MedicationSearchProvider>();
    final pillboxProvider = context.watch<PillboxProvider>();

    return Scaffold(
      backgroundColor: _bg,
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 130),
                child: Column(
                  children: [
                    _buildHeroCard(),
                    const SizedBox(height: 16),
                    _buildSearchCard(searchProvider),
                    const SizedBox(height: 16),
                    _buildInfoCard(),
                    const SizedBox(height: 16),
                    _buildScheduleCard(),
                    if (pillboxProvider.error != null) ...[
                      const SizedBox(height: 16),
                      _buildErrorBanner(pillboxProvider.error!),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: pillboxProvider.isSubmitting ? null : _submit,
            child: pillboxProvider.isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    context.l10n.addToPillbox,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // ── App bar ────────────────────────────────────────────────────────────────

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
        context.l10n.addMedication,
        style: TextStyle(
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

  Widget _buildHeroCard() {
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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF9F0),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.medication_outlined,
                color: _green, size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nouveau traitement',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _dark,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Creez un traitement avec son horaire de prise.',
                  style: TextStyle(
                    fontSize: 13,
                    color: _grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Search card ────────────────────────────────────────────────────────────

  Widget _buildSearchCard(MedicationSearchProvider searchProvider) {
    return _card(
      title: context.l10n.search,
      child: Column(
        children: [
          _styledTextField(
            controller: _searchController,
            label: context.l10n.searchMedication,
            icon: Icons.search_rounded,
            onChanged: context.read<MedicationSearchProvider>().search,
            hint: context.l10n.minimum3Characters,
          ),
          if (searchProvider.isSearching) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(
              minHeight: 3,
              color: _green,
              backgroundColor: Color(0xFFEAF9F0),
            ),
          ],
          if (_selectedSearchResult != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF9F0),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: _green, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _selectedSearchResult!.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E7E44),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() {
                      _selectedSearchResult = null;
                      _nameController.clear();
                    }),
                    child: const Icon(Icons.close_rounded,
                        size: 18, color: Color(0xFF1E7E44)),
                  ),
                ],
              ),
            ),
          ],
          if (searchProvider.results.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...searchProvider.results.take(5).map(
                  (result) => _searchResultTile(result),
                ),
          ],
          if (!searchProvider.isSearching &&
              _searchController.text.trim().length >= 3 &&
              searchProvider.results.isEmpty &&
              searchProvider.error == null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 18, color: Colors.grey.shade400),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.l10n.noResultsFound,
                      style: const TextStyle(color: _grey, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (searchProvider.error != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 18, color: Color(0xFFEF4444)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      searchProvider.error!,
                      style: const TextStyle(
                        color: Color(0xFFB42318),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _searchResultTile(MedicationSearchResult result) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        onTap: () => _selectSearchResult(result),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4F8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.medication_rounded,
                  size: 18, color: _grey),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: _dark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (result.form != null)
                    Text(
                      result.form!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: _grey),
          ],
        ),
      ),
    );
  }

  // ── Info card ──────────────────────────────────────────────────────────────

  Widget _buildInfoCard() {
    return _card(
      title: context.l10n.information,
      child: Column(
        children: [
          _styledTextFormField(
            controller: _nameController,
            label: context.l10n.medicationName,
            icon: Icons.medication_rounded,
            validator: (value) => (value == null || value.trim().isEmpty)
                ? context.l10n.requiredField
                : null,
          ),
          const SizedBox(height: 14),
          _styledTextField(
            controller: _dosageController,
            label: context.l10n.dosage,
            icon: Icons.description_outlined,
          ),
          const SizedBox(height: 14),
          _styledTextField(
            controller: _instructionsController,
            label: context.l10n.instructions,
            icon: Icons.note_outlined,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  // ── Schedule card ──────────────────────────────────────────────────────────

  Widget _buildScheduleCard() {
    return _card(
      title: context.l10n.scheduleTimes,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _datePickerTile(
                  label: context.l10n.start,
                  date: _startDate,
                  onPick: _pickStartDate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _timePickerTile(
                  label: context.l10n.timeOfIntake,
                  time: _time,
                  onPick: _pickTime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _datePickerTile(
            label: context.l10n.end,
            date: _endDate,
            placeholder: context.l10n.none,
            onPick: _pickEndDate,
            onClear: _endDate != null ? () => setState(() => _endDate = null) : null,
          ),
          const SizedBox(height: 14),
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
              _momentChip('MORNING', context.l10n.morning, Icons.wb_sunny_rounded),
              _momentChip('NOON', context.l10n.noon, Icons.wb_twilight_rounded),
              _momentChip('EVENING', context.l10n.evening, Icons.nights_stay_rounded),
              _momentChip('BEDTIME', context.l10n.bedtime, Icons.bedtime_rounded),
              _momentChip('CUSTOM', context.l10n.other, Icons.more_horiz_rounded),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _styledTextField(
                  controller: _quantityController,
                  label: context.l10n.quantity,
                  icon: Icons.numbers_rounded,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _styledTextField(
                  controller: _unitController,
                  label: context.l10n.unitExamples,
                  icon: Icons.straighten_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Shared widgets ─────────────────────────────────────────────────────────

  Widget _card({required String title, required Widget child}) {
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
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _dark,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _styledTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
    String? hint,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(
          color: _grey,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, size: 20, color: _grey),
        filled: true,
        fillColor: _bg,
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

  Widget _styledTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: _grey,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(icon, size: 20, color: _grey),
        filled: true,
        fillColor: _bg,
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _datePickerTile({
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
          color: _bg,
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
                    date != null ? _formatDateFr(date) : (placeholder ?? ''),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: date != null ? _dark : _grey,
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

  Widget _timePickerTile({
    required String label,
    required TimeOfDay time,
    required VoidCallback onPick,
  }) {
    return GestureDetector(
      onTap: onPick,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time_rounded, size: 20, color: _grey),
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
                    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
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
      ),
    );
  }

  Widget _momentChip(String value, String label, IconData icon) {
    final selected = _intakeMoment == value;
    return GestureDetector(
      onTap: () => setState(() => _intakeMoment = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _green : _bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _green : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? Colors.white : _grey),
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

  Widget _buildErrorBanner(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 20, color: Color(0xFFEF4444)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                color: Color(0xFFB42318),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  void _selectSearchResult(MedicationSearchResult result) {
    setState(() {
      _selectedSearchResult = result;
      _nameController.text = result.name;
    });
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate,
      firstDate: _startDate,
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) {
      setState(() => _time = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final time =
        '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';
    final quantity = _quantityController.text.trim();
    final payload = <String, dynamic>{
      'medicationName': _nameController.text.trim(),
      'medicationExternalId': _selectedSearchResult?.externalId,
      'source': _selectedSearchResult?.source,
      'cis': _selectedSearchResult?.cis,
      'cip': _selectedSearchResult?.cip,
      'medicationForm': _selectedSearchResult?.form,
      'activeSubstances': _selectedSearchResult?.activeSubstances,
      'dosageLabel': _nullableText(_dosageController.text),
      'instructions': _nullableText(_instructionsController.text),
      'startDate': _formatDate(_startDate),
      'endDate': _endDate != null ? _formatDate(_endDate!) : null,
      'schedules': [
        {
          'intakeTime': time,
          'intakeMoment': _intakeMoment,
          'weekday': null,
          'quantity': quantity.isNotEmpty ? quantity : null,
          'unit': _nullableText(_unitController.text),
          'notes': null,
        }
      ],
    }..removeWhere((_, value) => value == null);

    try {
      await context.read<PillboxProvider>().createMedication(payload);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {}
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
    return DateFormat.yMMMMd('fr_FR').format(date);
  }
}
