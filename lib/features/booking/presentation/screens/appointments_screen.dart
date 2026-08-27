import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:corevia_mobile/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/appointment.dart';
import '../providers/booking_provider.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR');
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reload();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _reload() {
    return context.read<BookingProvider>().loadMyAppointments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Consumer<BookingProvider>(
          builder: (context, provider, _) {
            final all = provider.appointments;
            final upcoming = all
                .where(
                  (a) =>
                      a.status.toUpperCase() == 'PENDING' ||
                      a.status.toUpperCase() == 'CONFIRMED',
                )
                .toList();
            final past =
                all.where((a) => a.status.toUpperCase() == 'COMPLETED').toList();
            final cancelled =
                all.where((a) => a.status.toUpperCase() == 'CANCELLED').toList();

            return Column(
              children: [
                _buildHeader(
                  isLoading: provider.isLoadingAppointments,
                  onReload: () => _reload(),
                ),
                const SizedBox(height: 14),
                _buildSummary(
                  total: all.length,
                  upcoming: upcoming.length,
                  completed: past.length,
                ),
                const SizedBox(height: 14),
                _buildTabBar(upcoming.length, past.length, cancelled.length),
                const SizedBox(height: 10),
                Expanded(
                  child: provider.isLoadingAppointments && all.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF34C759),
                          ),
                        )
                      : (provider.error != null && all.isEmpty)
                          ? _buildErrorState(provider.error!)
                          : TabBarView(
                              controller: _tabController,
                              children: [
                              _buildAppointmentsList(
                                  appointments: upcoming,
                                  emptyTitle: context.l10n.noUpcomingAppointments,
                                  emptySubtitle: context.l10n.bookFromDoctorsList,
                                ),
                                _buildAppointmentsList(
                                  appointments: past,
                                  emptyTitle: context.l10n.noPastAppointments,
                                  emptySubtitle:
                                      context.l10n.pastConsultationsWillAppearHere,
                                ),
                                _buildAppointmentsList(
                                  appointments: cancelled,
                                  emptyTitle: context.l10n.noCancelledAppointments,
                                  emptySubtitle:
                                      context.l10n.cancelledAppointmentsWillAppearHere,
                                ),
                              ],
                            ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader({
    required bool isLoading,
    required VoidCallback onReload,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _CircleActionButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: _handleBack,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.l10n.myAppointments,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
          ),
          _CircleActionButton(
            icon: isLoading ? Icons.sync_rounded : Icons.refresh_rounded,
            onTap: isLoading ? null : onReload,
          ),
        ],
      ),
    );
  }

  Widget _buildSummary({
    required int total,
    required int upcoming,
    required int completed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              label: context.l10n.total,
              value: total,
              color: const Color(0xFF0EA5E9),
              icon: Icons.calendar_month_rounded,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SummaryCard(
              label: context.l10n.upcoming,
              value: upcoming,
              color: const Color(0xFF34C759),
              icon: Icons.schedule_rounded,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SummaryCard(
              label: context.l10n.completed,
              value: completed,
              color: const Color(0xFF6366F1),
              icon: Icons.check_circle_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(int upcoming, int past, int cancelled) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: TabBar(
          controller: _tabController,
          isScrollable: false,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: const Color(0xFF34C759),
            borderRadius: BorderRadius.circular(10),
          ),
          indicatorPadding: const EdgeInsets.all(3),
          labelPadding: EdgeInsets.zero,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF6B7280),
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
          tabs: [
            Tab(text: '${context.l10n.upcoming} ($upcoming)'),
            Tab(text: '${context.l10n.past} ($past)'),
            Tab(text: '${context.l10n.cancelled} ($cancelled)'),
          ],
        ),
      ),
    );
  }

  void _handleBack() {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      context.pop();
      return;
    }
    context.go('/home');
  }

  Widget _buildAppointmentsList({
    required List<Appointment> appointments,
    required String emptyTitle,
    required String emptySubtitle,
  }) {
    if (appointments.isEmpty) {
      return _buildEmptyState(emptyTitle, emptySubtitle);
    }

    return RefreshIndicator(
      color: const Color(0xFF34C759),
      onRefresh: _reload,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        itemCount: appointments.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _buildAppointmentCard(appointments[index]),
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    final parsedDate = DateTime.tryParse(appointment.date);
    final dateLabel = parsedDate != null
        ? DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(parsedDate)
        : appointment.date;
    final formattedDate = _capitalize(dateLabel);
    final doctorName = appointment.doctor?.name ?? context.l10n.doctor;
    final specialty = appointment.doctor?.specialty ?? '';
    final address = appointment.doctor?.address ?? '';
    final status = _statusMeta(context, appointment.status);

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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(status.icon, size: 13, color: status.textColor),
                    const SizedBox(width: 4),
                    Text(
                      status.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: status.textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.event_rounded,
            text: formattedDate,
          ),
          const SizedBox(height: 6),
          _InfoRow(
            icon: Icons.access_time_rounded,
            text: appointment.time,
          ),
          if (address.isNotEmpty) ...[
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.location_on_rounded,
              text: address,
            ),
          ],
          if ((appointment.reason ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                appointment.reason!.trim(),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF374151),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F6EC),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.event_busy_rounded,
                color: Color(0xFF34C759),
                size: 34,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFEF4444),
              size: 34,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFFB42318),
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(context.l10n.retry),
            ),
          ],
        ),
      ),
    );
  }

  _StatusMeta _statusMeta(BuildContext context, String raw) {
    switch (raw.toUpperCase()) {
      case 'CONFIRMED':
        return _StatusMeta(
          label: context.l10n.confirmed,
          textColor: Color(0xFF047857),
          bgColor: Color(0xFFD1FAE5),
          icon: Icons.verified_rounded,
        );
      case 'COMPLETED':
        return _StatusMeta(
          label: context.l10n.completed,
          textColor: Color(0xFF3730A3),
          bgColor: Color(0xFFE0E7FF),
          icon: Icons.check_circle_rounded,
        );
      case 'CANCELLED':
        return _StatusMeta(
          label: context.l10n.cancelled,
          textColor: Color(0xFFB42318),
          bgColor: Color(0xFFFEE4E2),
          icon: Icons.close_rounded,
        );
      default:
        return _StatusMeta(
          label: context.l10n.pending,
          textColor: Color(0xFFB45309),
          bgColor: Color(0xFFFEF3C7),
          icon: Icons.hourglass_top_rounded,
        );
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

class _CircleActionButton extends StatelessWidget {
  const _CircleActionButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF374151)),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final int value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Color.fromARGB(31, color.red, color.green, color.blue),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value.toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
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
}

class _StatusMeta {
  const _StatusMeta({
    required this.label,
    required this.textColor,
    required this.bgColor,
    required this.icon,
  });

  final String label;
  final Color textColor;
  final Color bgColor;
  final IconData icon;
}
