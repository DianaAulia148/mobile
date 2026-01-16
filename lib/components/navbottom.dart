import 'package:flutter/material.dart';
import 'package:custom_line_indicator_bottom_navbar/custom_line_indicator_bottom_navbar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PurplePalette {
  static const Color lavender = Color(0xFFE39FF6);
  static const Color lilac = Color(0xFFBD93D3);
  static const Color amethyst = Color(0xFF9966CC);
  static const Color wildberry = Color(0xFF8B2991);
  static const Color iris = Color(0xFF9866C5);
  static const Color orchid = Color(0xFFAF69EE);
  static const Color periwinkle = Color(0xFFBD93D3);
  static const Color eggplant = Color(0xFF380385);
  static const Color violet = Color(0xFF710193);
  static const Color purple = Color(0xFFA32CC4);
  static const Color mauve = Color(0xFF7A4A88);
  static const Color heather = Color(0xFF9B7CB8);

  static const Color background = Color(0xFF1F0A2D);
  static const Color cardBackground = Color(0xFF2C123A);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFC7B8D6);
  static const Color accent = purple;
  static const Color success = Color(0xFF4CAF50);
  static const Color info = Color(0xFF2196F3);
}

class CustomBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            PurplePalette.orchid.withOpacity(0.1),
            PurplePalette.cardBackground,
          ],
        ),
        border: Border(
          top: BorderSide(
            color: PurplePalette.orchid.withOpacity(0.3),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: PurplePalette.orchid.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        child: CustomLineIndicatorBottomNavbar(
          selectedColor: Colors.white,
          unSelectedColor: PurplePalette.textSecondary,
          backgroundColor: Colors.transparent,
          currentIndex: widget.currentIndex,
          onTap: widget.onTap,
          enableLineIndicator: true,
          lineIndicatorWidth: 3,
          indicatorType: IndicatorType.Top,
          customBottomBarItems: [
            CustomBottomBarItems(
              label: 'Home',
              icon: FontAwesomeIcons.house,
            ),
            CustomBottomBarItems(
              label: 'Jadwal',
              icon: FontAwesomeIcons.calendarDays,
            ),
            CustomBottomBarItems(
              label: 'Makanan',
              icon: FontAwesomeIcons.utensils,
            ),
            CustomBottomBarItems(
              label: 'Workout',
              icon: FontAwesomeIcons.dumbbell,
            ),
            CustomBottomBarItems(
              label: 'Profile',
              icon: FontAwesomeIcons.user,
            ),
          ],
        ),
      ),
    );
  }
}
