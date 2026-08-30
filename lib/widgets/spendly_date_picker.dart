import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_colors.dart';
import 'date_helper.dart';

enum _PickerViewMode { day, month, year }

class SpendlyDatePicker extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const SpendlyDatePicker({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  static Future<DateTime?> show(
    BuildContext context, {
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    final DateTime effectiveFirstDate = firstDate ?? DateHelper.minDate;
    final DateTime effectiveLastDate = lastDate ?? DateHelper.nextMonthEnd();
    DateTime effectiveInitialDate = initialDate ?? DateHelper.today;

    if (effectiveInitialDate.isBefore(effectiveFirstDate)) {
      effectiveInitialDate = effectiveFirstDate;
    } else if (effectiveInitialDate.isAfter(effectiveLastDate)) {
      effectiveInitialDate = effectiveLastDate;
    }

    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SpendlyDatePicker(
        initialDate: effectiveInitialDate,
        firstDate: effectiveFirstDate,
        lastDate: effectiveLastDate,
      ),
    );
  }

  @override
  State<SpendlyDatePicker> createState() => _SpendlyDatePickerState();
}

class _SpendlyDatePickerState extends State<SpendlyDatePicker> {
  late DateTime _selectedDate;
  late int _displayYear;
  late int _displayMonth;
  _PickerViewMode _viewMode = _PickerViewMode.day;

  static const List<String> _monthNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  static const List<String> _shortMonthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  static const List<String> _dayNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _displayYear = _selectedDate.year;
    _displayMonth = _selectedDate.month;
  }

  bool _isMonthAvailable(int year, int month) {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

    if (endOfMonth.isBefore(widget.firstDate)) return false;
    if (startOfMonth.isAfter(widget.lastDate)) return false;
    return true;
  }

  bool _isDayAvailable(DateTime date) {
    final clean = DateTime(date.year, date.month, date.day);
    final first = DateTime(widget.firstDate.year, widget.firstDate.month, widget.firstDate.day);
    final last = DateTime(widget.lastDate.year, widget.lastDate.month, widget.lastDate.day);

    return !clean.isBefore(first) && !clean.isAfter(last);
  }

  void _prevMonth() {
    setState(() {
      if (_displayMonth == 1) {
        if (_displayYear > widget.firstDate.year) {
          _displayYear--;
          _displayMonth = 12;
        }
      } else {
        _displayMonth--;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      if (_displayMonth == 12) {
        if (_displayYear < widget.lastDate.year) {
          _displayYear++;
          _displayMonth = 1;
        }
      } else {
        _displayMonth++;
      }
    });
  }

  List<int> _availableYears() {
    final start = widget.firstDate.year;
    final end = widget.lastDate.year;
    return List<int>.generate(end - start + 1, (i) => start + i);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = Theme.of(context).cardColor;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color secondaryTextColor = isDark ? Colors.white60 : Colors.grey.shade600;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Preview
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const FaIcon(FontAwesomeIcons.calendarDay, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TANGGAL TERPILIH',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryGreen, letterSpacing: 1.1),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('EEEE, dd MMMM yyyy', 'id').format(_selectedDate),
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Quick Shortcut Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildQuickChip('Hari Ini', DateHelper.today, textColor, isDark),
                  _buildQuickChip('Kemarin', DateHelper.today.subtract(const Duration(days: 1)), textColor, isDark),
                  _buildQuickChip('2 Hari Lalu', DateHelper.today.subtract(const Duration(days: 2)), textColor, isDark),
                  _buildQuickChip(
                    'Awal Bulan Depan',
                    DateTime(DateHelper.today.year, DateHelper.today.month + 1, 1),
                    textColor,
                    isDark,
                    isFuture: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Month & Year Selector Navigation Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Month Selector Button
                InkWell(
                  onTap: () {
                    setState(() {
                      _viewMode = _viewMode == _PickerViewMode.month ? _PickerViewMode.day : _PickerViewMode.month;
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _viewMode == _PickerViewMode.month
                          ? AppColors.primaryGreen
                          : (isDark ? Colors.white10 : const Color(0xFFF1FAF5)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _viewMode == _PickerViewMode.month ? AppColors.primaryGreen : Colors.transparent),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _monthNames[_displayMonth - 1],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _viewMode == _PickerViewMode.month ? Colors.white : textColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _viewMode == _PickerViewMode.month ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          size: 18,
                          color: _viewMode == _PickerViewMode.month ? Colors.white : AppColors.primaryGreen,
                        ),
                      ],
                    ),
                  ),
                ),

                // Year Selector Button
                InkWell(
                  onTap: () {
                    setState(() {
                      _viewMode = _viewMode == _PickerViewMode.year ? _PickerViewMode.day : _PickerViewMode.year;
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _viewMode == _PickerViewMode.year
                          ? AppColors.primaryGreen
                          : (isDark ? Colors.white10 : const Color(0xFFF1FAF5)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _viewMode == _PickerViewMode.year ? AppColors.primaryGreen : Colors.transparent),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$_displayYear',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _viewMode == _PickerViewMode.year ? Colors.white : textColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _viewMode == _PickerViewMode.year ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          size: 18,
                          color: _viewMode == _PickerViewMode.year ? Colors.white : AppColors.primaryGreen,
                        ),
                      ],
                    ),
                  ),
                ),

                // Next & Prev Month Arrows
                if (_viewMode == _PickerViewMode.day)
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded),
                        color: textColor,
                        onPressed: _displayYear == widget.firstDate.year && _displayMonth <= widget.firstDate.month ? null : _prevMonth,
                        visualDensity: VisualDensity.compact,
                        splashRadius: 20,
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded),
                        color: textColor,
                        onPressed: _displayYear == widget.lastDate.year && _displayMonth >= widget.lastDate.month ? null : _nextMonth,
                        visualDensity: VisualDensity.compact,
                        splashRadius: 20,
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Content Area based on Mode
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _buildCurrentView(textColor, secondaryTextColor, isDark),
            ),
            const SizedBox(height: 20),

            // Bottom Confirm Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, null),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Batal', style: TextStyle(color: secondaryTextColor, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, _selectedDate),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text('Pilih Tanggal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickChip(String label, DateTime targetDate, Color textColor, bool isDark, {bool isFuture = false}) {
    if (!_isDayAvailable(targetDate)) return const SizedBox.shrink();

    final bool isSelected = _selectedDate.year == targetDate.year &&
        _selectedDate.month == targetDate.month &&
        _selectedDate.day == targetDate.day;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedDate = targetDate;
            _displayYear = targetDate.year;
            _displayMonth = targetDate.month;
            _viewMode = _PickerViewMode.day;
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryGreen
                : (isFuture
                    ? (isDark ? Colors.blue.withValues(alpha: 0.15) : const Color(0xFFE3F2FD))
                    : (isDark ? Colors.white10 : Colors.grey.shade100)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryGreen
                  : (isFuture ? const Color(0xFF2196F3).withValues(alpha: 0.3) : (isDark ? Colors.white12 : Colors.grey.shade300)),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : (isFuture ? const Color(0xFF2196F3) : textColor),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentView(Color textColor, Color secondaryTextColor, bool isDark) {
    switch (_viewMode) {
      case _PickerViewMode.month:
        return _buildMonthGridView(textColor, isDark);
      case _PickerViewMode.year:
        return _buildYearGridView(textColor, isDark);
      case _PickerViewMode.day:
        return _buildDayGridView(textColor, secondaryTextColor, isDark);
    }
  }

  Widget _buildMonthGridView(Color textColor, bool isDark) {
    return Container(
      key: const ValueKey('month_grid'),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 1.85,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: 12,
        itemBuilder: (context, index) {
          final monthNum = index + 1;
          final bool isAvailable = _isMonthAvailable(_displayYear, monthNum);
          final bool isSelected = _selectedDate.year == _displayYear && _selectedDate.month == monthNum;
          final bool isCurrentDisplay = _displayMonth == monthNum;

          return InkWell(
            onTap: isAvailable
                ? () {
                    setState(() {
                      _displayMonth = monthNum;
                      // Keep selected day if valid, otherwise adjust to max days in new month
                      final maxDays = DateTime(_displayYear, monthNum + 1, 0).day;
                      final targetDay = _selectedDate.day > maxDays ? maxDays : _selectedDate.day;
                      final candidate = DateTime(_displayYear, monthNum, targetDay);
                      if (_isDayAvailable(candidate)) {
                        _selectedDate = candidate;
                      }
                      _viewMode = _PickerViewMode.day;
                    });
                  }
                : null,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryGreen
                    : (isCurrentDisplay ? AppColors.primaryGreen.withValues(alpha: isDark ? 0.2 : 0.1) : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100)),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryGreen
                      : (isCurrentDisplay ? AppColors.primaryGreen.withValues(alpha: 0.4) : Colors.transparent),
                ),
              ),
              child: Text(
                _shortMonthNames[index],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: (isSelected || isCurrentDisplay) ? FontWeight.bold : FontWeight.normal,
                  color: !isAvailable
                      ? (isDark ? Colors.white24 : Colors.grey.shade400)
                      : (isSelected ? Colors.white : (isCurrentDisplay ? AppColors.primaryGreen : textColor)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildYearGridView(Color textColor, bool isDark) {
    final years = _availableYears();
    final selectedIndex = years.indexOf(_displayYear);
    final row = selectedIndex >= 0 ? (selectedIndex / 3).floor() : 0;
    final initialOffset = (row * 50.0).clamp(0.0, (years.length > 9 ? (years.length / 3 * 50.0) : 0.0));
    final controller = ScrollController(initialScrollOffset: initialOffset);

    return Container(
      key: const ValueKey('year_grid'),
      height: 180,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RawScrollbar(
        controller: controller,
        thumbVisibility: years.length > 9,
        radius: const Radius.circular(8),
        thickness: 3.5,
        thumbColor: isDark ? Colors.white30 : Colors.grey.shade400,
        child: GridView.builder(
          controller: controller,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(right: years.length > 9 ? 6 : 0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2.1,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: years.length,
          itemBuilder: (context, index) {
            final year = years[index];
            final bool isSelected = _selectedDate.year == year;
            final bool isCurrentDisplay = _displayYear == year;

            return InkWell(
              onTap: () {
                setState(() {
                  _displayYear = year;
                  if (!_isMonthAvailable(year, _displayMonth)) {
                    _displayMonth = widget.lastDate.year == year ? widget.lastDate.month : 1;
                  }
                  final maxDays = DateTime(year, _displayMonth + 1, 0).day;
                  final targetDay = _selectedDate.day > maxDays ? maxDays : _selectedDate.day;
                  final candidate = DateTime(year, _displayMonth, targetDay);
                  if (_isDayAvailable(candidate)) {
                    _selectedDate = candidate;
                  }
                  // Switch directly to month view so user can choose month next!
                  _viewMode = _PickerViewMode.month;
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryGreen
                      : (isCurrentDisplay ? AppColors.primaryGreen.withValues(alpha: isDark ? 0.2 : 0.1) : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100)),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryGreen
                        : (isCurrentDisplay ? AppColors.primaryGreen.withValues(alpha: 0.4) : Colors.transparent),
                  ),
                ),
                child: Text(
                  '$year',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: (isSelected || isCurrentDisplay) ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : (isCurrentDisplay ? AppColors.primaryGreen : textColor),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDayGridView(Color textColor, Color secondaryTextColor, bool isDark) {
    final firstDayOfMonth = DateTime(_displayYear, _displayMonth, 1);
    final daysInMonth = DateTime(_displayYear, _displayMonth + 1, 0).day;
    // Monday = 1, Sunday = 7
    final weekdayOffset = firstDayOfMonth.weekday - 1;
    final totalCells = weekdayOffset + daysInMonth;
    final totalRows = (totalCells / 7).ceil();

    return Column(
      key: const ValueKey('day_grid'),
      children: [
        // Day of Week Headers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _dayNames.map((d) {
            final isWeekend = d == 'Min';
            return SizedBox(
              width: 38,
              child: Center(
                child: Text(
                  d,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isWeekend ? Colors.redAccent : secondaryTextColor,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),

        // Days Grid
        SizedBox(
          height: (totalRows * 40.0).clamp(160.0, 240.0),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: totalRows * 7,
            itemBuilder: (context, index) {
              final dayIndex = index - weekdayOffset + 1;
              if (dayIndex < 1 || dayIndex > daysInMonth) {
                return const SizedBox.shrink();
              }

              final cellDate = DateTime(_displayYear, _displayMonth, dayIndex);
              final bool isAvailable = _isDayAvailable(cellDate);
              final bool isSelected = _selectedDate.year == cellDate.year &&
                  _selectedDate.month == cellDate.month &&
                  _selectedDate.day == cellDate.day;
              final bool isToday = DateHelper.today.year == cellDate.year &&
                  DateHelper.today.month == cellDate.month &&
                  DateHelper.today.day == cellDate.day;

              return InkWell(
                onTap: isAvailable
                    ? () {
                        setState(() {
                          _selectedDate = cellDate;
                        });
                      }
                    : null,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryGreen : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isToday && !isSelected
                        ? Border.all(color: AppColors.primaryGreen, width: 1.5)
                        : null,
                  ),
                  child: Text(
                    '$dayIndex',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: (isSelected || isToday) ? FontWeight.bold : FontWeight.normal,
                      color: !isAvailable
                          ? (isDark ? Colors.white24 : Colors.grey.shade300)
                          : (isSelected ? Colors.white : (isToday ? AppColors.primaryGreen : textColor)),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}