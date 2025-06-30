part of 'comments_cubit.dart';

abstract class CommentsState {}

class CommentsInitial extends CommentsState {}

class CommentsLoading extends CommentsState {}

class CommentsAdded extends CommentsState {}

class CommentsLoaded extends CommentsState {
  final Stream<List<CommentModel>> commentsStream;
  CommentsLoaded(this.commentsStream);
}

class CommentsError extends CommentsState {
  final String message;
  CommentsError(this.message);
}
