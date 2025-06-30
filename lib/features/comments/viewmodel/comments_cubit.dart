import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:facebook_clone/models/comments_model.dart';
import 'package:facebook_clone/core/services/post_services/post_service.dart';

part 'comments_state.dart';

class CommentsCubit extends Cubit<CommentsState> {
  final PostService postService;
  final String postId;
  final dynamic user;

  CommentsCubit(
      {required this.postService, required this.postId, required this.user})
      : super(CommentsInitial());

  Future<void> addComment(String commentText) async {
    emit(CommentsLoading());
    try {
      await postService.addCommentToPost(
          postId: postId, commentText: commentText, user: user);
      emit(CommentsAdded());
      fetchComments();
    } catch (e) {
      emit(CommentsError(e.toString()));
    }
  }

  Future<void> fetchComments() async {
    emit(CommentsLoading());
    try {
      final commentsStream = postService.getCommentsForPost(postId: postId);
      emit(CommentsLoaded(commentsStream));
    } catch (e) {
      emit(CommentsError(e.toString()));
    }
  }
}
