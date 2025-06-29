import 'package:facebook_clone/core/consts/theme.dart';
import 'package:facebook_clone/features/layout/view/layout_view.dart';
import 'package:facebook_clone/features/layout/viewmodel/layout_cubit.dart';
import 'package:facebook_clone/features/signin/view/signin_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/utlis/app_bloc_observer.dart';
import 'features/menu/viewmodel/theme_cubit.dart';
import 'features/menu/viewmodel/theme_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    const String databaseUrl = 'https://ikybwhywdnsrzvcbgrwj.supabase.co';
    const String anonKey =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlreWJ3aHl3ZG5zcnp2Y2JncndqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkyNDg5NDgsImV4cCI6MjA2NDgyNDk0OH0.oav7OQZVjc9Nvc4nJsFckyl0iz0EHIYn92bBbEF5DTk';

    await Supabase.initialize(url: databaseUrl, anonKey: anonKey);
    debugPrint('Supabase initialized successfully');
  } catch (e) {
    debugPrint('Failed to initialize Supabase: $e');
  }

  Bloc.observer = AppBlocObserver();

  final session = Supabase.instance.client.auth.currentSession;
  final Widget initialScreen =
      session != null ? const LayoutView() : const SigninView();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(create: (_) => LayoutCubit()..getUser()),
      ],
      child: MyApp(initialScreen: initialScreen),
    ),
  );
}

class MyApp extends StatelessWidget {
  final Widget? initialScreen;

  const MyApp({super.key, this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeState.themeMode,
          home: initialScreen,
        );
      },
    );
  }
}
