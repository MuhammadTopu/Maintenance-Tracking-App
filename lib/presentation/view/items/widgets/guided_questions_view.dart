import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/guided_answer_model.dart';
import '../../../../data/models/guided_question_model.dart';
import '../../../../shared/common_widgets.dart';
import '../../../../shared/custom_item_app_bar.dart';
import 'guided_question_tile.dart';

/// One round of Home / Other questions.
///
/// It keeps what the user has entered so far. The parent gives it a new `key`
/// for every round, so each round starts empty and scrolled to the top, while a
/// failed submit leaves the entered answers in place.
class GuidedQuestionsView extends StatefulWidget {
  const GuidedQuestionsView({
    super.key,
    required this.questions,
    required this.round,
    required this.isSubmitting,
    required this.onSubmit,
    required this.onClose,
  });

  final List<GuidedQuestion> questions;
  final int round;
  final bool isSubmitting;

  /// Receives one entry per question: an answer, or `skipped` for an optional
  /// question that was left blank.
  final Future<void> Function(List<GuidedAnswer> answers) onSubmit;
  final VoidCallback onClose;

  @override
  State<GuidedQuestionsView> createState() => _GuidedQuestionsViewState();
}

class _GuidedQuestionsViewState extends State<GuidedQuestionsView> {
  /// What the user has entered, by question id. See [GuidedAnswerBuilder] for
  /// the shape of each value.
  final Map<String, Object?> _drafts = {};

  void _setDraft(GuidedQuestion question, Object? value) {
    setState(() => _drafts[question.id] = value);
  }

  Future<void> _submit(
      List<({GuidedAnswer? answer, String? error})> checks,
      ) async {
    FocusScope.of(context).unfocus();
    // The button is only enabled when every check passed, so each entry has an
    // answer. Skip anything else rather than send a broken request.
    final answers = [
      for (final check in checks)
        if (check.answer != null) check.answer!,
    ];
    if (answers.length != checks.length) return;
    await widget.onSubmit(answers);
  }

  @override
  Widget build(BuildContext context) {
    final questions = widget.questions;
    final checks = [
      for (final question in questions)
        GuidedAnswerBuilder.build(question, _drafts[question.id]),
    ];
    final canSubmit =
        !widget.isSubmitting && checks.every((check) => check.error == null);
    final answeredCount = questions
        .where((q) => !GuidedAnswerBuilder.isBlank(_drafts[q.id]))
        .length;
    final progress = questions.isEmpty ? 0.0 : answeredCount / questions.length;

    return Scaffold(
      backgroundColor: const Color(0xffFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
              child: CustomItemAppBar(
                title: 'Quick Question & Answer',
                onTap: widget.onClose,
              ),
            ),
            SizedBox(height: 12.h),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.round <= 1
                      ? 'Answer a few questions so we can tailor your maintenance schedule.'
                      : 'A few follow-up questions to refine your schedule.',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                ),
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
                        value: progress,
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
                keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                child: Column(
                  children: [
                    for (var i = 0; i < questions.length; i++)
                      GuidedQuestionTile(
                        key: ValueKey(questions[i].id),
                        index: i + 1,
                        question: questions[i],
                        value: _drafts[questions[i].id],
                        onChanged: (value) => _setDraft(questions[i], value),
                      ),
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
                    color: Colors.black.withValues(alpha: 0.05),
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
                        visible: !widget.isSubmitting,
                        replacement: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                        child: PrimaryButton(
                          text: 'Submit',
                          onPressed: canSubmit ? () => _submit(checks) : null,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: widget.onClose,
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12.sp,
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