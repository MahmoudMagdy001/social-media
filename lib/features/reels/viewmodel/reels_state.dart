part of 'reels_cubit.dart';

abstract class ReelsState {}

class ReelsInitial extends ReelsState {}

class ReelsLoading extends ReelsState {}

class ReelsLoaded extends ReelsState {
  final List<ReelModel> reels;
  ReelsLoaded(this.reels);
}

class ReelsError extends ReelsState {
  final String message;
  ReelsError(this.message);
}
