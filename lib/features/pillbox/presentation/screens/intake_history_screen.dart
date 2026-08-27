import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:corevia_mobile/l10n/app_localizations.dart';
import '../providers/pillbox_provider.dart';
import '../widgets/intake_card.dart';

class IntakeHistoryScreen extends StatefulWidget {
  const IntakeHistoryScreen({super.key});

  @override
  State<IntakeHistoryScreen> createState() => _IntakeHistoryScreenState();
}

class _IntakeHistoryScreenState extends State<IntakeHistoryScreen> {
  static const _green = Color(0xFF34C759);
  static const _dark = Color(0xFF1D1D1F);
  static const _grey = Color(0xFF6B7280);
  static const _bg = Color(0xFFF8F9FB);

  late DateTime _currentMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month, 1);
    _selectedDate = now;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PillboxProvider>();
      provider.selectHistoryDate(_selectedDate);
      provider.loadMonthIntakes(_currentMonth);
    });
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
    context.read<PillboxProvider>().loadMonthIntakes(_currentMonth);
  }

  void _nextMonth() {
    final now = DateTime.now();
    final next = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    if (next.isAfter(DateTime(now.year, now.month + 1, 0))) return;
    setState(() {
      _currentMonth = next;
    });
    context.read<PillboxProvider>().loadMonthIntakes(_currentMonth);
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    context.read<PillboxProvider>().selectHistoryDate(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: _dark),
              onPressed: () => context.pop(),
            ),
            title: Text(
              context.l10n.history,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _dark,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _buildMonthSelector(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _buildCalendarGrid(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: _buildLegend(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: _buildSelectedDateHeader(),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: _buildSelectedDateIntakes(),
          ),
        ],
      ),
    );
  }

  // ── Month selector ──────────────────────────────────────────────────────

  Widget _buildMonthSelector() {
    final now = DateTime.now();
    final isCurrentMonth = _currentMonth.year == now.year &&
        _currentMonth.month == now.month;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: _previousMonth,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.chevron_left_rounded,
                  color: _dark, size: 24),
            ),
          ),
          Text(
            _monthName(_currentMonth.month) +
                (_currentMonth.year != now.year
                    ? ' ${_currentMonth.year}'
                    : ''),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _dark,
            ),
          ),
          GestureDetector(
            onTap: isCurrentMonth ? null : _nextMonth,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.chevron_right_rounded,
                  color: isCurrentMonth ? Colors.grey.shade300 : _dark,
                  size: 24),
            ),
          ),
        ],
      ),
    );
  }

  // ── Calendar grid ───────────────────────────────────────────────────────

  Widget _buildCalendarGrid() {
    return Consumer<PillboxProvider>(
      builder: (context, provider, _) {
        final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
        final daysInMonth =
            DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
        // Monday = 1, we want Monday as first column
        final startWeekday = firstDay.weekday; // 1=Mon ... 7=Sun

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        return Container(
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
          child: Column(
            children: [
              // Weekday headers
              Row(
                children: ['L', 'M', 'M', 'J', 'V', 'S', 'D']
                    .map(
                      (d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 10),
              // Day cells
              ..._buildWeeks(
                  firstDay, daysInMonth, startWeekday, today, provider),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildWeeks(DateTime firstDay, int daysInMonth,
      int startWeekday, DateTime today, PillboxProvider provider) {
    final weeks = <Widget>[];
    int dayNumber = 1;
    int column = startWeekday - 1; // 0-indexed from Monday

    while (dayNumber <= daysInMonth) {
      final cells = <Widget>[];
      for (int i = 0; i < 7; i++) {
        if ((weeks.isEmpty && i < column) || dayNumber > daysInMonth) {
          cells.add(const Expanded(child: SizedBox(height: 44)));
        } else {
          final day = dayNumber;
          final date = DateTime(firstDay.year, firstDay.month, day);
          final isFuture = date.isAfter(today);
          final isSelected = _selectedDate.year == date.year &&
              _selectedDate.month == date.month &&
              _selectedDate.day == date.day;
          final isToday = date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;

          final compliance = provider.getComplianceForDate(date);
          final status = isFuture ? null : _dayStatus(compliance);

          cells.add(
            Expanded(
              child: GestureDetector(
                onTap: isFuture ? null : () => _selectDate(date),
                child: Container(
                  height: 44,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _green
                        : isToday
                            ? _green.withValues(alpha: 0.1)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              isToday || isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : isFuture
                                  ? Colors.grey.shade300
                                  : _dark,
                        ),
                      ),
                      if (status != null)
                        Positioned(
                          bottom: 4,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _statusColor(status, isSelected),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
          dayNumber++;
        }
      }
      weeks.add(Row(children: cells));
      if (weeks.length > 1) column = 0; // reset after first week
    }
    return weeks;
  }

  _DayStatus? _dayStatus(bool? compliance) {
    if (compliance == null) return null;
    if (compliance) return _DayStatus.allTaken;
    return _DayStatus.partial;
  }

  Color _statusColor(_DayStatus status, bool isSelected) {
    switch (status) {
      case _DayStatus.allTaken:
        return isSelected ? Colors.white : _green;
      case _DayStatus.partial:
        return isSelected ? Colors.white : const Color(0xFFFF9500);
    }
  }

  // ── Legend ───────────────────────────────────────────────────────────────

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendDot(_green, 'Tout pris'),
        const SizedBox(width: 20),
        _legendDot(const Color(0xFFFF9500), 'Incomplet'),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: _grey,
          ),
        ),
      ],
    );
  }

  // ── Selected date header ────────────────────────────────────────────────

  Widget _buildSelectedDateHeader() {
    return Consumer<PillboxProvider>(
      builder: (context, provider, _) {
        final cached = provider.getIntakesForCachedDate(_selectedDate);
        final intakes = cached?.intakes ?? [];
        final takenCount =
            intakes.where((i) => i.status.toUpperCase() == 'TAKEN').length;
        final total = intakes.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatSelectedDate(context),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _dark,
                  ),
                ),
                if (total > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: takenCount == total
                          ? const Color(0xFFE8FFF0)
                          : const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$takenCount/$total',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: takenCount == total
                            ? _green
                            : const Color(0xFFFF9500),
                      ),
                    ),
                  ),
              ],
            ),
            if (total > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: total > 0 ? takenCount / total : 0,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE5E7EB),
                    color: takenCount == total
                        ? _green
                        : const Color(0xFF007AFF),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // ── Selected date intakes list ──────────────────────────────────────────

  Widget _buildSelectedDateIntakes() {
    return Consumer<PillboxProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingHistory) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: CircularProgressIndicator(color: _green),
              ),
            ),
          );
        }

        final cached = provider.getIntakesForCachedDate(_selectedDate);
        final intakes = cached?.intakes ?? [];

        if (intakes.isEmpty) {
          return SliverToBoxAdapter(child: _buildEmptyDay());
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => IntakeCard(intake: intakes[index]),
            childCount: intakes.length,
          ),
        );
      },
    );
  }

  Widget _buildEmptyDay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
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
          const Icon(Icons.event_available_rounded,
              size: 40, color: _green),
          const SizedBox(height: 10),
          Text(
            context.l10n.noIntakesToday,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _dark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.noMedicationsScheduled,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  String _formatSelectedDate(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sel = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (sel == today) return context.l10n.today;
    if (sel == yesterday) return context.l10n.yesterday;

    final dayNames = [
      '', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'
    ];
    return '${dayNames[_selectedDate.weekday]} ${_selectedDate.day} ${_monthName(_selectedDate.month)}';
  }

  String _monthName(int month) {
    const months = [
      '', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
    ];
    return months[month];
  }
}

enum _DayStatus { allTaken, partial }
