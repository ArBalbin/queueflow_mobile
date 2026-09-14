import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class QBadge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const QBadge({
    super.key,
    required this.label,
    required this.bg,
    required this.fg,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg),
    ),
  );
}

class StatTile extends StatelessWidget {
  final String value;
  final String label;
  final Color? valueColor;
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    this.valueColor,
  });
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.dark,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
          ),
        ],
      ),
    ),
  );
}

class QueueListItem extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;
  final Color circBg;
  final Color circFg;
  final Color? titleColor;
  final Widget? badge;
  final bool highlighted;
  final Color? highlightColor;
  const QueueListItem({
    super.key,
    required this.number,
    required this.title,
    required this.subtitle,
    required this.circBg,
    required this.circFg,
    this.titleColor,
    this.badge,
    this.highlighted = false,
    this.highlightColor,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
    decoration: BoxDecoration(
      color: AppColors.white,
      border: Border.all(
        color: highlighted
            ? (highlightColor ?? AppColors.green)
            : AppColors.border,
        width: highlighted ? 1.5 : 1,
      ),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(color: circBg, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(
            number,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: circFg,
            ),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: titleColor ?? AppColors.dark,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        ?badge,
      ],
    ),
  );
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color? bg;
  final Color? fg;
  final bool outlined;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;
  final double? fontSize;
  const PrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.bg,
    this.fg,
    this.outlined = false,
    this.borderColor,
    this.padding,
    this.fontSize,
  });
  @override
  Widget build(BuildContext context) {
    final bgColor = bg ?? (outlined ? Colors.transparent : AppColors.dark);
    final fgColor = fg ?? (outlined ? AppColors.dark : AppColors.white);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: padding ?? const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: bgColor,
          border: outlined
              ? Border.all(color: borderColor ?? AppColors.dark, width: 1.5)
              : null,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: fontSize ?? 12,
            fontWeight: FontWeight.w600,
            color: fgColor,
          ),
        ),
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: AppColors.textMuted,
      letterSpacing: 0.3,
    ),
  );
}

class AlertBanner extends StatelessWidget {
  final String text;
  final Color bg;
  final Color borderColor;
  final Color dotColor;
  final Color textColor;
  const AlertBanner({
    super.key,
    required this.text,
    required this.bg,
    required this.borderColor,
    required this.dotColor,
    required this.textColor,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: bg,
      border: Border.all(color: borderColor),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 10, color: textColor, height: 1.4),
          ),
        ),
      ],
    ),
  );
}

class QueueNumberCard extends StatelessWidget {
  final String number;
  final String label;
  final Color bg;
  final Color numColor;
  final Widget badge;
  const QueueNumberCard({
    super.key,
    required this.number,
    required this.label,
    required this.bg,
    required this.numColor,
    required this.badge,
  });
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 11),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(13),
    ),
    child: Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color.fromARGB(128, 240, 238, 238)),
        ),
        const SizedBox(height: 3),
        Text(
          number,
          style: TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.w700,
            color: numColor,
            height: 1,
          ),
        ),
        const SizedBox(height: 6),
        badge,
      ],
    ),
  );
}

class QAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Color? bgColor;
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget>? actions;

  const QAppBar({
    super.key,
    this.title,
    this.bgColor,
    this.showBack = false,
    this.onBack,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(
    backgroundColor: bgColor ?? AppColors.green,
    automaticallyImplyLeading: false,
    leading: showBack
        ? IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            color: AppColors.white,
            onPressed: onBack ?? () => Navigator.of(context).pop(),
          )
        : null,
    actions: actions,
    titleSpacing: showBack ? 0 : 20,
    title: title != null
        ? Text(
            title!,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          )
        : Image.asset('assets/img/Logo.png', height: 24, fit: BoxFit.contain),
  );
}

class QBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const QBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const labels = ['My Queue', 'History', 'Profile', 'Help'];
    final systemInset = MediaQuery.viewPaddingOf(context).bottom;
    
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.fromLTRB(16, 0, 16, systemInset + 12),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.green,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          children: List.generate(4, (i) {
            final active = i == currentIndex;
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: active ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CustomPaint(
                          painter: _NavIconPainter(index: i, active: active),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        labels[i],
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: active ? AppColors.green : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavIconPainter extends CustomPainter {
  final int index;
  final bool active;
  _NavIconPainter({required this.index, required this.active});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 22;
    final activeCol = AppColors.green;
    final inactiveCol = Colors.white;
    final inactiveFill = Colors.white.withValues(alpha: 0.25);
    final activeFill = AppColors.green.withValues(alpha: 0.2);
    final color = active ? activeCol : inactiveCol;
    final stroke = Paint()
      ..color = color
      ..strokeWidth = 1.8 * s
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    switch (index) {
      case 0:
        final r = Radius.circular(2 * s);
        canvas.drawRRect(
          RRect.fromLTRBR(3 * s, 3 * s, 10 * s, 10 * s, r),
          Paint()..color = active ? activeCol : inactiveFill,
        );
        canvas.drawRRect(
          RRect.fromLTRBR(12 * s, 3 * s, 19 * s, 10 * s, r),
          Paint()..color = active ? activeFill : inactiveFill,
        );
        canvas.drawRRect(
          RRect.fromLTRBR(3 * s, 12 * s, 10 * s, 19 * s, r),
          Paint()..color = active ? activeFill : inactiveFill,
        );
        canvas.drawRRect(
          RRect.fromLTRBR(12 * s, 12 * s, 19 * s, 19 * s, r),
          Paint()..color = active ? activeFill : inactiveFill,
        );
        break;
      case 1:
        canvas.drawLine(Offset(4 * s, 6 * s), Offset(18 * s, 6 * s), stroke);
        canvas.drawLine(Offset(4 * s, 11 * s), Offset(18 * s, 11 * s), stroke);
        canvas.drawLine(Offset(4 * s, 16 * s), Offset(12 * s, 16 * s), stroke);
        break;
      case 2:
        canvas.drawCircle(Offset(11 * s, 8 * s), 3.5 * s, stroke);
        final path = Path()
          ..moveTo(4 * s, 19 * s)
          ..cubicTo(4 * s, 15.13 * s, 7.13 * s, 12 * s, 11 * s, 12 * s)
          ..cubicTo(14.87 * s, 12 * s, 18 * s, 15.13 * s, 18 * s, 19 * s);
        canvas.drawPath(path, stroke);
        break;
      case 3:
        canvas.drawCircle(Offset(11 * s, 11 * s), 3.5 * s, stroke);
        for (final pts in [
          [11, 3, 11, 5],
          [11, 17, 11, 19],
          [3, 11, 5, 11],
          [17, 11, 19, 11],
          [5.22, 5.22, 6.64, 6.64],
          [15.36, 15.36, 16.78, 16.78],
          [5.22, 16.78, 6.64, 15.36],
          [15.36, 6.64, 16.78, 5.22],
        ]) {
          canvas.drawLine(
            Offset(pts[0] * s, pts[1] * s),
            Offset(pts[2] * s, pts[3] * s),
            stroke,
          );
        }
        break;
    }
  }

  @override
  bool shouldRepaint(_NavIconPainter old) =>
      old.active != active || old.index != index;
}