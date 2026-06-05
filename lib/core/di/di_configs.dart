import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import '../../data/repository/auth_repository_impl.dart';
import '../../domain/base_repository/auth_repository.dart';
import '../../presentation/view_models/login_provider.dart';
import '../services/api/api_service.dart';

final GetIt getIt = GetIt.instance;

Future<void> diConfig() async {
  // Core Services
  getIt.registerLazySingleton<Dio>(() => Dio());
  getIt.registerLazySingleton<ApiService>(() => ApiService());

  // ===== Repository =====
  getIt.registerLazySingleton<AuthRepository>(
        () => AuthRepositoriesImpl(getIt<ApiService>()),
  );


  // ===== Providers =====
  getIt.registerFactory<LoginProvider>(
        () => LoginProvider(getIt<AuthRepository>()),
  );


  // ===== Simple Providers =====
  // getIt.registerLazySingleton<ParentScreenProvider>(
  //       () => ParentScreenProvider(),
  // );
}