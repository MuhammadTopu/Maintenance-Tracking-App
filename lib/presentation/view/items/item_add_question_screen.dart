import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/common_widgets.dart';
import '../../../shared/custom_item_app_bar.dart';
import '../../view_models/add_item_provider.dart';
import '../../view_models/all_item_list_provider.dart';
import '../../view_models/question_provider.dart';
import '../../../data/models/question_response_model.dart';
import 'recommendation_screen.dart';

class ItemAddQuestionScreen extends StatefulWidget {
  const ItemAddQuestionScreen({super.key});

  @override
  State<ItemAddQuestionScreen> createState() => _ItemAddQuestionScreenState();
}

class _ItemAddQuestionScreenState extends State<ItemAddQuestionScreen> {
  final Map<String, String> answers = {};

  bool _hasError = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final addItemProvider = context.read<AddItemProvider>();
      final allItemProvider = context.read<AllItemListProvider>();
      final questionProvider = context.read<QuestionProvider>();

      questionProvider.setIsGenerateLoading(true);

      final success = await addItemProvider.addItem();

      if (!success) {
        if (mounted) Navigator.pop(context);
        return;
      }

      final newItemId = addItemProvider.lastAddedItemId;

      if (newItemId == null || newItemId.isEmpty) {
        if (mounted) Navigator.pop(context);
        return;
      }

      unawaited(allItemProvider.getAllItem());

      await questionProvider.setQId(newItemId);

      final questions = questionProvider.questionResponse?.questions ?? [];
      debugPrint('Fetched questions count: ${questions.length}');

      if (questions.isEmpty) {
        _hasError = true;
      }

      addItemProvider.clearFields();
      addItemProvider.clearLastAddedItemId();
      questionProvider.setIsGenerateLoading(false);

      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QuestionProvider>(
      builder: (_, provider, __) {
        if (provider.isGenerateLoading) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const WaveLoading(),
                  SizedBox(height: 16.h),
                  Text(
                    "Generating task. Please wait...",
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          );
        }

        final questions = provider.questionResponse?.questions ?? [];

        if (_hasError || questions.isEmpty) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  children: [
                    CustomItemAppBar(
                      title: 'Quick Question & Answer',
                      onTap: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.help_outline_rounded,
                              size: 48.sp,
                              color: Colors.grey[300],
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              'No maintenance questions available for this item.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final answeredCount = answers.length;

        return Scaffold(
          backgroundColor: const Color(0xffFAFAFA),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
                  child: CustomItemAppBar(
                    title: 'Quick Question & Answer',
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                SizedBox(height: 12.h),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(99.r),
                          child: LinearProgressIndicator(
                            value: answeredCount / questions.length,
                            minHeight: 6.h,
                            backgroundColor: const Color(0xffE9E9EA),
                            valueColor: AlwaysStoppedAnimation(
                              AppColors.primaryColor,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        '$answeredCount/${questions.length}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16.h),

                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                    child: Column(
                      children: [
                        ...questions.asMap().entries.map((entry) {
                          final index = entry.key;
                          final q = entry.value;
                          return QuestionTile(
                            index: index + 1,
                            question: q,
                            selectedAnswer: answers[q.id] ?? "",
                            onChanged: (String? value) {
                              setState(() {
                                answers[q.id] = value!;
                                debugPrint("Selected Answers: $answers");
                              });
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                ),

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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: Visibility(
                            visible: !provider.postLoading,
                            replacement: Padding(
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              child: Center(
                                child: CircularProgressIndicator(color: AppColors.primaryColor),
                              ),
                            ),
                            child: PrimaryButton(
                              text: 'Submit',
                              onPressed: answeredCount == questions.length
                                  ? () async {
                                final orderedAnswers = questions
                                    .map((q) => answers[q.id] ?? '')
                                    .toList();

                                debugPrint('Submitting answers in order: $orderedAnswers');

                                final success = await provider.answerQuestions(orderedAnswers);

                                if (!mounted) return;

                                if (success && provider.answeredResponse != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RecommendationScreen(
                                        response: provider.answeredResponse!,
                                      ),
                                    ),
                                  );
                                }
                              }
                                  : null,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12.sp),
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
      },
    );
  }
}

class QuestionTile extends StatelessWidget {
  final int index;
  final MaintenanceQuestion question;
  final String selectedAnswer;
  final ValueChanged<String?> onChanged;

  const QuestionTile({
    super.key,
    required this.index,
    required this.question,
    required this.selectedAnswer,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xffF0F0F1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 22.w,
                height: 22.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$index',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  question.maintenanceItem,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              _PriorityChip(priority: question.priority),
            ],
          ),

          SizedBox(height: 6.h),

          Padding(
            padding: EdgeInsets.only(left: 30.w),
            child: Text(
              question.category,
              style: TextStyle(
                fontSize: 10.5.sp,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ),

          SizedBox(height: 12.h),

          Text(
            question.question,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),

          if (question.reason.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: const Color(0xffF7F7F8),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 14.sp,
                    color: Colors.grey[500],
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      question.reason,
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: 14.h),

          Row(
            children: [
              Expanded(
                child: _AnswerOption(
                  label: "Yes",
                  value: "Yes",
                  icon: Icons.check_rounded,
                  color: const Color(0xff2E7D32),
                  groupValue: selectedAnswer,
                  onChanged: onChanged,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _AnswerOption(
                  label: "Planned",
                  value: "Planned",
                  icon: Icons.schedule_rounded,
                  color: const Color(0xffE58A00),
                  groupValue: selectedAnswer,
                  onChanged: onChanged,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _AnswerOption(
                  label: "No",
                  value: "No",
                  icon: Icons.close_rounded,
                  color: const Color(0xffC62828),
                  groupValue: selectedAnswer,
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnswerOption extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String groupValue;
  final ValueChanged<String?> onChanged;

  const _AnswerOption({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(10.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(vertical: 4.h),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? color : const Color(0xffE0E0E0),
            width: isSelected ? 1.4 : 1,
          ),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16.sp,
              color: isSelected ? color : Colors.grey[400],
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? color : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99.r),
      ),
      child: Text(
        priority,
        style: TextStyle(
          fontSize: 9.5.sp,
          color: _color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
