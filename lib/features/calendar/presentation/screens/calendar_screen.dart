import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:corevia_mobile/l10n/app_localizations.dart';
import '../../../booking/domain/entities/appointment.dart';
import '../../../booking/presentation/providers/booking_provider.dart';

enum CalendarTab { programme, list }

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, this.initialTab = CalendarTab.programme});

  final CalendarTab initialTab;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarTab _selectedTab = CalendarTab.programme;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR');
    _selectedTab = widget.initialTab;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<BookingProvider>();
      provider.loadDoctors();
      provider.loadMyAppointments();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
              child:
                  _selectedTab == CalendarTab.programme ? _buildSchedule() : _buildDoctors(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                context.l10n.calendar,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = CalendarTab.programme),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                        color: _selectedTab == CalendarTab.programme
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        context.l10n.schedule,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: _selectedTab == CalendarTab.programme
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = CalendarTab.list),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color:
                            _selectedTab == CalendarTab.list ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        context.l10n.lists,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: _selectedTab == CalendarTab.list
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchedule() {
    return Consumer<BookingProvider>(
      builder: (context, provider, _) {
        final appointments = provider.appointments;

        if (provider.isLoadingAppointments && appointments.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF34C759)),
          );
        }

        if (provider.error != null && appointments.isEmpty) {
          return _buildDoctorsError(
            provider.error!,
            onRetry: () => provider.loadMyAppointments(),
          );
        }

        if (appointments.isEmpty) {
          return RefreshIndicator(
            color: const Color(0xFF34C759),
            onRefresh: () => provider.loadMyAppointments(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 80),
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Aucun rendez-vous pour le moment.\nConsultez la liste des medecins pour en prendre un.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: const Color(0xFF34C759),
          onRefresh: () => provider.loadMyAppointments(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: appointments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) =>
                _buildAppointmentCard(appointments[index]),
          ),
        );
      },
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    final parsedDate = DateTime.tryParse(appointment.date);
    final dateLabel = parsedDate != null
        ? _capitalize(
            DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(parsedDate),
          )
        : appointment.date;
    final doctorName = appointment.doctor?.name ?? 'Medecin';
    final specialty = appointment.doctor?.specialty ?? '';
    final address = appointment.doctor?.address ?? '';
    final status = _statusMeta(appointment.status);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F6EC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_hospital_rounded,
                  color: Color(0xFF34C759),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctorName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    if (specialty.isNotEmpty)
                      Text(
                        specialty,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: status.bgColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: status.textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow(Icons.event_rounded, dateLabel),
          const SizedBox(height: 6),
          _infoRow(Icons.access_time_rounded, appointment.time),
          if (address.isNotEmpty) ...[
            const SizedBox(height: 6),
            _infoRow(Icons.location_on_rounded, address),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF6B7280)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF374151),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  _AppointmentStatusMeta _statusMeta(String raw) {
    switch (raw.toUpperCase()) {
      case 'CONFIRMED':
        return const _AppointmentStatusMeta(
          label: 'Confirme',
          textColor: Color(0xFF047857),
          bgColor: Color(0xFFD1FAE5),
        );
      case 'COMPLETED':
        return const _AppointmentStatusMeta(
          label: 'Termine',
          textColor: Color(0xFF3730A3),
          bgColor: Color(0xFFE0E7FF),
        );
      case 'CANCELLED':
        return const _AppointmentStatusMeta(
          label: 'Annule',
          textColor: Color(0xFFB42318),
          bgColor: Color(0xFFFEE4E2),
        );
      default:
        return const _AppointmentStatusMeta(
          label: 'En attente',
          textColor: Color(0xFFB45309),
          bgColor: Color(0xFFFEF3C7),
        );
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Widget _buildDoctors() {
    return Consumer<BookingProvider>(
      builder: (context, provider, _) {
        final doctors = provider.doctors;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onSubmitted: (value) {
                  provider.loadDoctors(search: value.trim().isEmpty ? null : value.trim());
                },
                decoration: InputDecoration(
                  hintText: context.l10n.searchDoctor,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      provider.loadDoctors(
                        search: _searchController.text.trim().isEmpty
                            ? null
                            : _searchController.text.trim(),
                      );
                    },
                  ),
                ),
              ),
            ),
            Expanded(
              child: provider.isLoadingDoctors
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF34C759)),
                    )
                  : (provider.error != null && doctors.isEmpty)
                      ? _buildDoctorsError(
                          provider.error!,
                          onRetry: () => provider.loadDoctors(
                            search: _searchController.text.trim().isEmpty
                                ? null
                                : _searchController.text.trim(),
                          ),
                        )
                  : doctors.isEmpty
                      ? Center(child: Text(context.l10n.noDoctorsAvailable))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: doctors.length,
                          itemBuilder: (context, index) {
                            final doctor = doctors[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundColor: const Color(0xFFE8F5E9),
                                    child: Text(
                                      doctor.name.isNotEmpty
                                          ? doctor.name[0].toUpperCase()
                                          : 'M',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF34C759),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          doctor.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          doctor.specialty,
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${doctor.city} • ${doctor.address}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      context.push(
                                        '/calendar/booking',
                                        extra: {
                                          'doctorId': doctor.userId.isNotEmpty
                                              ? doctor.userId
                                              : doctor.id,
                                          'doctorName': doctor.name,
                                          'specialty': doctor.specialty,
                                          'address': doctor.address,
                                          'imageUrl': '',
                                        },
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.calendar_month_rounded,
                                      color: Color(0xFF34C759),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDoctorsError(String message, {required VoidCallback onRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFEF4444),
              size: 30,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFFB42318),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(context.l10n.retry),
            ),
          ],
        ),
      ),
    );
  }

}

class _AppointmentStatusMeta {
  const _AppointmentStatusMeta({
    required this.label,
    required this.textColor,
    required this.bgColor,
  });

  final String label;
  final Color textColor;
  final Color bgColor;
}
