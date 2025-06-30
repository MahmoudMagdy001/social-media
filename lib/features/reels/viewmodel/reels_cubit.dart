import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:facebook_clone/models/reels_model.dart';
import 'package:facebook_clone/core/services/post_services/post_service.dart';

part 'reels_state.dart';

class ReelsCubit extends Cubit<ReelsState> {
  final PostService postService;
  final String userId;

  ReelsCubit({required this.postService, required this.userId})
      : super(ReelsInitial());

  Future<void> fetchReels() async {
    emit(ReelsLoading());
    try {
      final reels = await postService.getReels();
      emit(ReelsLoaded(reels));
    } catch (e) {
      emit(ReelsError(e.toString()));
    }
  }
}
