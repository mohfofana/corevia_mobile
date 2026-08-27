import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:corevia_mobile/l10n/app_localizations.dart';

import '../../../../networking/api_service.dart';
import '../../../../networking/routes/user_routes.dart';
import '../../../../widgets/initials_avatar.dart';
import '../../../../widgets/navigation_bar.dart';
import '../../../ai_chat/presentation/ai_chat_modal.dart';
import '../../../pillbox/domain/entities/intake.dart';
import '../../../pillbox/presentation/providers/pillbox_provider.dart';
import '../../../pillbox/presentation/widgets/intake_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  DateTime selectedDate = DateTime.now();
  Map<String, dynamic>? _user;

  String get _name => _user?['name'] as String? ?? '';
  String? get _imageUrl => _user?['image'] as String?;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUser();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<PillboxProvider>();
      await provider.loadTodayIntakes();
      await provider.loadMedications();
      _loadWeekIntakes(provider);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<PillboxProvider>().loadTodayIntakes();
    }
  }

  Future<void> _loadUser() async {
    try {
      final res = await ApiService.authGet(UserRoutes.me());
      if (!mounted) return;
      setState(() {
        _user = res['user'] as Map<String, dynamic>?;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const BottomNavBar(currentLocation: '/home'),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton(
          onPressed: () => showAiChatModal(context),
          backgroundColor: const Color(0xFF34C759),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.smart_toy_rounded, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopCard(),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWeeklyCalendar(),
                    const SizedBox(height: 30),
                    _buildTodayIntakesSection(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopCard() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => context.push('/account'),
                child: InitialsAvatar(
                  name: _name,
                  imageUrl: _imageUrl,
                  size: 60,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _name.isNotEmpty
                          ? context.l10n.helloUser(_name)
                          : context.l10n.hello,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D1D1F),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F2C1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, size: 16, color: Color(0xFFFFBE0A)),
                          SizedBox(width: 4),
                          Text(
                            context.l10n.proMember,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFFFBE0A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => showAiChatModal(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F7),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 12),
                  Text(
                    context.l10n.startChatDocAi,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _loadWeekIntakes(PillboxProvider provider) {
    final now = DateTime.now();
    provider.loadMonthIntakes(DateTime(now.year, now.month, 1));
  }

  Widget _buildWeeklyCalendar() {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    final week = List.generate(7, (index) => start.add(Duration(days: index)));

    return Consumer<PillboxProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
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
            children: week
                .map(
                  (date) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: _buildDayCircle(date, provider),
                    ),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  Widget _buildDayCircle(DateTime date, PillboxProvider provider) {
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final isFuture = date.isAfter(DateTime(now.year, now.month, now.day));
    final label = _weekdayLetter(date.weekday);

    // Get status for this specific day
    _DayStatus? status;
    if (!isFuture || isToday) {
      if (isToday) {
        switch (provider.todayBadgeStatus) {
          case 'allTaken':
            status = _DayStatus.allTaken;
          case 'partial':
            status = _DayStatus.partial;
          case 'hasSkipped':
            status = _DayStatus.hasSkipped;
        }
      } else {
        // Compliance cache for past days.
        // null means no data loaded or no intakes that day — show no badge.
        final compliance = provider.getComplianceForDate(date);
        if (compliance == true) {
          status = _DayStatus.allTaken;
        } else if (compliance == false) {
          status = _DayStatus.hasSkipped;
        } else {
          status = null;
        }
      }
    }

    // Today with no medications scheduled → gray styling, no badge.
    final isTodayEmpty =
        isToday && provider.intakes.isEmpty && !provider.isLoading;
    if (isTodayEmpty) status = null;

    final Color borderColor;
    final Color textColor;
    final Color bgColor;
    if (isTodayEmpty) {
      borderColor = const Color(0xFFD1D5DB);
      textColor = const Color(0xFFB0B7C3);
      bgColor = const Color(0xFFF5F5F7);
    } else if (isToday) {
      borderColor = const Color(0xFF34C759);
      textColor = const Color(0xFF333333);
      bgColor = Colors.white;
    } else {
      borderColor = const Color(0xFFF0F0F0);
      textColor = const Color(0xFF333333);
      bgColor = Colors.white;
    }

    return GestureDetector(
      onTap: () => setState(() => selectedDate = date),
      child: SizedBox(
        width: 40,
        height: 58,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              top: 6,
              child: Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: borderColor,
                    width: isToday ? 1.5 : 1.0,
                  ),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 20,
                      color: textColor,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            // Badge - top right corner, half in / half out
            if (status == null && !isFuture)
              Positioned(
                top: 0,
                right: -2,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFB0B7C3),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.remove_rounded,
                      size: 10, color: Colors.white),
                ),
              )
            else if (status == _DayStatus.allTaken)
              Positioned(
                top: 0,
                right: -2,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF34C759),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.check_rounded,
                      size: 10, color: Colors.white),
                ),
              )
            else if (status == _DayStatus.hasSkipped)
              Positioned(
                top: 0,
                right: -2,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFEF4444),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.close_rounded,
                      size: 10, color: Colors.white),
                ),
              )
            else if (status == _DayStatus.partial)
              Positioned(
                top: 0,
                right: -2,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFF9500),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.remove_rounded,
                      size: 10, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayIntakesSection() {
    return Consumer<PillboxProvider>(
      builder: (context, provider, _) {
        final intakes = provider.intakes;
        final takenCount =
            intakes.where((i) => i.status.toUpperCase() == 'TAKEN').length;
        final total = intakes.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.todayIntakes,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1D1D1F),
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (total > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            context.l10n.todayIntakeProgress(takenCount, total),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: takenCount == total
                                  ? const Color(0xFF34C759)
                                  : Colors.grey.shade500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Wrap(
                  spacing: 0,
                  runSpacing: 0,
                  children: [
                    TextButton.icon(
                      onPressed: () => context.push('/pillbox/history'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      icon: const Icon(Icons.history_rounded, size: 16),
                      label: Text(context.l10n.history),
                    ),
                    const SizedBox(width: 4),
                    TextButton.icon(
                      onPressed: () => context.push('/pillbox'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF34C759),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: Text(context.l10n.viewAll),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (total > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: total > 0 ? takenCount / total : 0,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE5E7EB),
                    color: takenCount == total
                        ? const Color(0xFF34C759)
                        : const Color(0xFF007AFF),
                  ),
                ),
              ),
            if (provider.isLoading && intakes.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF34C759),
                  ),
                ),
              )
            else if (intakes.isEmpty)
              _buildEmptyIntakes()
            else
              Column(
                children: intakes
                    .map(
                      (intake) => IntakeCard(
                        intake: intake,
                        onTaken: () => _markTaken(intake),
                        onSkipped: () => _markSkipped(intake),
                      ),
                    )
                    .toList(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyIntakes() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              size: 40, color: Color(0xFF34C759)),
          const SizedBox(height: 10),
          Text(
            context.l10n.noIntakesToday,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.addMedicationsWithSchedules,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 40,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/pillbox/add'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF34C759),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                context.l10n.addMedication,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markTaken(Intake intake) async {
    await context.read<PillboxProvider>().markIntakeTaken(intake.id);
  }

  Future<void> _markSkipped(Intake intake) async {
    await context.read<PillboxProvider>().markIntakeSkipped(intake.id);
  }

  String _weekdayLetter(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'L';
      case DateTime.tuesday:
        return 'M';
      case DateTime.wednesday:
        return 'M';
      case DateTime.thursday:
        return 'J';
      case DateTime.friday:
        return 'V';
      case DateTime.saturday:
        return 'S';
      case DateTime.sunday:
        return 'D';
      default:
        return '';
    }
  }
}

enum _DayStatus { allTaken, hasSkipped, partial }
