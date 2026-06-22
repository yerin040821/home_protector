// lib/widgets/commerce_widget.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class CommerceWidget extends StatelessWidget {
  const CommerceWidget({super.key});

  static const List<_Product> _products = [
    _Product(
      emoji: '🚧',
      name: '차수 스티커',
      description: '현관문 침수 방어\n방수 실리콘 접착',
      price: '45,000원',
      badge: '인기',
      badgeColor: AppColors.red,
      rating: 4.8,
      reviews: 1234,
    ),
    _Product(
      emoji: '🛡️',
      name: '비상 모래주머니',
      description: '10kg × 5개 세트\n즉시 배송 가능',
      price: '28,000원',
      badge: 'NEW',
      badgeColor: AppColors.info,
      rating: 4.6,
      reviews: 567,
    ),
    _Product(
      emoji: '🎒',
      name: '생존 굿즈 세트',
      description: '비상식량+손전등\n구급용품 포함',
      price: '89,000원',
      badge: '추천',
      badgeColor: AppColors.amber,
      rating: 4.9,
      reviews: 2891,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
                child: const Icon(Icons.shopping_bag_rounded,
                    color: AppColors.amber, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '침수 대비 필수 아이템',
                      style: GoogleFonts.notoSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '제휴 파트너 최저가 · 익일배송',
                      style: GoogleFonts.notoSans(
                          fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _showAllProducts(context),
                child: Text(
                  '전체보기',
                  style: GoogleFonts.notoSans(
                    fontSize: 12,
                    color: AppColors.amber,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 225,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _products.length,
              separatorBuilder: (_, idx) => const SizedBox(width: 10),
              itemBuilder: (context, i) => _ProductCard(
                product: _products[i],
                onTap: () => _showProductDetail(context, _products[i]),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_rounded,
                    color: AppColors.success, size: 16),
                const SizedBox(width: 8),
                Text(
                  '제휴 파트너: 쿠팡·네이버쇼핑·11번가',
                  style: GoogleFonts.notoSans(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '최대 5% 적립',
                    style: GoogleFonts.notoSans(
                      fontSize: 10,
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
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

  void _showProductDetail(BuildContext context, _Product product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ProductDetailSheet(product: product),
    );
  }

  void _showAllProducts(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('더 많은 재난 대비 상품이 준비 중입니다!',
            style: GoogleFonts.notoSans(color: AppColors.textPrimary)),
        backgroundColor: AppColors.bgSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border)),
      ),
    );
  }
}

class _Product {
  final String emoji;
  final String name;
  final String description;
  final String price;
  final String badge;
  final Color badgeColor;
  final double rating;
  final int reviews;
  const _Product({
    required this.emoji,
    required this.name,
    required this.description,
    required this.price,
    required this.badge,
    required this.badgeColor,
    required this.rating,
    required this.reviews,
  });
}

class _ProductCard extends StatefulWidget {
  final _Product product;
  final VoidCallback onTap;
  const _ProductCard({required this.product, required this.onTap});

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
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
        width: 155,
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.product.badgeColor
                            .withValues(alpha: 0.1),
                        AppColors.bgCard,
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16)),
                  ),
                  child: Center(
                    child: Text(widget.product.emoji,
                        style: const TextStyle(fontSize: 40)),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: widget.product.badgeColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.product.badge,
                      style: GoogleFonts.notoSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: GoogleFonts.notoSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.product.description,
                    style: GoogleFonts.notoSans(
                      fontSize: 10,
                      color: AppColors.textMuted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: AppColors.amber, size: 12),
                      const SizedBox(width: 2),
                      Text(
                        '${widget.product.rating}',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: AppColors.amber,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        ' (${widget.product.reviews})',
                        style: GoogleFonts.notoSans(
                            fontSize: 10, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.product.price,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: AppColors.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.shopping_cart_rounded,
                            color: AppColors.red, size: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductDetailSheet extends StatelessWidget {
  final _Product product;
  const _ProductDetailSheet({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(product.emoji,
              style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 12),
          Text(
            product.name,
            style: GoogleFonts.notoSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            product.description.replaceAll('\n', ' '),
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSans(
                fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Text(
            product.price,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.amber,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('제휴 쇼핑몰로 연결 중...',
                        style:
                            GoogleFonts.notoSans(color: AppColors.textPrimary)),
                    backgroundColor: AppColors.bgSurface,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.border)),
                  ),
                );
              },
              child: Text(
                '구매하러 가기',
                style: GoogleFonts.notoSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
