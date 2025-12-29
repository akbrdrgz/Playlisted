// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, implicit_dynamic_list_literal

import 'dart:io';

import 'package:dart_frog/dart_frog.dart';


import '../routes/index.dart' as index;
import '../routes/Users/index.dart' as users_index;
import '../routes/Users/[id].dart' as users_$id;
import '../routes/UserGames/index.dart' as user_games_index;
import '../routes/UserAchievements/index.dart' as user_achievements_index;
import '../routes/Reviews/index.dart' as reviews_index;
import '../routes/Reviews/[id].dart' as reviews_$id;
import '../routes/Games/index.dart' as games_index;
import '../routes/Feats/index.dart' as feats_index;

import '../routes/_middleware.dart' as middleware;

void main() async {
  final address = InternetAddress.tryParse('') ?? InternetAddress.anyIPv6;
  final port = int.tryParse(Platform.environment['PORT'] ?? '8080') ?? 8080;
  hotReload(() => createServer(address, port));
}

Future<HttpServer> createServer(InternetAddress address, int port) {
  final handler = Cascade().add(buildRootHandler()).handler;
  return serve(handler, address, port);
}

Handler buildRootHandler() {
  final pipeline = const Pipeline().addMiddleware(middleware.middleware);
  final router = Router()
    ..mount('/Feats', (context) => buildFeatsHandler()(context))
    ..mount('/Games', (context) => buildGamesHandler()(context))
    ..mount('/Reviews', (context) => buildReviewsHandler()(context))
    ..mount('/UserAchievements', (context) => buildUserAchievementsHandler()(context))
    ..mount('/UserGames', (context) => buildUserGamesHandler()(context))
    ..mount('/Users', (context) => buildUsersHandler()(context))
    ..mount('/', (context) => buildHandler()(context));
  return pipeline.addHandler(router);
}

Handler buildFeatsHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/', (context) => feats_index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildGamesHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/', (context) => games_index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildReviewsHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/', (context) => reviews_index.onRequest(context,))..all('/<id>', (context,id,) => reviews_$id.onRequest(context,id,));
  return pipeline.addHandler(router);
}

Handler buildUserAchievementsHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/', (context) => user_achievements_index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildUserGamesHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/', (context) => user_games_index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildUsersHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/', (context) => users_index.onRequest(context,))..all('/<id>', (context,id,) => users_$id.onRequest(context,id,));
  return pipeline.addHandler(router);
}

Handler buildHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/', (context) => index.onRequest(context,));
  return pipeline.addHandler(router);
}

