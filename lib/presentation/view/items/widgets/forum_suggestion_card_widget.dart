import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:maintenance_genie/data/models/one_item_model.dart';

class ForumSuggestionsCard extends StatelessWidget {
  final OneItemModel response;

  const ForumSuggestionsCard({super.key, required this.response});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Forum Suggestions',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18.sp),
        ),
        const Divider(color: Colors.grey, thickness: 1.07),
        response.item.forumSuggestions.isEmpty
            ? const Text('No suggestions available')
            : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: response.item.forumSuggestions.length,
              itemBuilder: (context, index) {
                return Text(
                  response.item.forumSuggestions[index].replaceAll('**', ' '),
                  style: TextStyle(
                    fontSize: 15.sp,
                    color: Colors.grey.shade700,
                  ),
                );
              },
              separatorBuilder: (context, index) => SizedBox(height: 4.h),
            ),
      ],
    );
  }
}
