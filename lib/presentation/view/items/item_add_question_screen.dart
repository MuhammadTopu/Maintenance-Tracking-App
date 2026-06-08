import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../app/routes/route_names.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/common_widgets.dart';
import '../../../shared/custom_item_app_bar.dart';
import '../../view_models/add_item_provider.dart';
import '../../view_models/all_item_list_provider.dart';
import '../../view_models/question_provider.dart';
import '../../view_models/user_provider.dart';
import 'widgets/show_item_added_dialog.dart';

class ItemAddQuestionScreen extends StatefulWidget {
  const ItemAddQuestionScreen({super.key});

  @override
  State<ItemAddQuestionScreen> createState() => _ItemAddQuestionScreenState();
}

class _ItemAddQuestionScreenState extends State<ItemAddQuestionScreen> {
  List<String> answers = List.generate(5, (index) => "No");

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.read<QuestionProvider>().setIsGenerateLoading(true);

      await context.read<AddItemProvider>().addItem();
      await context.read<AllItemListProvider>().getAllItem();
      await context.read<QuestionProvider>().setQId(
        context.read<AllItemListProvider>().allItemListModel?.items?.first.id ??
            '',
      );

      context.read<QuestionProvider>().setIsGenerateLoading(false);
      context.read<AddItemProvider>().clearFields();
    });
    super.initState();
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
                  CircularProgressIndicator(),
                  SizedBox(height: 16.h),
                  Text(
                    "Generating task. Please wait...",
                    style: TextStyle(fontSize: 14.sp),
                  ),
                ],
              ),
            ),
          );
        }
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    CustomItemAppBar(
                      title: 'Quick Question & Answer',
                      onTap: () => Navigator.pop(context),
                    ),
                    Divider(),
                    const SizedBox(height: 16),
                    Column(
                      children: List.generate(
                        5,
                        (index) => QuestionTile(
                          question:
                              '${index + 1}: ${provider.questionResponse?.questions[index]}',
                          selectedAnswer: answers[index],
                          onChanged: (String? value) {
                            setState(() {
                              answers[index] = value!;
                              debugPrint("Selected Answers: $answers");
                            });
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    SizedBox(
                      width: double.infinity,
                      child: Visibility(
                        visible: !provider.postLoading,
                        replacement: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryColor,
                          ),
                        ),
                        child: PrimaryButton(
                          text: 'Generate task',
                          onPressed: () async {
                            final userProvider = Provider.of<UserProvider>(
                              context,
                              listen: false,
                            );
                            await provider.answerQuestions(answers);
                            if (provider.generateTaskResponse?.success ==
                                    true &&
                                userProvider.userResponse?.data.role ==
                                    "premium") {
                              showDialog(
                                context: context,
                                builder: (_) => ItemAddedDialog(
                                  onDone: () => Navigator.popAndPushNamed(
                                    context,
                                    RouteName.parent,
                                  ),
                                  isPremium:
                                      userProvider.userResponse?.data.role ==
                                      "premium",
                                ),
                              );
                            } else {
                              showDialog(
                                context: context,
                                builder: (_) => ItemAddedDialog(
                                  onDone: () => Navigator.popAndPushNamed(
                                    context,
                                    RouteName.parent,
                                  ),
                                  isPremium:
                                      userProvider.userResponse?.data.role ==
                                      "premium",
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: Colors.black, fontSize: 12.sp),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class QuestionTile extends StatelessWidget {
  final String question;
  final String selectedAnswer;
  final ValueChanged<String?> onChanged;

  const QuestionTile({
    super.key,
    required this.question,
    required this.selectedAnswer,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question, style: TextStyle(fontSize: 14.sp)),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Yes"),
                    Radio<String>(
                      activeColor: AppColors.primaryColor,
                      value: "Yes",
                      groupValue: selectedAnswer,
                      onChanged: onChanged,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("No"),
                    Radio<String>(
                      activeColor: AppColors.primaryColor,
                      value: "No",
                      groupValue: selectedAnswer,
                      onChanged: onChanged,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
      ],
    );
  }
}
