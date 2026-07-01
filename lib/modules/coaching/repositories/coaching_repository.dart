import 'package:soccer_sys/core/errors/failure.dart';
import 'package:soccer_sys/core/errors/failure_mapper.dart';
import 'package:soccer_sys/modules/auth/models/user_model.dart';
import 'package:soccer_sys/modules/auth/models/user_role.dart';
import 'package:soccer_sys/modules/chat/models/chat_room_model.dart';
import 'package:soccer_sys/modules/coaching/services/coaching_service.dart';

class CoachingRepository {
  CoachingRepository(this._coachingService);

  final CoachingService _coachingService;

  Future<({Failure? failure, UserModel? user})> assignTrainer(
    String trainerId,
  ) async {
    try {
      final data = await _coachingService.assignTrainer(trainerId);
      return (failure: null, user: UserModel.fromJson(data));
    } catch (error) {
      return (failure: FailureMapper.fromException(error), user: null);
    }
  }

  Future<({Failure? failure, ChatPeerModel? trainer})> fetchMyTrainer() async {
    try {
      final data = await _coachingService.fetchMyTrainer();
      if (data == null) {
        return (failure: null, trainer: null);
      }
      return (
        failure: null,
        trainer: _profileToPeer(data),
      );
    } catch (error) {
      return (failure: FailureMapper.fromException(error), trainer: null);
    }
  }

  Future<({Failure? failure, List<UserModel> trainees})> fetchMyTrainees() async {
    try {
      final data = await _coachingService.fetchMyTrainees();
      final trainees = data.map(UserModel.fromJson).toList();
      return (failure: null, trainees: trainees);
    } catch (error) {
      return (
        failure: FailureMapper.fromException(error),
        trainees: <UserModel>[],
      );
    }
  }

  Future<({Failure? failure, UserModel? trainee})> fetchTraineeById(
    String traineeId,
  ) async {
    try {
      final data = await _coachingService.fetchTraineeProfile(traineeId);
      if (data == null) {
        return (failure: null, trainee: null);
      }
      return (failure: null, trainee: UserModel.fromJson(data));
    } catch (error) {
      return (failure: FailureMapper.fromException(error), trainee: null);
    }
  }

  Future<({Failure? failure, List<ChatPeerModel> trainers})>
      listAvailableTrainers() async {
    try {
      final data = await _coachingService.listAvailableTrainers();
      final trainers = data.map(_profileToPeer).toList();
      return (failure: null, trainers: trainers);
    } catch (error) {
      return (
        failure: FailureMapper.fromException(error),
        trainers: <ChatPeerModel>[],
      );
    }
  }

  ChatPeerModel _profileToPeer(Map<String, dynamic> json) {
    return ChatPeerModel(
      id: json['id'] as String,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      role: UserRole.fromString(json['role'] as String),
    );
  }
}
