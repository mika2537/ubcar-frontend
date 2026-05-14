enum TripStateEnum {
  requested,
  accepted,
  arriving,
  inProgress,
  completed,
  cancelled,
}

extension TripStateExtension on TripStateEnum {
  bool canTransitionTo(TripStateEnum nextState) {
    const validTransitions = {
      TripStateEnum.requested: [
        TripStateEnum.accepted,
        TripStateEnum.cancelled,
      ],
      TripStateEnum.accepted: [TripStateEnum.arriving, TripStateEnum.cancelled],
      TripStateEnum.arriving: [
        TripStateEnum.inProgress,
        TripStateEnum.cancelled,
      ],
      TripStateEnum.inProgress: [TripStateEnum.completed],
      TripStateEnum.completed: <TripStateEnum>[],
      TripStateEnum.cancelled: <TripStateEnum>[],
    };

    return validTransitions[this]?.contains(nextState) ?? false;
  }
}
