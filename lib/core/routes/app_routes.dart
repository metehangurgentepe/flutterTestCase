enum AppRoute {
  home('/'),
  chat('/chat/:roomId');

  final String path;
  const AppRoute(this.path);
}

