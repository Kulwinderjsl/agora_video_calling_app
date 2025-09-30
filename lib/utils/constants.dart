class AppConstants {
  // App Info
  static const String appName = 'VideoCall App';
  static const String appVersion = '1.0.0';

  // API Constants

  static const String baseUrl = 'https://jsonplaceholder.typicode.com';
  static const String endPoint = '/users';

  // Agora Configuration
  static const String agoraAppId =
      '8d061ddc32104022b14e31afbd145aa5'; // Replace with actual App ID
  static const String defaultChannelName = 'test123';

  static const String tempToken ='007eJxTYNjRsb6OPfm7ekP/VTMZGcHL7yqCZh+ZrFBkcrbjY+EdNRcFBosUAzPDlJRkYyNDAxMDI6MkQ5NUY8PEtKQUQxPTxERT1Ve3MxoCGRmWXa1gZmSAQBCfnaEktbjE0MiYgQEAt6IgwA==';
      }

class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String home = '/home';
  static const String videoCall = '/video-call';
  static const String users = '/users';
}

class AppStrings {
  static const String invalidEmail = 'Please enter a valid email';
  static const String emptyField = 'This field cannot be empty';
  static const String noInternet = 'No internet connection';
}
