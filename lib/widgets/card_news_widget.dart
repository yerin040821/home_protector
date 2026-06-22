// lib/widgets/card_news_widget.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class CardNewsWidget extends StatelessWidget {
  const CardNewsWidget({super.key});

  static const List<_CardNewsItem> _newsItems = [
    _CardNewsItem(
      emoji: '🚪',
      title: '반지하 침수 대피 골든타임',
      summary: '물이 문 높이의 1/3 이상 차면 성인 힘으로도 문을 열 수 없습니다. 수위가 복사뼈까지 오면 즉시 대피하세요.',
      badge: '대피',
      badgeColor: AppColors.red,
      steps: [
        '수위가 복사뼈 근처일 때 즉시 대피를 결심하고 현관문을 먼저 열어 둡니다.',
        '구두나 슬리퍼보다는 미끄러짐 방지에 탁월한 운동화를 착용하세요.',
        '정전 상황에 대비해 스마트폰 플래시나 손전등을 미리 확보합니다.',
        '외부 계단으로 탈출할 때 물이 흐른다면 난간을 꽉 잡고 신속히 대피합니다.'
      ],
    ),
    _CardNewsItem(
      emoji: '🏜️',
      title: '물길 막는 모래주머니 쌓기',
      summary: '틈새가 생기지 않도록 지그재그 교차하여 쌓는 것이 핵심입니다. 차수 스티커와 병행하면 방수 효과가 극대화됩니다.',
      badge: '대비',
      badgeColor: AppColors.amber,
      steps: [
        '모래주머니는 바닥에 눕혀 평평하게 다진 뒤 빈틈없이 꼼꼼하게 밀착시킵니다.',
        '벽돌을 쌓는 것처럼 지그재그 형태로 교차해 올려 쌓아야 수압을 견딥니다.',
        '물길이 진입하는 현관문 앞, 주차장 입구, 지하 환풍구 틈새 등에 배치합니다.',
        '바닥에 비닐 시트를 깐 후 그 위에 쌓으면 물이 스며드는 것을 효과적으로 차단합니다.'
      ],
    ),
    _CardNewsItem(
      emoji: '🚗',
      title: '지하주차장 차량 대피 기준',
      summary: '경사로에 물이 흘러내리기 시작하면 지하 주차장 진입은 절대 금물입니다. 차수막 가동 전에 신속히 출차하세요.',
      badge: '차량',
      badgeColor: AppColors.info,
      steps: [
        '호우 경보 발령 시 대피 안내 방송에 귀 기울이고 신속하게 대기합니다.',
        '주차장 입구 경사로에 빗물이 흘러들기 시작했다면 차량 구출을 포기하고 절대 진입하지 마십시오.',
        '입구 차수판(물막이판)이 작동하기 전에 지상 높은 안전 지대로 이동시킵니다.',
        '차량이 이미 침수되어 바퀴의 2/3 이상 잠겼다면 즉시 차를 버리고 안전한 건물 2층 이상으로 대피하십시오.'
      ],
    ),
    _CardNewsItem(
      emoji: '⚡',
      title: '침수 후 감전/누전 차단 방법',
      summary: '실내에 물이 차오를 때는 가장 먼저 누전 차단기(두꺼비집)를 내리고 가스 밸브를 잠가 2차 대형 사고를 예방해야 합니다.',
      badge: '주의',
      badgeColor: AppColors.warning,
      steps: [
        '침수 위험 징후 포착 즉시 신발을 신은 상태에서 세대 내 누전 차단기 스위치를 내립니다.',
        '가스 배관 밸브를 잠가 가스 누출로 인한 폭발/화재 사고를 미연에 방지합니다.',
        '물이 고인 상태에서 가전제품 플러그를 만지거나 코드를 뽑는 행위는 매우 감전 위험이 높으니 절대 손대지 마십시오.',
        '대피 후 집으로 귀가했을 때도 가전 및 콘센트가 바짝 마르기 전까지는 전원을 켜지 말고 안전 진단을 받으세요.'
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.menu_book_rounded,
                    color: AppColors.amber, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '재난 안전 카드뉴스',
                      style: GoogleFonts.notoSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '침수 상황별 행동 요령 및 대비법',
                      style: GoogleFonts.notoSans(
                          fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 170,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _newsItems.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final item = _newsItems[index];
                return _CardNewsCard(
                  item: item,
                  onTap: () => _showDetailSheet(context, item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailSheet(BuildContext context, _CardNewsItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: item.badgeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.badge,
                      style: GoogleFonts.notoSans(
                        color: item.badgeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(item.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.title,
                      style: GoogleFonts.notoSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(color: AppColors.border, height: 24),
              Text(
                '구체적인 단계별 안전 지침:',
                style: GoogleFonts.notoSans(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ...List.generate(item.steps.length, (idx) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: item.badgeColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${idx + 1}',
                            style: GoogleFonts.outfit(
                              fontSize: 9,
                              color: item.badgeColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.steps[idx],
                          style: GoogleFonts.notoSans(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

class _CardNewsItem {
  final String emoji;
  final String title;
  final String summary;
  final String badge;
  final Color badgeColor;
  final List<String> steps;

  const _CardNewsItem({
    required this.emoji,
    required this.title,
    required this.summary,
    required this.badge,
    required this.badgeColor,
    required this.steps,
  });
}

class _CardNewsCard extends StatefulWidget {
  final _CardNewsItem item;
  final VoidCallback onTap;

  const _CardNewsCard({required this.item, required this.onTap});

  @override
  State<_CardNewsCard> createState() => _CardNewsCardState();
}

class _CardNewsCardState extends State<_CardNewsCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        transform: Matrix4.diagonal3Values(
            _pressed ? 0.96 : 1.0, _pressed ? 0.96 : 1.0, 1.0),
        width: 140,
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 54,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.item.badgeColor.withValues(alpha: 0.1),
                    AppColors.bgCard,
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(widget.item.emoji, style: const TextStyle(fontSize: 26)),
                  ),
                  Positioned(
                    top: 6,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: widget.item.badgeColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.item.badge,
                        style: GoogleFonts.notoSans(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.notoSans(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Expanded(
                      child: Text(
                        widget.item.summary,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.notoSans(
                          fontSize: 9,
                          color: AppColors.textMuted,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
