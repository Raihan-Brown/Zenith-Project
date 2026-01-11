//// lib/domain/entities/user_entity.dart
import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String nis;
  final String name;
  final String role; // 'USER' or 'ADMIN'
  final int points;

  const UserEntity({
    required this.nis,
    required this.name,
    required this.role,
    this.points = 0,
  });

  @override
  List<Object?> get props => [nis, name, role, points];
}