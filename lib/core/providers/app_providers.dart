import 'package:maintenance_genie/presentation/view_models/forget_pass_provider.dart';
import 'package:maintenance_genie/presentation/view_models/login_provider.dart';
import 'package:maintenance_genie/presentation/view_models/sign_up_provider.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../di/di_configs.dart';

class AppViewModels {
  static final List<SingleChildWidget> viewModels = [
    ChangeNotifierProvider<LoginProvider>(create: (_) => getIt<LoginProvider>(),),
    ChangeNotifierProvider<SignUpProvider>(create: (_) => getIt<SignUpProvider>(),),
    ChangeNotifierProvider<ForgetPassProvider>(create: (_) => getIt<ForgetPassProvider>(),),
  ];
}