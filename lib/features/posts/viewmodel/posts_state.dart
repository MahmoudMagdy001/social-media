part of 'posts_cubit.dart';

abstract class PostsState {}

class PostsInitial extends PostsState {}

class PostsLoading extends PostsState {}

class PostsLoaded extends PostsState {
  final List<PostDataModel> posts;
  PostsLoaded(this.posts);
}

class PostsError extends PostsState {
  final String message;
  PostsError(this.message);
}
