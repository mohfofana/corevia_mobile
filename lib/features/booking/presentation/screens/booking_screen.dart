import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:corevia_mobile/l10n/app_localizations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/booking_provider.dart';

class BookingScreen extends StatefulWidget {
  final String doctorId;
  final String doctorName;
  final String specialty;
  final String imageUrl;
  final String address;

  const BookingScreen({
    super.key,
    String? doctorId,
    String? doctorName,
    String? specialty,
    String? imageUrl,
    String? address,
  })  : doctorId = doctorId ?? '',
        doctorName = doctorName ?? '',
        specialty = specialty ?? '',
        imageUrl = imageUrl ?? 'https://via.placeholder.com/150',
        address = address ?? '';

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedTimeSlot;

  List<DateTime> _nextSevenDays() {
    return List.generate(7, (index) => DateTime.now().add(Duration(days: index)));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSlots();
    });
  }

  String _toApiDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _dateLocaleName(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return locale.languageCode == 'fr' ? 'fr_FR' : 'en_US';
  }

  Future<void> _loadSlots() async {
    if (widget.doctorId.isEmpty) return;
    await context.read<BookingProvider>().loadAvailableSlots(
          doctorId: widget.doctorId,
          date: _toApiDate(_selectedDate),
        );
  }

  Future<void> _confirmBooking() async {
    if (_selectedTimeSlot == null) return;
    if (widget.doctorId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.invalidDoctor)),
      );
      return;
    }

    final appointment = await context.read<BookingProvider>().createAppointment(
          doctorId: widget.doctorId,
          date: _toApiDate(_selectedDate),
          time: _selectedTimeSlot!,
        );
    if (!mounted) return;

    if (appointment == null) {
      final err = context.read<BookingProvider>().error ??
          context.l10n.createAppointmentFailed;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }

    context.push(
      '/calendar/booking/confirmation',
      extra: {
        'doctorId': widget.doctorId,
        'doctorName': widget.doctorName,
        'specialty': widget.specialty,
        'imageUrl': widget.imageUrl,
        'address': widget.address,
        'date': _selectedDate,
        'timeSlot': _selectedTimeSlot!,
        'appointmentId': appointment.id,
        'status': appointment.status,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildDoctorCard(),
                    const SizedBox(height: 24),
                    _buildDateSelection(),
                    const SizedBox(height: 24),
                    _buildTimeSlotSelection(),
                    const SizedBox(height: 40),
                    _buildConfirmButton(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  size: 20, color: Color(0xFF1D1D1F)),
            ),
          ),
          Text(
            context.l10n.bookAppointment,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _buildDoctorCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                widget.imageUrl,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 56,
                  height: 56,
                  color: Colors.grey[200],
                  child: const Icon(Icons.person, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.doctorName.isNotEmpty ? widget.doctorName : context.l10n.doctor,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 2),
                  if (widget.specialty.isNotEmpty)
                    Text(widget.specialty,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  if (widget.specialty.isNotEmpty) const SizedBox(height: 2),
                  if (widget.address.isNotEmpty)
                    Text(widget.address,
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelection() {
    final localeName = _dateLocaleName(context);
    return SizedBox(
      height: 90,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _nextSevenDays().length,
        itemBuilder: (context, index) {
          final date = _nextSevenDays()[index];
          final isSelected = DateFormat('yyyy-MM-dd').format(date) ==
              DateFormat('yyyy-MM-dd').format(_selectedDate);
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
                _selectedTimeSlot = null;
              });
              _loadSlots();
            },
            child: Container(
              width: 70,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF34C759) : Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(DateFormat('EEE', localeName).format(date),
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  Text(DateFormat('dd', localeName).format(date),
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : const Color(0xFF1D1D1F))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeSlotSelection() {
    return Consumer<BookingProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingSlots) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF34C759)),
          );
        }
        if (provider.availableSlots.isEmpty) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(context.l10n.noAvailableSlotsMessage),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: provider.availableSlots.map((time) {
              final isSelected = _selectedTimeSlot == time;
              return GestureDetector(
                onTap: () => setState(() => _selectedTimeSlot = time),
                child: Container(
                  width: (MediaQuery.of(context).size.width - 60) / 3,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF34C759) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          isSelected ? const Color(0xFF34C759) : Colors.grey.shade200,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    time,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : const Color(0xFF1D1D1F),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildConfirmButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: _selectedTimeSlot != null
              ? const LinearGradient(colors: [Color(0xFF34C759), Color(0xFF30D158)])
              : null,
          color: _selectedTimeSlot == null ? Colors.grey.shade300 : null,
          borderRadius: BorderRadius.circular(20),
        ),
        child: ElevatedButton(
          onPressed: _selectedTimeSlot != null ? _confirmBooking : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                context.l10n.confirmBooking,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 8),
              Icon(LucideIcons.arrowRight, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
