// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:provider/provider.dart';
//
// class SignUpScreen extends StatefulWidget {
//   const SignUpScreen({super.key});
//
//   @override
//   State<SignUpScreen> createState() => _SignUpScreenState();
// }
//
// class _SignUpScreenState extends State<SignUpScreen> {
//
//   final TextEditingController emailController = TextEditingController();
//   final FocusNode _focusNode = FocusNode();
//
//   @override
//   void dispose() {
//     super.dispose();
//     emailController.dispose();
//     _focusNode.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Color(0xffFFFFFF),
//       body: SafeArea(
//         child: Padding(
//           padding: EdgeInsets.symmetric(horizontal: 20),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               SizedBox(height: 40),
//               Row(
//                 children: [
//                   Image.asset("assets/images/brand.png"),
//                   SizedBox(width: 8),
//                   Text(
//                     "Maintenance\nGenie",
//                     style: TextStyle(
//                       color: Color(0xff023455),
//                       fontSize: 26,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   Spacer(),
//                 ],
//               ),
//               SizedBox(height: 18),
//               Text(
//                 "Create Your Account",
//                 style: TextStyle(
//                   color: Color(0xff1D1F2C),
//                   fontSize: 20,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               SizedBox(height: 20),
//               Text(
//                 "Email",
//                 style: TextStyle(
//                   color: Color(0xff1D1F2C),
//                   fontWeight: FontWeight.w400,
//                   fontSize: 14,
//                 ),
//               ),
//               SizedBox(height: 8),
//               CustomTextField(
//                 controller: emailController,
//                 hintText: "Enter your email",
//                 keyboardType: TextInputType.emailAddress,
//                 inputFormatters: [
//                   FilteringTextInputFormatter.deny(RegExp(r'\s')),
//                 ], // Disallow spaces
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter an email address';
//                   }
//                   return null;
//                 },
//                 focusNode: _focusNode,
//               ),
//               SizedBox(height: 20),
//               SizedBox(
//                 width: MediaQuery.of(context).size.width * 0.9,
//                 child: Consumer<SignUpScreenProvider>(
//                   builder: (context, provider, child) {
//                     return Visibility(
//                       visible: !provider.isSULoading,
//                       replacement: const Center(
//                         child: CircularProgressIndicator(),
//                       ),
//                       child: PrimaryButton(
//                         text: "Verify",
//                         onPressed: () async {
//                           // Add logging to track progress
//                           print("Email entered: ${emailController.text}");
//
//                           final res = await provider.getEmailVerification(
//                             emailController.text,
//                           );
//                           print("Verification result: $res");
//
//                           if (res) {
//                             Navigator.pushNamed(
//                               context,
//                               RouteName.otpScreen,
//                               arguments: emailController.text,
//                             );
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               SnackBar(content: Text(provider.errorMessage)),
//                             );
//                           } else {
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               SnackBar(content: Text(provider.errorMessage)),
//                             );
//                           }
//                         },
//                       ),
//                     );
//                   },
//                 ),
//               ),
//               SizedBox(height: 12),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.start,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Checkbox(value: true, onChanged: (value) {}),
//                   Expanded(
//                     child: Text(
//                       "By proceeding, you accept Maintenance\nGenie Terms of Service and acknowledge reading its Privacy Policy.",
//                       style: TextStyle(
//                         color: Color(0xff1D1F2C),
//                         fontWeight: FontWeight.w400,
//                         fontSize: 16,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
