// lib/widgets/category_card.dart

import 'package:flutter/material.dart';
import 'package:nabour_app/models/ride_model.dart';
import 'package:nabour_app/theme/app_colors.dart';
import 'package:nabour_app/theme/app_text_styles.dart';
import 'package:nabour_app/theme/app_constants.dart';

class CategoryCard extends StatefulWidget {
  final RideCategory category;
  final IconData icon;
  final String title;
  final String subtitle;
  final String price;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget? badge;
  final bool isEnabled;

  const CategoryCard({
    super.key,
    required this.category,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.isSelected,
    required this.onTap,
    this.badge,
    this.isEnabled = true,
  });

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppConstants.animationMedium,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _elevationAnimation = Tween<double>(begin: AppConstants.elevationM, end: AppConstants.elevationL).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CategoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  CategoryColors _getCategoryColors() {
    switch (widget.category) {
      case RideCategory.any:
        return CategoryColors(
          primary: const Color(0xFF7C3AED),
          background: const Color(0xFF7C3AED).withAlpha(25),
          gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF9C27B0)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        );
      case RideCategory.standard:
        return CategoryColors(
          primary: AppColors.standardCategory,
          background: AppColors.standardCategory.withAlpha(25),
          gradient: const LinearGradient(colors: [AppColors.standardCategory, AppColors.primaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
        );
      case RideCategory.family:
        return CategoryColors(
          primary: AppColors.familyCategory,
          background: AppColors.familyCategory.withAlpha(25),
          gradient: LinearGradient(colors: [AppColors.familyCategory, Colors.teal.shade300], begin: Alignment.topLeft, end: Alignment.bottomRight),
        );
      case RideCategory.energy:
        return CategoryColors(
          primary: AppColors.energyCategory,
          background: AppColors.energyCategory.withAlpha(25),
          gradient: const LinearGradient(colors: [AppColors.energyCategory, AppColors.secondaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
        );
      case RideCategory.best:
        return CategoryColors(
          primary: AppColors.bestCategory,
          background: AppColors.bestCategory.withAlpha(25),
          gradient: const LinearGradient(colors: [AppColors.bestCategory, Color(0xFF9C27B0)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        );
      case RideCategory.utility:
        return CategoryColors(
          primary: Colors.orange.shade700,
          background: Colors.orange.withAlpha(25),
          gradient: LinearGradient(colors: [Colors.orange.shade700, Colors.deepOrange], begin: Alignment.topLeft, end: Alignment.bottomRight),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _getCategoryColors();
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppConstants.radiusL),
              gradient: widget.isSelected ? colors.gradient : null,
              color: widget.isSelected ? null : AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: widget.isSelected 
                      ? colors.primary.withAlpha(76)
                      : AppColors.shadowLight,
                  blurRadius: _elevationAnimation.value * 2,
                  offset: Offset(0, _elevationAnimation.value),
                ),
              ],
              border: widget.isSelected 
                  ? null 
                  : Border.all(
                      color: AppColors.textDisabled.withAlpha(51),
                    ),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(AppConstants.radiusXL),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppConstants.radiusL),
                onTap: widget.isEnabled ? widget.onTap : null,
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingL),
                  child: Row(
                    children: [
                      _buildIcon(colors),
                      const SizedBox(width: AppConstants.spacingM),
                      Expanded(child: _buildContent()),
                      const SizedBox(width: AppConstants.spacingM),
                      _buildPriceSection(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIcon(CategoryColors colors) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: widget.isSelected 
            ? Colors.white.withAlpha(51)
            : colors.background,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: widget.isSelected 
            ? Border.all(color: Colors.white.withAlpha(76))
            : null,
      ),
      child: Icon(
        widget.icon,
        size: AppConstants.iconL,
        color: widget.isSelected 
            ? AppColors.textOnPrimary
            : colors.primary,
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.title,
                style: AppTextStyles.headingMedium.copyWith(
                  color: widget.isSelected 
                      ? AppColors.textOnPrimary
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.badge != null) ...[
              const SizedBox(width: AppConstants.spacingS),
              widget.badge!,
            ],
          ],
        ),
        const SizedBox(height: AppConstants.spacingXS),
        Text(
          widget.subtitle,
          style: AppTextStyles.bodyMedium.copyWith(
            color: widget.isSelected 
                ? AppColors.textOnPrimary.withAlpha(230)
                : AppColors.textSecondary,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.price,
          style: AppTextStyles.priceText.copyWith(
            color: widget.isSelected 
                ? AppColors.textOnPrimary
                : AppColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (widget.isSelected) ...[
          const SizedBox(height: AppConstants.spacingXS),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingS,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              borderRadius: BorderRadius.circular(AppConstants.radiusS),
              border: Border.all(
                color: Colors.white.withAlpha(76),
              ),
            ),
            child: Text(
              'SELECTAT',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textOnPrimary,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class PremiumCategoryCard extends StatefulWidget {
  final RideCategory category;
  final IconData icon;
  final String title;
  final String subtitle;
  final Map<String, double> fareDetails;
  final bool isSelected;
  final VoidCallback onTap;
  final String? estimatedTime;
  final bool isRecommended;

  const PremiumCategoryCard({
    super.key,
    required this.category,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.fareDetails,
    required this.isSelected,
    required this.onTap,
    this.estimatedTime,
    this.isRecommended = false,
  });

  @override
  State<PremiumCategoryCard> createState() => _PremiumCategoryCardState();
}

class _PremiumCategoryCardState extends State<PremiumCategoryCard>
    with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late AnimationController _selectionController;
  late Animation<double> _hoverAnimation;
  late Animation<double> _shimmerAnimation;

  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    
    _hoverController = AnimationController(
      duration: AppConstants.animationFast,
      vsync: this,
    );
    
    _selectionController = AnimationController(
      duration: AppConstants.animationMedium,
      vsync: this,
    );

    _hoverAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(CurvedAnimation(
      parent: _selectionController,
      curve: Curves.easeInOut,
    ));

    if (widget.isSelected) {
      _selectionController.forward();
    }
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _selectionController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PremiumCategoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _selectionController.forward();
      } else {
        _selectionController.reverse();
      }
    }
  }
  
  void _onHover(bool isHovering) {
    setState(() { _isHovering = isHovering; });
    if (isHovering) { _hoverController.forward(); } else { _hoverController.reverse(); }
  }

  CategoryColors _getCategoryColors() {
    switch (widget.category) {
      case RideCategory.any:
        return CategoryColors(
          primary: const Color(0xFF7C3AED),
          background: const Color(0xFF7C3AED).withAlpha(25),
          gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF9C27B0)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        );
      case RideCategory.standard:
        return CategoryColors(
          primary: AppColors.standardCategory,
          background: AppColors.standardCategory.withAlpha(25),
          gradient: const LinearGradient(colors: [AppColors.standardCategory, AppColors.primaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
        );
      case RideCategory.family:
        return CategoryColors(
          primary: AppColors.familyCategory,
          background: AppColors.familyCategory.withAlpha(25),
          gradient: LinearGradient(colors: [AppColors.familyCategory, Colors.teal.shade300], begin: Alignment.topLeft, end: Alignment.bottomRight),
        );
      case RideCategory.energy:
        return CategoryColors(
          primary: AppColors.energyCategory,
          background: AppColors.energyCategory.withAlpha(25),
          gradient: const LinearGradient(colors: [AppColors.energyCategory, AppColors.secondaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
        );
      case RideCategory.best:
        return CategoryColors(
          primary: AppColors.bestCategory,
          background: AppColors.bestCategory.withAlpha(25),
          gradient: const LinearGradient(colors: [AppColors.bestCategory, Color(0xFF9C27B0)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        );
      case RideCategory.utility:
        return CategoryColors(
          primary: Colors.orange.shade700,
          background: Colors.orange.withAlpha(25),
          gradient: LinearGradient(colors: [Colors.orange.shade700, Colors.deepOrange], begin: Alignment.topLeft, end: Alignment.bottomRight),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _getCategoryColors();
    
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: AnimatedBuilder(
        animation: Listenable.merge([_hoverController, _selectionController]),
        builder: (context, child) {
          return Transform.scale(
            scale: _hoverAnimation.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppConstants.radiusL),
                gradient: widget.isSelected ? colors.gradient : null,
                color: widget.isSelected ? null : AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: widget.isSelected ? colors.primary.withAlpha(102) : (_isHovering ? AppColors.shadowMedium : AppColors.shadowLight),
                    blurRadius: widget.isSelected ? 20 : (_isHovering ? 12 : 8),
                    offset: Offset(0, widget.isSelected ? 8 : (_isHovering ? 6 : 2)),
                  ),
                ],
                border: widget.isSelected ? null : Border.all(color: AppColors.textDisabled.withAlpha(51)),
              ),
              child: Stack(
                children: [
                  if (widget.isSelected) _buildShimmerEffect(),
                  if (widget.isRecommended) _buildRecommendedBadge(),
                  Material(
                    color: Colors.transparent,
              borderRadius: BorderRadius.circular(AppConstants.radiusL),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppConstants.radiusL),
                onTap: widget.onTap,
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingM),
                        child: _buildContent(colors),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerEffect() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppConstants.radiusL),
      child: AnimatedBuilder(
        animation: _shimmerAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_shimmerAnimation.value * 200, 0),
            child: Container(
              width: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.white.withAlpha(51), Colors.transparent],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecommendedBadge() {
    return Positioned(
      top: AppConstants.spacingM,
      right: AppConstants.spacingM,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingS, vertical: AppConstants.spacingXS),
        decoration: BoxDecoration(
          color: AppColors.warning,
          borderRadius: BorderRadius.circular(AppConstants.radiusS),
          boxShadow: [ BoxShadow(color: AppColors.warning.withAlpha(76), blurRadius: 4, offset: const Offset(0, 2),),],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, color: Colors.white, size: AppConstants.iconS,),
            const SizedBox(width: 2),
            Text('RECOMANDAT', style: AppTextStyles.labelSmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5,),),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(CategoryColors colors) {
    return Row(
      children: [
        _buildEnhancedIcon(colors),
        const SizedBox(width: AppConstants.spacingM),
        Expanded(child: _buildEnhancedContent()),
        const SizedBox(width: AppConstants.spacingM),
        Flexible(child: _buildEnhancedPriceSection()),
      ],
    );
  }

  Widget _buildEnhancedIcon(CategoryColors colors) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: widget.isSelected ? Colors.white.withAlpha(51) : colors.background,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: widget.isSelected ? Border.all(color: Colors.white.withAlpha(76), width: 2) : null,
        boxShadow: widget.isSelected ? [BoxShadow(color: Colors.white.withAlpha(51), blurRadius: 8, offset: const Offset(0, 4),),] : null,
      ),
      child: Icon(widget.icon, size: AppConstants.iconL + 4, color: widget.isSelected ? AppColors.textOnPrimary : colors.primary,),
    );
  }

  Widget _buildEnhancedContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.title,
          style: AppTextStyles.headingMedium.copyWith(
            color: widget.isSelected ? AppColors.textOnPrimary : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppConstants.spacingXS),
        Text(
          widget.subtitle,
          style: AppTextStyles.bodyMedium.copyWith(
            color: widget.isSelected ? AppColors.textOnPrimary.withAlpha(230) : AppColors.textSecondary,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (widget.estimatedTime != null) ...[
          const SizedBox(height: AppConstants.spacingS),
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: AppConstants.iconS,
                color: widget.isSelected ? AppColors.textOnPrimary.withAlpha(204) : AppColors.textSecondary,
              ),
              const SizedBox(width: AppConstants.spacingXS),
              Expanded(
                child: Text(
                  widget.estimatedTime!,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: widget.isSelected ? AppColors.textOnPrimary.withAlpha(204) : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildEnhancedPriceSection() {
    if (!widget.isSelected) return const SizedBox.shrink();
    return _buildSelectedIndicator();
  }

  Widget _buildSelectedIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingS, vertical: AppConstants.spacingXS,),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(51),
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
        border: Border.all(color: Colors.white.withAlpha(102),),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.textOnPrimary, size: AppConstants.iconS,),
          const SizedBox(width: AppConstants.spacingXS),
          Flexible(
            child: Text(
              'SELECTAT',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textOnPrimary,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

}


class CategoryCardList extends StatelessWidget {
  final Map<RideCategory, Map<String, double>> faresByCategory;
  final RideCategory selectedCategory;
  final Function(RideCategory) onCategorySelected;
  final String? estimatedTime;
  final bool showRecommendation;

  const CategoryCardList({
    super.key,
    required this.faresByCategory,
    required this.selectedCategory,
    required this.onCategorySelected,
    this.estimatedTime,
    this.showRecommendation = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildCategoryCard(
          RideCategory.standard,
          Icons.drive_eta_rounded,
          'Standard',
          'Cea mai accesibilă opțiune.',
          isRecommended: showRecommendation,
        ),
        _buildCategoryCard(
          RideCategory.family,
          Icons.family_restroom_rounded,
          'Family',
          'Mai mult spațiu pentru toți.',
        ),
        _buildCategoryCard(
          RideCategory.energy,
          Icons.electric_car_rounded,
          'Energy',
          'Călătorește eco-friendly.',
        ),
        _buildCategoryCard(
          RideCategory.best,
          Icons.star_rounded,
          'Best',
          'Experiență premium.',
        ),
      ],
    );
  }

  Widget _buildCategoryCard(
    RideCategory category,
    IconData icon,
    String title,
    String subtitle, {
    bool isRecommended = false,
  }) {
    final fareDetails = faresByCategory[category];
    if (fareDetails == null) return const SizedBox.shrink();

    return PremiumCategoryCard(
      category: category,
      icon: icon,
      title: title,
      subtitle: subtitle,
      fareDetails: fareDetails,
      isSelected: selectedCategory == category,
      onTap: () => onCategorySelected(category),
      estimatedTime: estimatedTime,
      isRecommended: isRecommended,
    );
  }
}

// --- CLASA AJUTĂTOARE ADĂUGATĂ ---
class CategoryColors {
  final Color primary;
  final Color background;
  final LinearGradient gradient;

  CategoryColors({
    required this.primary,
    required this.background,
    required this.gradient,
  });
}