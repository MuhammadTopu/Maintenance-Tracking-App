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
import '../../../data/models/guided_answer_model.dart';
import '../../../data/models/question_response_model.dart';
import 'answers_review_screen.dart';
import 'recommendation_screen.dart';
import 'widgets/guided_questions_view.dart';

/// Step after "Add Asset" for premium users, for every category:
///
///  1. saves the item (so the server can generate its questions),
///  2. loads the questions,
///  3. Vehicle: Yes / No / Planned → recommendations.
///     Home and Other: typed questions, round by round → read-only review.
///
/// It is opened with the `AddItemData` as its route argument and pops `true`
/// once the item is saved, so the form that opened it can reset itself and the
/// same item cannot be submitted twice.
class ItemAddQuestionScreen extends StatefulWidget {
  const ItemAddQuestionScreen({super.key});

  @override
  State<ItemAddQuestionScreen> createState() => _ItemAddQuestionScreenState();
}

class _ItemAddQuestionScreenState extends State<ItemAddQuestionScreen> {
  /// Vehicle answers (Yes / No / Planned) by question id.
  final Map<String, String> answers = {};

  String? _itemId;
  String _category = ItemCategory.vehicle;
  bool _itemSaved = false;
  bool _loadFailed = false;

  /// True until the item is saved and the questions were requested, so the
  /// first frame shows the loader and not an empty state.
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
          (_) => _createItemAndLoadQuestions(),
    );
  }

  Future<void> _createItemAndLoadQuestions() async {
    final addItemProvider = context.read<AddItemProvider>();
    final allItemProvider = context.read<AllItemListProvider>();
    final questionProvider = context.read<QuestionProvider>();

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! AddItemData) {
      debugPrint('ItemAddQuestionScreen: missing AddItemData argument');
      _close();
      return;
    }

    // The provider outlives this screen, so start from a clean slate.
    questionProvider.reset();
    questionProvider.setIsGenerateLoading(true);

    final success = await addItemProvider.addItem(args);
    final itemId = addItemProvider.lastAddedItemId;

    if (!success || itemId == null || itemId.isEmpty) {
      questionProvider.setIsGenerateLoading(false);
      _close();
      return;
    }

    _itemSaved = true;
    _itemId = itemId;
    _category = args.category;

    addItemProvider.clearFields();
    addItemProvider.clearLastAddedItemId();
    unawaited(allItemProvider.getAllItem());

    if (!mounted) return;
    await _loadQuestions();
  }

  /// Fetches the questions of the saved item. Also used by "Try again".
  Future<void> _loadQuestions() async {
    final itemId = _itemId;
    if (itemId == null) return;

    final provider = context.read<QuestionProvider>();
    provider.setIsGenerateLoading(true);
    await provider.start(itemId: itemId, category: _category);

    _loadFailed = provider.isGuidedFlow && !provider.guidedLoaded;
    provider.setIsGenerateLoading(false);

    if (mounted) {
      setState(() => _initializing = false);
    }
  }

  /// Closes the screen. Pops `true` when the item was already saved.
  void _close() {
    if (!mounted) return;
    Navigator.of(context).pop(_itemSaved);
  }

  /// The user wants to leave. Not while the item is being saved or the
  /// questions are loading: leaving then would drop the screen while a request
  /// is still running.
  void _leave() {
    if (context.read<QuestionProvider>().isGenerateLoading) return;
    _close();
  }

  /// Home / Other: show the read-only review. It replaces this screen, so back
  /// from the review does not return to a finished question list.
  void _openReview() {
    Navigator.of(context).pushReplacement<void, bool>(
      MaterialPageRoute<void>(builder: (_) => const AnswersReviewScreen()),
      result: _itemSaved,
    );
  }

  Future<void> _submitGuided(List<GuidedAnswer> guidedAnswers) async {
    final provider = context.read<QuestionProvider>();
    final accepted = await provider.submitGuidedAnswers(guidedAnswers);
    if (!mounted || !accepted) return; // the error was already shown

    // Finished: review. Otherwise the provider now holds the next round and
    // this screen rebuilds with it.
    if (provider.guidedFinished) _openReview();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Consumer<QuestionProvider>(
        builder: (_, provider, __) {
          if (_initializing || provider.isGenerateLoading) {
            return _buildLoading();
          }
          return provider.isGuidedFlow
              ? _buildGuided(provider)
              : _buildVehicle(provider);
        },
      ),
    );
  }

  Widget _buildLoading() {
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

  /// A centred message with an optional button, under the usual app bar.
  Widget _buildMessageState({
    required IconData icon,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              CustomItemAppBar(
                title: 'Quick Question & Answer',
                onTap: _leave,
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 48.sp, color: Colors.grey[300]),
                      SizedBox(height: 12.h),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                      ),
                      if (actionLabel != null && onAction != null) ...[
                        SizedBox(height: 20.h),
                        PrimaryButton(text: actionLabel, onPressed: onAction),
                      ],
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

  // ================= HOME / OTHER =================

  Widget _buildGuided(QuestionProvider provider) {
    if (_loadFailed) {
      return _buildMessageState(
        icon: Icons.cloud_off_rounded,
        message: 'We couldn\'t load the questions for this item.',
        actionLabel: 'Try again',
        onAction: _loadQuestions,
      );
    }

    final pending = provider.pendingQuestions;
    if (pending.isEmpty) {
      // Nothing to ask (or everything is already answered). Tasks can still
      // be generated.
      return _buildMessageState(
        icon: Icons.help_outline_rounded,
        message: 'No more questions for this item.',
        actionLabel: 'Continue',
        onAction: _openReview,
      );
    }

    return GuidedQuestionsView(
      // A new key per round: empty answers, scrolled to the top.
      key: ValueKey('round-${provider.round}-${pending.first.id}'),
      questions: pending,
      round: provider.round,
      isSubmitting: provider.postLoading,
      onSubmit: _submitGuided,
      onClose: _leave,
    );
  }

  // ================= VEHICLE =================

  Widget _buildVehicle(QuestionProvider provider) {
    final questions = provider.questionResponse?.questions ?? [];

    if (questions.isEmpty) {
      return _buildMessageState(
        icon: Icons.help_outline_rounded,
        message: 'No maintenance questions available for this item.',
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
                onTap: _leave,
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
                            child: CircularProgressIndicator(
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                        child: PrimaryButton(
                          text: 'Submit',
                          onPressed: answeredCount == questions.length
                              ? () => _submitVehicle(provider, questions)
                              : null,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _leave,
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

  Future<void> _submitVehicle(
      QuestionProvider provider,
      List<MaintenanceQuestion> questions,
      ) async {
    // One answer per question, in the order the questions were returned.
    final orderedAnswers = questions.map((q) => answers[q.id] ?? '').toList();

    debugPrint('Submitting answers in order: $orderedAnswers');

    final success = await provider.answerQuestions(orderedAnswers);

    if (!mounted) return;

    if (success && provider.answeredResponse != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              RecommendationScreen(response: provider.answeredResponse!),
        ),
      );
    }
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