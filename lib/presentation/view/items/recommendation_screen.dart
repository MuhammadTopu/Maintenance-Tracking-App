import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:maintenance_genie/presentation/view_models/parent_screen_provider.dart';
import 'package:provider/provider.dart';
import '../../../app/routes/route_names.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/common_widgets.dart';
import '../../../shared/custom_item_app_bar.dart';
import '../../../data/models/question_response_model.dart';
import '../../view_models/question_provider.dart';
import '../../view_models/item_task_list_provider.dart';

class RecommendationScreen extends StatelessWidget {
  final QuestionsResponse response;

  const RecommendationScreen({super.key, required this.response});

  @override
  Widget build(BuildContext context) {
    final questions = response.questions;

    final recommendedCount = questions
        .where(
          (q) =>
              (q.recommendations.isNotEmpty
                      ? q.recommendations.first.status
                      : '')
                  .toLowerCase() ==
              'recommended',
        )
        .length;
    final completeCount = questions
        .where(
          (q) =>
              (q.recommendations.isNotEmpty
                      ? q.recommendations.first.status
                      : '')
                  .toLowerCase() ==
              'complete',
        )
        .length;
    final plannedCount = questions
        .where(
          (q) =>
              (q.recommendations.isNotEmpty
                      ? q.recommendations.first.status
                      : '')
                  .toLowerCase() ==
              'planned',
        )
        .length;

    return Scaffold(
      backgroundColor: const Color(0xffFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
              child: CustomItemAppBar(
                title: 'Recommendations',
                onTap: () => Navigator.pop(context),
              ),
            ),

            SizedBox(height: 16.h),

            // Summary header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryColor,
                      AppColors.primaryColor.withOpacity(0.85),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.fact_check_rounded,
                          color: Colors.white,
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          '${questions.length} feedback reviewed',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Here\'s what we recommend based on your answers',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 11.5.sp,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        _SummaryStat(
                          label: 'Recommended',
                          count: recommendedCount,
                          icon: Icons.priority_high_rounded,
                        ),
                        SizedBox(width: 10.w),
                        _SummaryStat(
                          label: 'Planned',
                          count: plannedCount,
                          icon: Icons.schedule_rounded,
                        ),
                        SizedBox(width: 10.w),
                        _SummaryStat(
                          label: 'Completed',
                          count: completeCount,
                          icon: Icons.check_circle_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 18.h),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                child: Column(
                  children: questions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final q = entry.value;
                    return RecommendationTile(index: index + 1, question: q);
                  }).toList(),
                ),
              ),
            ),

            // Sticky bottom action bar
            Container(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Consumer<QuestionProvider>(
                  builder: (ctx, provider, _) {
                    return SizedBox(
                      width: double.infinity,
                      child: Visibility(
                        visible: !provider.taskGenerating,
                        replacement: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                        child: PrimaryButton(
                          text: 'Generate Tasks',
                          onPressed: () async {
                            final success = await provider.generateTasks();

                            if (!ctx.mounted) return;

                            if (success) {
                              await ctx
                                  .read<ItemTaskListProvider>()
                                  .getItemTasks();

                              if (!ctx.mounted) return;

                              ctx.read<ParentScreensProvider>().onSelectedIndex(
                                1,
                              );
                              Navigator.of(ctx).pushNamedAndRemoveUntil(
                                RouteName.parent,
                                (route) => false,
                              );
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;

  const _SummaryStat({
    required this.label,
    required this.count,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 6.w),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 16.sp),
            SizedBox(height: 4.h),
            Text(
              '$count',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 9.5.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RecommendationTile extends StatelessWidget {
  final int index;
  final MaintenanceQuestion question;

  const RecommendationTile({
    super.key,
    required this.index,
    required this.question,
  });

  QuestionRecommendation? get _recommendation =>
      question.recommendations.isNotEmpty
      ? question.recommendations.first
      : null;

  Color get _statusColor {
    switch (_recommendation?.status.toLowerCase()) {
      case 'complete':
        return const Color(0xff2E7D32);
      case 'planned':
        return const Color(0xffE58A00);
      case 'recommended':
        return const Color(0xffC62828);
      default:
        return Colors.grey;
    }
  }

  IconData get _statusIcon {
    switch (_recommendation?.status.toLowerCase()) {
      case 'complete':
        return Icons.check_circle_rounded;
      case 'planned':
        return Icons.schedule_rounded;
      case 'recommended':
        return Icons.error_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor;

    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xffF0F0F1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== Top strip: status color bar =====
          Container(
            height: 4.h,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 26.w,
                      height: 26.w,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$index',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            question.maintenanceItem,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            question.category,
                            style: TextStyle(
                              fontSize: 10.5.sp,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    _PriorityChip(priority: question.priority),
                  ],
                ),

                SizedBox(height: 14.h),

                // Question
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: const Color(0xffF7F7F8),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        question.question,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                      if (question.reason.isNotEmpty) ...[
                        SizedBox(height: 6.h),
                        Text(
                          question.reason,
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            color: Colors.grey[600],
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                SizedBox(height: 12.h),

                // Answer badge
                if (question.userAnswer != null &&
                    question.userAnswer!.isNotEmpty)
                  _AnswerBadge(answer: question.userAnswer!),

                // Recommendation
                if (_recommendation != null) ...[
                  SizedBox(height: 10.h),
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: statusColor.withOpacity(0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(_statusIcon, size: 18.sp, color: statusColor),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _recommendation!.status,
                                style: TextStyle(
                                  fontSize: 10.5.sp,
                                  fontWeight: FontWeight.w800,
                                  color: statusColor,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              SizedBox(height: 3.h),
                              Text(
                                _recommendation!.message,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.grey[800],
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerBadge extends StatelessWidget {
  final String answer;
  const _AnswerBadge({required this.answer});

  ({IconData icon, Color color}) get _style {
    switch (answer) {
      case 'Yes':
        return (icon: Icons.check_rounded, color: const Color(0xff2E7D32));
      case 'Planned':
        return (icon: Icons.schedule_rounded, color: const Color(0xffE58A00));
      case 'No':
        return (icon: Icons.close_rounded, color: const Color(0xffC62828));
      default:
        return (icon: Icons.help_outline_rounded, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _style;
    return Row(
      children: [
        Text(
          'Your answer',
          style: TextStyle(
            fontSize: 11.sp,
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(width: 8.w),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: s.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(99.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(s.icon, size: 12.sp, color: s.color),
              SizedBox(width: 4.w),
              Text(
                answer,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: s.color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PriorityChip extends StatelessWidget {
  final String priority;
  const _PriorityChip({required this.priority});

  Color get _color {
    switch (priority.toLowerCase()) {
      case 'high':
        return const Color(0xffC62828);
      case 'medium':
        return const Color(0xffE58A00);
      case 'low':
        return const Color(0xff2E7D32);
      default:
        return Colors.grey;
    }
  }

  IconData get _icon {
    switch (priority.toLowerCase()) {
      case 'high':
        return Icons.keyboard_double_arrow_up_rounded;
      case 'medium':
        return Icons.drag_handle_rounded;
      case 'low':
        return Icons.keyboard_arrow_down_rounded;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(99.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 11.sp, color: _color),
          SizedBox(width: 3.w),
          Text(
            priority,
            style: TextStyle(
              fontSize: 9.5.sp,
              color: _color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
