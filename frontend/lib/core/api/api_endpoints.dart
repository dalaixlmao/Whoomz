class ApiEndpoints {
  static const String signup = '/auth/signup';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refresh = '/auth/refresh';
  static const String chat = '/chat/';
  static const String foodLogs = '/food-logs/';
  static const String weightLogs = '/weight-logs/';
  static const String workouts = '/workouts/';

  static String dailyNote(String date) => '/daily-notes/$date';
}
