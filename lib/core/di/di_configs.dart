import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:maintenance_genie/data/repository/item_and_task_list_repository_impl.dart';
import 'package:maintenance_genie/data/repository/support_mail_repository_impl.dart';
import 'package:maintenance_genie/domain/base_repository/add_items_repository.dart';
import 'package:maintenance_genie/domain/base_repository/item_and_task_list_repository.dart';
import 'package:maintenance_genie/domain/base_repository/support_mail_repository.dart';
import 'package:maintenance_genie/presentation/view_models/add_item_provider.dart';
import 'package:maintenance_genie/presentation/view_models/add_receipt_provider.dart';
import 'package:maintenance_genie/presentation/view_models/forget_pass_provider.dart';
import 'package:maintenance_genie/presentation/view_models/item_task_list_by_item_id_provider.dart';
import 'package:maintenance_genie/presentation/view_models/parent_screen_provider.dart';
import 'package:maintenance_genie/presentation/view_models/question_provider.dart';
import 'package:maintenance_genie/presentation/view_models/sign_up_provider.dart';
import 'package:maintenance_genie/presentation/view_models/support_mail_provider.dart';
import '../../data/repository/add_items_repository_impl.dart';
import '../../data/repository/auth_repository_impl.dart';
import '../../domain/base_repository/auth_repository.dart';
import '../../presentation/view_models/all_item_list_provider.dart';
import '../../presentation/view_models/item_task_list_provider.dart';
import '../../presentation/view_models/login_provider.dart';
import '../../presentation/view_models/user_provider.dart';
import '../services/api/api_service.dart';

final GetIt getIt = GetIt.instance;

Future<void> diConfig() async {
  // Core Services
  getIt.registerLazySingleton<Dio>(() => Dio());
  getIt.registerLazySingleton<ApiService>(() => ApiService());

  // ===== Repository =====
  getIt.registerLazySingleton<AuthRepository>(() => AuthRepositoriesImpl(getIt<ApiService>()),);
  getIt.registerLazySingleton<ItemAndTaskListRepository>(() => ItemAndTaskListRepositoryImpl(getIt<ApiService>()),);
  getIt.registerLazySingleton<AddItemRepository>(() => AddItemRepositoryImpl());
  getIt.registerLazySingleton<SupportMailRepository>(() => SupportMailRepositoryImpl(getIt<ApiService>()),);


  // ===== Providers =====
  getIt.registerFactory<LoginProvider>(() => LoginProvider(getIt<AuthRepository>()),);
  getIt.registerFactory<SignUpProvider>(() => SignUpProvider(getIt<AuthRepository>()),);
  getIt.registerFactory<ForgetPassProvider>(() => ForgetPassProvider(getIt<AuthRepository>()),);
  getIt.registerFactory<AllItemListProvider>(() => AllItemListProvider(getIt<ItemAndTaskListRepository>()),);
  getIt.registerFactory<ItemTaskListProvider>(() => ItemTaskListProvider(getIt<ItemAndTaskListRepository>()),);
  getIt.registerFactory<ItemTaskListByItemIdProvider>(() => ItemTaskListByItemIdProvider(getIt<ItemAndTaskListRepository>()),);
  getIt.registerFactory<AddItemProvider>(() => AddItemProvider(getIt<AddItemRepository>()),);
  getIt.registerFactory<SupportMailProvider>(() => SupportMailProvider(getIt<SupportMailRepository>()),);
  getIt.registerFactory<UserProvider>(() => UserProvider(getIt<AuthRepository>()),);
  getIt.registerFactory<QuestionProvider>(() => QuestionProvider());
  getIt.registerFactory<AddReceiptProvider>(() => AddReceiptProvider());


  // ===== Simple Providers =====
  getIt.registerLazySingleton<ParentScreensProvider>(() => ParentScreensProvider(),);
}