import 'package:equatable/equatable.dart';
import '../errors/failures.dart';

abstract class UseCase<Type, Params> {
  Future<({Failure? failure, Type? data})> call(Params params);
}

class NoParams extends Equatable {
  @override
  List<Object> get props => [];
}
