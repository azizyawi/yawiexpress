class CurrentUser {
  final String userId;
  final String? phoneNumber;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? referralCode;
  final String? referredByCode;
  final String? referredByUserId;
  final int wanBucksBalance;
  final bool referralRewardApplied;
  final String? createdAt;

  const CurrentUser({
    required this.userId,
    this.phoneNumber,
    this.firstName,
    this.lastName,
    this.email,
    this.referralCode,
    this.referredByCode,
    this.referredByUserId,
    required this.wanBucksBalance,
    required this.referralRewardApplied,
    this.createdAt,
  });

  factory CurrentUser.fromMap(Map<String, dynamic> map) {
    return CurrentUser(
      userId: (map['userId'] ?? '').toString(),
      phoneNumber: map['phoneNumber']?.toString(),
      firstName: map['firstName']?.toString(),
      lastName: map['lastName']?.toString(),
      email: map['email']?.toString(),
      referralCode: map['referralCode']?.toString(),
      referredByCode: map['referredByCode']?.toString(),
      referredByUserId: map['referredByUserId']?.toString(),
      wanBucksBalance: map['wanBucksBalance'] is int
          ? map['wanBucksBalance'] as int
          : int.tryParse((map['wanBucksBalance'] ?? '0').toString()) ?? 0,
      referralRewardApplied: map['referralRewardApplied'] == true,
      createdAt: map['createdAt']?.toString(),
    );
  }
}
