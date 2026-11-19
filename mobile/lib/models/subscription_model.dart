class SubscriptionModel {
  final int id;
  final int shopId;
  final String planName;
  final double amount;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final bool trialDaysCompleted;
  final int daysRemaining;
  final int daysElapsed;
  final bool isLocked;
  final String? lockReason;

  SubscriptionModel({
    required this.id,
    required this.shopId,
    required this.planName,
    required this.amount,
    required this.status,
    this.startDate,
    this.endDate,
    required this.isActive,
    this.trialDaysCompleted = false,
    this.daysRemaining = 0,
    this.daysElapsed = 0,
    this.isLocked = false,
    this.lockReason,
  });

  bool get isTrial => planName.toLowerCase() == 'trial';

  bool get computedIsLocked {
    if (isLocked) return true;
    if (!isActive) return true;
    if (status.toUpperCase() == 'EXPIRED') return true;
    if (endDate != null && DateTime.now().isAfter(endDate!)) return true;
    return false;
  }

  bool get shouldShow14DayReminder {
    if (computedIsLocked) return false;
    if (!isTrial) return false;
    if (trialDaysCompleted) return true;
    if (startDate != null) {
      final elapsed = DateTime.now().difference(startDate!).inDays;
      return elapsed >= 14;
    }
    return false;
  }

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    final sDate = json['start_date'] != null ? DateTime.tryParse(json['start_date']) : null;
    final eDate = json['end_date'] != null ? DateTime.tryParse(json['end_date']) : null;
    final now = DateTime.now();

    final parsedElapsed = json['days_elapsed'] != null
        ? (int.tryParse(json['days_elapsed'].toString()) ?? 0)
        : (sDate != null ? now.difference(sDate).inDays.clamp(0, 365) : 0);

    final parsedRemaining = json['days_remaining'] != null
        ? (int.tryParse(json['days_remaining'].toString()) ?? 0)
        : (eDate != null && eDate.isAfter(now) ? eDate.difference(now).inDays : 0);

    final isTrialPlan = (json['plan_name'] as String? ?? 'trial').toLowerCase() == 'trial';
    final parsedTrialCompleted = json['trial_days_completed'] as bool? ?? (isTrialPlan && parsedElapsed >= 14);

    final rawIsActive = json['is_active'] as bool? ?? true;
    final rawStatus = json['status'] as String? ?? 'ACTIVE';

    final parsedLocked = json['is_locked'] as bool? ??
        (!rawIsActive || rawStatus.toUpperCase() == 'EXPIRED' || (eDate != null && now.isAfter(eDate)));

    return SubscriptionModel(
      id: json['id'] as int? ?? 1,
      shopId: json['shop_id'] as int? ?? 1,
      planName: json['plan_name'] as String? ?? 'trial',
      amount: double.tryParse(json['amount']?.toString() ?? '49.0') ?? 49.0,
      status: rawStatus,
      startDate: sDate,
      endDate: eDate,
      isActive: rawIsActive && !parsedLocked,
      trialDaysCompleted: parsedTrialCompleted,
      daysRemaining: parsedRemaining,
      daysElapsed: parsedElapsed,
      isLocked: parsedLocked,
      lockReason: json['lock_reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'plan_name': planName,
      'amount': amount,
      'status': status,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'is_active': isActive,
      'trial_days_completed': trialDaysCompleted,
      'days_remaining': daysRemaining,
      'days_elapsed': daysElapsed,
      'is_locked': isLocked,
      'lock_reason': lockReason,
    };
  }
}
