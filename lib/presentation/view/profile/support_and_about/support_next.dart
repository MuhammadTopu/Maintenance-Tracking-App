import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../shared/common_widgets.dart';
import '../../../../shared/custom_item_app_bar.dart';
import '../../../view_models/support_mail_provider.dart';

class SupportNext extends StatefulWidget {
  const SupportNext({super.key});

  @override
  State<SupportNext> createState() => _SupportNextState();
}

class _SupportNextState extends State<SupportNext> {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  void _showSubmissionDialog(BuildContext context, String tokenNumber) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          contentPadding: const EdgeInsets.all(12.0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '🎉', // Confetti emoji
                style: TextStyle(fontSize: 50),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your message has been submitted.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  text: 'Your Token number is ',
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                  children: <TextSpan>[
                    TextSpan(
                      text: tokenNumber,
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _subjectController.clear();
                    _messageController.clear();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Container(
          color: Colors.white, // Set the background color to white here
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CustomItemAppBar(
                    title: 'Support',
                    onTap: Navigator.of(context).pop,
                  ),
                ),
                SizedBox(height: 8.h),
                Divider(color: Color(0xffE9E9EA), thickness: 1),
                SizedBox(height: 20),
                const Align(
                  alignment: Alignment.topLeft,
                  child: Text('Type Subject', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _subjectController,
                  decoration: InputDecoration(
                    hintText: 'Type Subject',
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.topLeft,
                  child: Text('Message', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _messageController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Type Message',
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Colors.grey, // Grey border
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  child: Consumer<SupportMailProvider>(
                    builder: (_, provider, _) {
                      return Visibility(
                        visible: !provider.isLoading,
                        replacement: const Center(
                          child: CircularProgressIndicator(),
                        ),
                        child: PrimaryButton(
                          text: "Save",
                          onPressed: () async {
                            if (_subjectController.text.isEmpty || _messageController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please fill all fields'),
                                ),
                              );
                              return;
                            }
                            final rs = await provider.sendSupportMail(_subjectController.text, _messageController.text);
                            if (rs) {
                              _showSubmissionDialog(context, provider.supportMailToken);
                            }
                          },
                        ),
                      );
                    }
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
