import 'dart:io';

void main() {
  print('🧱 MVVM + Cubit Structure Generator for Flutter');

  // === 1. إدخال اسم الفيتشر ===
  stdout.write('📦 Enter feature name (e.g. auth, home): ');
  final feature = stdin.readLineSync();

  if (feature == null || feature.isEmpty) {
    print('❌ Feature name is required.');
    return;
  }

  final basePath = 'lib/features/$feature';

  // === 2. إنشاء المجلدات ===
  final directories = [
    '$basePath/model',
    '$basePath/view',
    '$basePath/viewmodel',
  ];

  for (final dir in directories) {
    final directory = Directory(dir);
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
      print('✅ Created: $dir');
    }
  }

  // === 3. إنشاء الملفات ===
  final modelFile = File('$basePath/model/${feature}_model.dart');
  final viewFile = File('$basePath/view/${feature}_view.dart');
  final cubitFile = File('$basePath/viewmodel/${feature}_cubit.dart');
  final stateFile = File('$basePath/viewmodel/${feature}_state.dart');

  final className = _capitalize(feature);

  _writeFileIfNotExists(modelFile, '''
class ${className}Model {
  // TODO: Define your model
}
''');

  _writeFileIfNotExists(stateFile, '''
abstract class ${className}State {}

class ${className}Initial extends ${className}State {}

class ${className}Loading extends ${className}State {}

class ${className}Success extends ${className}State {}

class ${className}Error extends ${className}State {
  final String message;
  ${className}Error(this.message);
}
''');

  _writeFileIfNotExists(cubitFile, '''
import 'package:flutter_bloc/flutter_bloc.dart';
import '${feature}_state.dart';

class ${className}Cubit extends Cubit<${className}State> {
  ${className}Cubit() : super(${className}Initial());

  void example() {
    emit(${className}Loading());
    emit(${className}Success());
  }
}
''');

  _writeFileIfNotExists(viewFile, '''
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../viewmodel/${feature}_cubit.dart';
import '../viewmodel/${feature}_state.dart';

class ${className}View extends StatelessWidget {
  const ${className}View({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ${className}Cubit(),
      child: BlocBuilder<${className}Cubit, ${className}State>(
        builder: (context, state) {
          if (state is ${className}Loading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ${className}Success) {
            return const Center(child: Text("Success"));
          } else if (state is ${className}Error) {
            return Center(child: Text(state.message));
          }

          return Scaffold(
            appBar: AppBar(title: const Text('$className')),
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  context.read<${className}Cubit>().example();
                },
                child: const Text('Trigger Example'),
              ),
            ),
          );
        },
      ),
    );
  }
}
''');

  // === 4. إنشاء ملفات utils ===
  final utilsDir = Directory('lib/utlis');
  if (!utilsDir.existsSync()) {
    utilsDir.createSync(recursive: true);
    print('✅ Created: lib/utlis');
  }

  final navHelperFile = File('lib/utlis/navigation_helper.dart');
  _writeFileIfNotExists(navHelperFile, _navigationHelperContent());

  final retryHelperFile = File('lib/utlis/retry_helper.dart');
  _writeFileIfNotExists(retryHelperFile, _retryHelperContent());

  // === 5. تم! ===
  print('\n📂 Folder structure created under lib/features/$feature');
  print('📁 navigation_helper.dart & retry_helper.dart created in lib/utlis/');
  print(
    '🎉 Feature "$feature" with Cubit MVVM structure created successfully!',
  );
}

String _capitalize(String s) =>
    s.split('_').map((e) => e[0].toUpperCase() + e.substring(1)).join();

void _writeFileIfNotExists(File file, String content) {
  if (!file.existsSync()) {
    file.writeAsStringSync(content);
    print('📝 Created file: ${file.path}');
  } else {
    print('⚠️  File already exists: ${file.path}');
  }
}

String _navigationHelperContent() => '''
import 'package:flutter/material.dart';

enum TransitionType { slideFromBottom, fade, scale }

Future<T?> navigateWithTransition<T>(
  BuildContext context,
  Widget page, {
  TransitionType type = TransitionType.slideFromBottom,
  Duration duration = const Duration(milliseconds: 400),
}) {
  return Navigator.of(context).push<T>(
    PageRouteBuilder(
      transitionDuration: duration,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        switch (type) {
          case TransitionType.fade:
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          case TransitionType.scale:
            return ScaleTransition(
              scale: animation,
              child: child,
            );
          case TransitionType.slideFromBottom:
            final tween = Tween(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).chain(
              CurveTween(
                curve: Curves.ease,
              ),
            );
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
        }
      },
    ),
  );
}
''';

String _retryHelperContent() => '''
import 'package:flutter/material.dart';

Future<T> executeWithRetry<T>(
  Future<T> Function() operation, {
  required int maxRetries,
  required Duration retryDelay,
}) async {
  int retryCount = 0;
  while (retryCount < maxRetries) {
    try {
      return await operation();
    } catch (e) {
      retryCount++;
      if (retryCount == maxRetries) {
        debugPrint('Operation failed after \$maxRetries attempts: \$e');
        rethrow;
      }
      await Future.delayed(retryDelay * retryCount);
    }
  }
  throw Exception('Operation failed after \$maxRetries attempts');
}
''';
