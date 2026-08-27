import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:corevia_mobile/l10n/app_localizations.dart';
import '../../domain/entities/patient_medication.dart';
import '../providers/pillbox_provider.dart';
import '../widgets/medication_list_card.dart';

class PillboxScreen extends StatefulWidget {
  const PillboxScreen({super.key});

  @override
  State<PillboxScreen> createState() => _PillboxScreenState();
}

enum _Filter { all, active, inactive }

class _PillboxScreenState extends State<PillboxScreen> {
  _Filter _filter = _Filter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PillboxProvider>().loadMedications();
    });
  }

  List<PatientMedication> _applyFilter(List<PatientMedication> meds) {
    switch (_filter) {
      case _Filter.active:
        return meds.where((m) => m.isActive).toList();
      case _Filter.inactive:
        return meds.where((m) => !m.isActive).toList();
      case _Filter.all:
        return meds;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: Consumer<PillboxProvider>(
        builder: (context, provider, _) {
          final filtered = _applyFilter(provider.medications);
          final activeCount =
              provider.medications.where((m) => m.isActive).length;
          final inactiveCount = provider.medications.length - activeCount;

          return CustomScrollView(
            slivers: [
              // ── App bar ──
              SliverAppBar(
                pinned: true,
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF1D1D1F)),
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
                ),
                title: Text(
                  context.l10n.medicationPlan,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1D1D1F),
                    letterSpacing: -0.5,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.history_rounded,
                        size: 22, color: Color.fromARGB(255, 0, 0, 0)),
                    tooltip: context.l10n.history,
                    onPressed: () => context.push('/pillbox/history'),
                  ),
                ],
                centerTitle: true,
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(
                    height: 1,
                    color: const Color(0xFFF0F0F0),
                  ),
                ),
              ),

              // ── Summary + filters ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    children: [
                      // Summary cards
                      Row(
                        children: [
                          _SummaryCard(
                            label: context.l10n.total,
                            count: provider.medications.length,
                            icon: Icons.medication_rounded,
                            color: const Color(0xFF34C759),
                            bgColor: const Color(0xFFEAF9F0),
                          ),
                          const SizedBox(width: 10),
                          _SummaryCard(
                            label: context.l10n.active,
                            count: activeCount,
                            icon: Icons.check_circle_outline_rounded,
                            color: const Color(0xFF007AFF),
                            bgColor: const Color(0xFFE8F0FE),
                          ),
                          const SizedBox(width: 10),
                          _SummaryCard(
                            label: context.l10n.inactive,
                            count: inactiveCount,
                            icon: Icons.pause_circle_outline_rounded,
                            color: const Color(0xFFFF9500),
                            bgColor: const Color(0xFFFFF3E0),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Filter chips
                      Row(
                        children: [
                          _FilterChip(
                            label: context.l10n.all,
                            selected: _filter == _Filter.all,
                            onTap: () =>
                                setState(() => _filter = _Filter.all),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: context.l10n.active,
                            selected: _filter == _Filter.active,
                            onTap: () =>
                                setState(() => _filter = _Filter.active),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: context.l10n.inactive,
                            selected: _filter == _Filter.inactive,
                            onTap: () =>
                                setState(() => _filter = _Filter.inactive),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              // ── Loading ──
              if (provider.isLoading && provider.medications.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF34C759),
                    ),
                  ),
                )

              // ── Error ──
              else if (provider.error != null && provider.medications.isEmpty)
                SliverFillRemaining(
                  child: _buildErrorState(provider),
                )

              // ── Empty ──
              else if (provider.medications.isEmpty)
                SliverFillRemaining(child: _buildEmptyState())

              // ── Filtered empty ──
              else if (filtered.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.filter_list_off_rounded,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _filter == _Filter.active
                              ? context.l10n.noMedicationsActive
                              : context.l10n.noMedicationsInactive,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )

              // ── Medication list ──
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index < filtered.length) {
                          final med = filtered[index];
                          return MedicationListCard(
                            medication: med,
                            onTap: () => context.push('/pillbox/${med.id}'),
                          );
                        }
                        // Load more button
                        if (provider.hasMore) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4, bottom: 8),
                            child: Center(
                              child: TextButton.icon(
                                onPressed: provider.isLoading
                                    ? null
                                    : provider.loadMoreMedications,
                                icon: provider.isLoading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF34C759),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.expand_more_rounded,
                                        color: Color(0xFF34C759),
                                      ),
                                label: Text(
                                  provider.isLoading
                                      ? context.l10n.loading
                                      : context.l10n.loadMore,
                                  style: const TextStyle(
                                    color: Color(0xFF34C759),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                        return null;
                      },
                      childCount:
                          filtered.length + (provider.hasMore ? 1 : 0),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF34C759),
        elevation: 4,
        onPressed: () => context.push('/pillbox/add'),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          context.l10n.addMedication,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF9F0),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Center(
                child: Text('💊', style: TextStyle(fontSize: 42)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              context.l10n.emptyPillboxTitle,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1D1D1F),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.emptyPillboxSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/pillbox/add'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF34C759),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  context.l10n.addMedication,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(PillboxProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
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
              provider.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D1D1F),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => provider.loadMedications(refresh: true),
              icon: const Icon(Icons.refresh_rounded,
                  color: Color(0xFF34C759)),
              label: Text(
                context.l10n.retry,
                style: TextStyle(
                  color: Color(0xFF34C759),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Summary card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _SummaryCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filter chip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF34C759) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? const Color(0xFF34C759)
                : const Color(0xFFE5E7EB),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF34C759).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }
}
