import 'package:flutter/material.dart';
import '../../../../models/user.dart';
import '../../../../widgets/profile/profile_dialog.dart';
import '../../../../utils/responsive.dart';
import '../../../../utils/app_theme.dart';

class HomeAppBar extends StatelessWidget {
  final User user;
  final bool isOwner;
  final bool showFilters;
  final VoidCallback onFilterToggle;
  final VoidCallback onSwitchToOwner;

  const HomeAppBar({
    super.key,
    required this.user,
    required this.isOwner,
    required this.showFilters,
    required this.onFilterToggle,
    required this.onSwitchToOwner,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    
    return SliverAppBar(
      expandedHeight: Responsive.getAppBarExpandedHeight(context),
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.background,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primary.withOpacity(0.15),
                AppTheme.background,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: isDesktop ? 32 : 20,
                top: 16,
                right: isDesktop ? 32 : 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      // Greeting section
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back',
                              style: TextStyle(
                                fontSize: Responsive.bodyText(context),
                                color: AppTheme.textMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.fullName.split(' ')[0],
                              style: TextStyle(
                                fontSize: Responsive.headline1(context),
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Tagline
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusRound),
                      border: Border.all(
                        color: AppTheme.primary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Ready to play today?',
                          style: TextStyle(
                            fontSize: Responsive.caption(context),
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        // Player Mode Indicator
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(AppTheme.radiusRound),
            border: Border.all(color: AppTheme.surfaceBorder),
          ),
          child: Row(
            children: [
              const Icon(Icons.sports_soccer, size: 14, color: AppTheme.primary),
              const SizedBox(width: 6),
              Text(
                'Player',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: Responsive.caption(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Switch to Owner Mode
        if (isOwner)
          Container(
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              border: Border.all(color: AppTheme.surfaceBorder),
            ),
            child: IconButton(
              icon: const Icon(Icons.business, color: AppTheme.accent, size: 20),
              onPressed: onSwitchToOwner,
              tooltip: 'Switch to Owner Mode',
            ),
          ),

        // Filter Toggle
        Container(
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: showFilters 
                ? AppTheme.primary.withOpacity(0.1) 
                : AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            border: Border.all(
              color: showFilters ? AppTheme.primary : AppTheme.surfaceBorder,
            ),
          ),
          child: IconButton(
            icon: Icon(
              showFilters ? Icons.filter_list : Icons.filter_list_outlined,
              color: showFilters ? AppTheme.primary : AppTheme.textSecondary,
              size: 20,
            ),
            onPressed: onFilterToggle,
            tooltip: 'Toggle Filters',
          ),
        ),

        // Notification Icon
        Container(
          margin: const EdgeInsets.only(right: 4),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.notifications_outlined, 
                    color: AppTheme.textSecondary,
                    size: 20,
                  ),
                  onPressed: () {},
                  tooltip: 'Notifications',
                ),
              ),
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppTheme.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.surface, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Profile Icon
        GestureDetector(
          onTap: () => ProfileDialog.show(context, user),
          child: Container(
            margin: EdgeInsets.only(right: isDesktop ? 24 : 12),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.primaryGradient,
              ),
              child: CircleAvatar(
                backgroundColor: AppTheme.surface,
                radius: isDesktop ? 18 : 16,
                child: Text(
                  user.fullName[0].toUpperCase(),
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: isDesktop ? 16 : 14,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
