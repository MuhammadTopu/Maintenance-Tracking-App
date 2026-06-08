import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:maintenance_genie/presentation/view_models/user_provider.dart';
import 'package:provider/provider.dart';

import '../../../../shared/common_widgets.dart';
import '../../../../shared/custom_item_app_bar.dart';
import '../../../../shared/custom_text_field.dart';

class Security extends StatefulWidget {
  const Security({super.key});

  @override
  State<Security> createState() => _SecurityState();
}

class _SecurityState extends State<Security> {

  final TextEditingController currentPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final provider = context.read<UserProvider>();
    final state = context.watch<UserProvider>();
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(8.0),
                child: CustomItemAppBar(
                  title: 'Security',
                  onTap: Navigator.of(context).pop,
                ),
              ),
              const Divider(color: Color(0xffE9E9EA)),
              const SizedBox(height: 20),
              Text(
                "Current Password",
                style: TextStyle(
                  color: Color(0xff1D1F2C),
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              CustomTextField(
                controller: currentPasswordController,
                hintText: "Enter current your password",
                obscureText: state.current,
                suffixIcon: IconButton(
                  onPressed: () => provider.toggle('current'),
                  icon: Icon(
                    state.current
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "New Password",
                style: TextStyle(
                  color: Color(0xff1D1F2C),
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              CustomTextField(
                controller: newPasswordController,
                hintText: "Enter your password",
                onChanged: (value) {
                  provider.validatePassword(value);
                },
                obscureText: state.newPassword,
                suffixIcon: IconButton(
                  onPressed: () => provider.toggle('new'),
                  icon: Icon(
                    state.newPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                "Confirm Password",
                style: TextStyle(
                  color: Color(0xff1D1F2C),
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              CustomTextField(
                controller: confirmPasswordController,
                hintText: "Confirm your password",
                obscureText: state.confirm,
                suffixIcon: IconButton(
                  onPressed: () => provider.toggle('confirm'),
                  icon: Icon(
                    state.confirm
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: PrimaryButton(text: "Save", onPressed: () {}),
              ),
              SizedBox(height: 20.h,)
            ],
          ),
        ),
      ),
    );
  }
}
