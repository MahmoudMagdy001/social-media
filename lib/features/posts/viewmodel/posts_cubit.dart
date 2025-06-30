import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:facebook_clone/models/post_data_model.dart';
import 'package:facebook_clone/core/services/post_services/post_service.dart';

part 'posts_state.dart';

class PostsCubit extends Cubit<PostsState> {
  final PostService postService;
  final String userId;

  PostsCubit({required this.postService, required this.userId})
      : super(PostsInitial());

  Future<void> fetchPosts() async {
    emit(PostsLoading());
    try {
      final posts = await postService.getFriendsPosts(userId);
      emit(PostsLoaded(posts));
    } catch (e) {
      emit(PostsError(e.toString()));
    }
  }
}
