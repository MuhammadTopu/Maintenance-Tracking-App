import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/custom_item_app_bar.dart';

class FrequentlyAskedQuestions extends StatefulWidget {
  const FrequentlyAskedQuestions({super.key});

  @override
  State<FrequentlyAskedQuestions> createState() =>
      _FrequentlyAskedQuestionsState();
}

class _FrequentlyAskedQuestionsState extends State<FrequentlyAskedQuestions> {
  final List<Map<String, String>> _faqs = [
    {
      'question': 'How does this app work?',
      'answer':
          'By using Maintenance Genie, you agree to the following terms. Please read them carefully.',
    },
    {
      'question': 'Is the app free to use?',
      'answer':
          'The basic features of the app are free to use. Premium features require a subscription.',
    },
    {
      'question': 'How do reminders work?',
      'answer':
          'Reminders are set based on your asset\'s service intervals and your preferences. You will receive notifications for upcoming maintenance.',
    },
    {
      'question': 'Can I track multiple vehicles or items?',
      'answer':
          'Yes, Maintenance Genie allows you to add and track multiple assets, including vehicles, homes, and other equipment.',
    },
    {
      'question': 'What\'s included in Premium?',
      'answer':
          'Premium features include advanced service provider suggestions, access to the maintenance forum, and more personalized experience.',
    },
    {
      'question': 'How do I cancel my Premium subscription?',
      'answer':
          'You can cancel your Premium subscription through your account settings within the app or via your app store subscription management.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Container(
          color: Colors.white,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CustomItemAppBar(
                    title: 'Frequently Asked Question',
                    onTap: Navigator.of(context).pop,
                  ),
                ),
                SizedBox(height: 8.h),
                Divider(color: Color(0xffE9E9EA), thickness: 1),
                SizedBox(height: 20),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _faqs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade300,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Card(
                          color: Colors.white,
                          elevation: 0,
                          margin: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(
                              horizontal: 0,
                              vertical: 8,
                            ),
                            title: Text(
                              _faqs[index]['question']!,
                              style: const TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 16.0,
                                  right: 16.0,
                                  bottom: 8.0,
                                ),
                                child: Align(
                                  alignment: Alignment.topLeft,
                                  child: Text(
                                    _faqs[index]['answer']!,
                                    style: const TextStyle(
                                      fontSize: 14.0,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
