import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_calling_app/utils/app_themes.dart';

import 'bloc/auth/auth_bloc.dart';
import 'bloc/users/user_bloc.dart';
import 'bloc/video_call/video_call_bloc.dart';
import 'data/repositories/user_repository.dart';
import 'data/services/agora_service.dart';
import 'data/services/local_storage_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/users/users_screen.dart';
import 'screens/video_call/video_call_screen.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorageService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => UserRepository()),
        RepositoryProvider(create: (context) => AgoraService()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(create: (context) => AuthBloc()),
          BlocProvider<VideoCallBloc>(
            create: (context) {
              final agoraService = context.read<AgoraService>();
              final bloc = VideoCallBloc(agoraService: agoraService);
              agoraService.setVideoCallBloc(bloc);
              return bloc;
            },
          ),
          BlocProvider(
            create: (context) =>
                UserListBloc(userRepository: context.read<UserRepository>())
                  ..add(const FetchUsers()),
          ),
        ],
        child: MaterialApp(
          title: AppConstants.appName,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          initialRoute: AppRoutes.splash,
          routes: {
            AppRoutes.splash: (context) => const SplashScreen(),
            AppRoutes.login: (context) => const LoginScreen(),
            AppRoutes.home: (context) => const HomeScreen(),
            AppRoutes.videoCall: (context) => const VideoCallScreen(),
            AppRoutes.users: (context) => const UserListScreen(),
          },
          debugShowCheckedModeBanner: false,
          onGenerateRoute: (settings) {
            return MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: Center(child: Text('Route ${settings.name} not found')),
              ),
            );
          },
        ),
      ),
    );
  }
}
