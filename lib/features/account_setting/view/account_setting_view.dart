import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../viewmodel/account_setting_cubit.dart';
import '../viewmodel/account_setting_state.dart';

class AccountSettingView extends StatelessWidget {
  const AccountSettingView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AccountSettingCubit(),
      child: BlocBuilder<AccountSettingCubit, AccountSettingState>(
        builder: (context, state) {
          if (state is AccountSettingLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is AccountSettingSuccess) {
            return const Center(child: Text("Success"));
          } else if (state is AccountSettingError) {
            return Center(child: Text(state.message));
          }

          return Scaffold(
            appBar: AppBar(title: const Text('AccountSetting')),
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  context.read<AccountSettingCubit>().example();
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
