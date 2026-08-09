import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:maintenance_genie/data/models/one_item_model.dart';
import 'package:maintenance_genie/shared/common_widgets.dart';

import '../../../../core/constants/app_colors.dart';

class ForumSuggestionsCard extends StatelessWidget {
  final OneItemModel response;
  final bool isPremium;

  const ForumSuggestionsCard({
    super.key,
    required this.response,
    required this.isPremium,
  });

  @override
  Widget build(BuildContext context) {
    final suggestions = response.item.forumSuggestions;
    final hasSuggestions = suggestions.isNotEmpty;

    if (!isPremium) {
      return PremiumLockedView(
        title: 'Go Premium to see\nForum Suggestions',
        showButton: !isPremium,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Forum Suggestions',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18.sp),
        ),
        const Divider(color: Colors.grey, thickness: 1.07),
        hasSuggestions ?
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            final s = suggestions[index];
            return _ForumSuggestionTile(suggestion: s);
          },
          separatorBuilder: (context, index) =>
              Divider(height: 20.h, color: Colors.grey.shade300),
        ) : const Text('No suggestions available'),
      ],
    );
  }
}

class _ForumSuggestionTile extends StatelessWidget {
  final ForumSuggestion suggestion;

  const _ForumSuggestionTile({required this.suggestion});

  Color _confidenceColor(String confidence) {
    switch (confidence.toLowerCase()) {
      case 'high':
        return Colors.green.shade700;
      case 'medium':
        return Colors.orange.shade800;
      case 'low':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                suggestion.maintenanceItem.isNotEmpty
                    ? suggestion.maintenanceItem
                    : suggestion.category,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade900,
                ),
              ),
            ),
            if (suggestion.confidence.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: _confidenceColor(suggestion.confidence).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(99.r),
                  border: Border.all(color: _confidenceColor(suggestion.confidence)),
                ),
                child: Text(
                  suggestion.confidence,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: _confidenceColor(suggestion.confidence),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 6.h),
        if (suggestion.appliesTo.isNotEmpty)
          Text(
            'Applies to: ${suggestion.appliesTo}',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
          ),
        SizedBox(height: 4.h),
        if (suggestion.manufacturerInterval.isNotEmpty ||
            suggestion.forumRecommendedInterval.isNotEmpty)
          Wrap(
            spacing: 12.w,
            runSpacing: 4.h,
            children: [
              if (suggestion.manufacturerInterval.isNotEmpty)
                Text(
                  'Manufacturer: ${suggestion.manufacturerInterval}',
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade700),
                ),
              if (suggestion.forumRecommendedInterval.isNotEmpty)
                Text(
                  'Forum recommended: ${suggestion.forumRecommendedInterval}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade900,
                  ),
                ),
            ],
          ),
        SizedBox(height: 6.h),
        if (suggestion.reason.isNotEmpty)
          GptMarkdown(
            suggestion.reason,
            style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade700),
          ),
        if (suggestion.sourceForum.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: 4.h),
            child: Text(
              'Source: ${suggestion.sourceForum}',
              style: TextStyle(
                fontSize: 11.sp,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade500,
              ),
            ),
          ),
      ],
    );
  }
}