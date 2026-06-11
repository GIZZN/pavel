import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

class InfoBlock extends StatefulWidget {
  static const Color primaryBlue = Color(0xFF0126FF);
  static const Color primaryBlack = Color(0xFF010101);
  static const Color primaryWhite = Color(0xFFFFFFFF);

  const InfoBlock({super.key});

  @override
  State<InfoBlock> createState() => _InfoBlockState();
}

class _InfoBlockState extends State<InfoBlock> {
  static const Color primaryBlue = Color(0xFF0126FF);
  static const Color primaryBlack = Color(0xFF010101);
  static const Color primaryWhite = Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок секции
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: FadeInLeft(
            duration: const Duration(milliseconds: 800),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: primaryBlue,
                    borderRadius: BorderRadius.all(Radius.circular(2)),
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ПОЛЕЗНАЯ ИНФОРМАЦИЯ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: primaryBlack,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      'Актуальные данные рынка',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0x80010101),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),
        // Инфо блоки
        FadeInUp(
          duration: const Duration(milliseconds: 600),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                // Первая строка - калькулятор ипотеки и средняя цена
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Калькулятор ипотеки
                    Expanded(
                      flex: 3,
                      child: _buildMortgageCard(),
                    ),
                    const SizedBox(width: 12),
                    // Средняя цена и новые объекты
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _buildSmallCard(
                            icon: Icons.payments_rounded,
                            title: '8.5 млн ₽',
                            subtitle: 'средняя цена',
                            color: primaryWhite,
                            textColor: primaryBlack,
                            trend: '+12%',
                          ),
                          const SizedBox(height: 12),
                          _buildSmallCard(
                            icon: Icons.fiber_new_rounded,
                            title: '47',
                            subtitle: 'новых за неделю',
                            color: primaryBlack,
                            textColor: primaryWhite,
                            trend: null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Вторая строка - популярные районы и консультация
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildDistrictCard(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: _buildConsultationCard(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMortgageCard() {
    return Container(
      height: 210,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryBlue, Color(0xFF0145FF)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryWhite.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.calculate_rounded, color: primaryWhite, size: 28),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryWhite.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'от 5.9%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: primaryWhite,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Калькулятор',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: primaryWhite,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'ипотеки',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: primaryWhite,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Рассчитайте платеж онлайн',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: primaryWhite.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color textColor,
    String? trend,
  }) {
    return Container(
      height: 99,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: color == primaryWhite
            ? Border.all(color: primaryBlack.withValues(alpha: 0.1), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: primaryBlack.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: textColor.withValues(alpha: 0.7), size: 24),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C853).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    trend,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF00C853),
                    ),
                  ),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  height: 1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: textColor.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDistrictCard() {
    return Container(
      height: 110,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: primaryBlack.withValues(alpha: 0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_rounded, color: primaryBlack.withValues(alpha: 0.8), size: 24),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'ТОП-3',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Центр, Парк',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: primaryBlack,
                  height: 1.1,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Набережная',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: primaryBlack,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationCard() {
    return Container(
      height: 125,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: primaryBlue.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(Icons.headset_mic_rounded, color: primaryBlue.withValues(alpha: 0.8), size: 28),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Бесплатная консультация',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: primaryBlue,
                  height: 1.1,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Ответим за 5 минут',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xB30126FF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
