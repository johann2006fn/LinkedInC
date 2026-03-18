import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final String role; // 'student' or 'mentor'
  final String? profileImageUrl;
  final String? subtitle;
  final List<String> tags;
  final String? experience;
  final String? mentees;
  final String? collegeCode;
  // Fields for Gemini matchmaking
  final String? bio;
  final List<String> skills;
  final List<String> interests;
  final List<String> goals;
  final String? department;
  final String? year; // e.g. 'Class of 2026' or '3rd year'
  final int? yearsOfExperience; // Explicit years of experience integer
  final List<String> savedMentors; // List of mentor IDs saved by the user
  final int matchScore; // computed field or stored
  final String? matchReason; // AI generated reason

  // Onboarding & preferences fields
  final bool isProfileComplete;
  final String? gender;
  final Map<String, dynamic>? preferences; // {connectWith, communicationStyle}
  final DateTime? onboardingCompletedAt;

  // Mentor-specific fields
  final bool acceptingMentees;
  final int maxMentees;

  // Social proof
  final List<String> reviews;

  // Vector embedding for semantic matchmaking
  final List<double>? profileEmbedding;

  // Online presence
  final bool isOnline;
  final DateTime? lastSeen;
  final String?
  availabilityStatus; // e.g. 'Available tonight', 'Away till Monday'
  final int sessionsCompleted;
  final Map<String, int> endorsements;
  final bool isVerifiedCollegeUser;
  final String? identityId;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.profileImageUrl,
    this.subtitle,
    this.tags = const [],
    this.experience,
    this.mentees,
    this.collegeCode,
    this.bio,
    this.skills = const [],
    this.interests = const [],
    this.goals = const [],
    this.department,
    this.year,
    this.yearsOfExperience,
    this.matchScore = 0,
    this.matchReason,
    this.isProfileComplete = false,
    this.gender,
    this.preferences,
    this.onboardingCompletedAt,
    this.acceptingMentees = false,
    this.maxMentees = 3,
    this.reviews = const [],
    this.profileEmbedding,
    this.isOnline = false,
    this.lastSeen,
    this.savedMentors = const [],
    this.availabilityStatus,
    this.sessionsCompleted = 0,
    this.endorsements = const {},
    this.isVerifiedCollegeUser = false,
    this.identityId,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return AppUser(
      id: doc.id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: data['role'] as String? ?? 'student',
      profileImageUrl: data['profileImageUrl'] as String?,
      subtitle: data['subtitle'] as String?,
      tags: (data['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      experience: data['experience'] as String?,
      mentees: data['mentees'] as String?,
      collegeCode: data['collegeCode'] as String?,
      bio: data['bio'] as String?,
      skills:
          (data['skills'] as List?)?.map((e) => e.toString()).toList() ?? [],
      interests:
          (data['interests'] as List?)?.map((e) => e.toString()).toList() ?? [],
      goals: (data['goals'] as List?)?.map((e) => e.toString()).toList() ?? [],
      department: data['department'] as String?,
      year: data['year'] as String?,
      yearsOfExperience: data['yearsOfExperience'] as int?,
      isProfileComplete: data['isProfileComplete'] as bool? ?? false,
      gender: data['gender'] as String?,
      preferences: data['preferences'] is Map
          ? Map<String, dynamic>.from(data['preferences'] as Map)
          : null,
      onboardingCompletedAt: (data['onboardingCompletedAt'] as Timestamp?)
          ?.toDate(),
      acceptingMentees: data['acceptingMentees'] as bool? ?? false,
      maxMentees: data['maxMentees'] as int? ?? 3,
      reviews:
          (data['reviews'] as List?)?.map((e) => e.toString()).toList() ?? [],
      profileEmbedding: (data['profileEmbedding'] as List?)
          ?.map((e) => (e as num?)?.toDouble() ?? 0.0)
          .toList(),
      isOnline: data['isOnline'] as bool? ?? false,
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate(),
      savedMentors:
          (data['savedMentors'] as List?)?.map((e) => e.toString()).toList() ??
          [],
      availabilityStatus: data['availabilityStatus'] as String?,
      sessionsCompleted: data['sessionsCompleted'] as int? ?? 0,
      endorsements: Map<String, int>.from(data['endorsements'] ?? {}),
      isVerifiedCollegeUser: data['isVerifiedCollegeUser'] as bool? ?? false,
      identityId: data['identityId'] as String?,
      matchScore: data['matchScore'] as int? ?? data['match_score'] as int? ?? 0,
      matchReason: data['matchReason'] as String? ?? data['match_reason'] as String?,
    );
  }

  factory AppUser.fromMap(Map<String, dynamic>? rawData, String id) {
    final data = rawData ?? {};
    return AppUser(
      id: id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: data['role'] as String? ?? 'student',
      profileImageUrl: data['profileImageUrl'] as String?,
      subtitle: data['subtitle'] as String?,
      tags: (data['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      experience: data['experience'] as String?,
      mentees: data['mentees'] as String?,
      collegeCode: data['collegeCode'] as String?,
      bio: data['bio'] as String?,
      skills:
          (data['skills'] as List?)?.map((e) => e.toString()).toList() ?? [],
      interests:
          (data['interests'] as List?)?.map((e) => e.toString()).toList() ?? [],
      goals: (data['goals'] as List?)?.map((e) => e.toString()).toList() ?? [],
      department: data['department'] as String?,
      year: data['year'] as String?,
      yearsOfExperience: data['yearsOfExperience'] as int?,
      isProfileComplete: data['isProfileComplete'] as bool? ?? false,
      gender: data['gender'] as String?,
      preferences: data['preferences'] is Map
          ? Map<String, dynamic>.from(data['preferences'] as Map)
          : null,
      onboardingCompletedAt: (data['onboardingCompletedAt'] as Timestamp?)
          ?.toDate(),
      acceptingMentees: data['acceptingMentees'] as bool? ?? false,
      maxMentees: data['maxMentees'] as int? ?? 3,
      reviews:
          (data['reviews'] as List?)?.map((e) => e.toString()).toList() ?? [],
      profileEmbedding: (data['profileEmbedding'] as List?)
          ?.map((e) => (e as num?)?.toDouble() ?? 0.0)
          .toList(),
      isOnline: data['isOnline'] as bool? ?? false,
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate(),
      savedMentors:
          (data['savedMentors'] as List?)?.map((e) => e.toString()).toList() ??
          [],
      sessionsCompleted: data['sessionsCompleted'] as int? ?? 0,
      endorsements: Map<String, int>.from(data['endorsements'] ?? {}),
      isVerifiedCollegeUser: data['isVerifiedCollegeUser'] as bool? ?? false,
      identityId: data['identityId'] as String?,
      matchScore: data['matchScore'] as int? ?? data['match_score'] as int? ?? 0,
      matchReason: data['matchReason'] as String? ?? data['match_reason'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'profileImageUrl': profileImageUrl,
      'subtitle': subtitle,
      'tags': tags,
      'experience': experience,
      'mentees': mentees,
      'collegeCode': collegeCode,
      'bio': bio,
      'skills': skills,
      'interests': interests,
      'goals': goals,
      'department': department,
      'year': year,
      'yearsOfExperience': yearsOfExperience,
      'isProfileComplete': isProfileComplete,
      'gender': gender,
      'preferences': preferences,
      'onboardingCompletedAt': onboardingCompletedAt != null
          ? Timestamp.fromDate(onboardingCompletedAt!)
          : null,
      'acceptingMentees': acceptingMentees,
      'maxMentees': maxMentees,
      'isOnline': isOnline,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'savedMentors': savedMentors,
      'availabilityStatus': availabilityStatus,
      'sessionsCompleted': sessionsCompleted,
      'endorsements': endorsements,
      'isVerifiedCollegeUser': isVerifiedCollegeUser,
      'identityId': identityId,
      'matchScore': matchScore,
      'matchReason': matchReason,
      // profileEmbedding is managed server-side by Cloud Functions
    };
  }

  AppUser copyWith({
    String? name,
    String? email,
    String? role,
    String? profileImageUrl,
    String? subtitle,
    List<String>? tags,
    String? experience,
    String? mentees,
    String? collegeCode,
    String? bio,
    List<String>? skills,
    List<String>? interests,
    List<String>? goals,
    String? department,
    String? year,
    int? yearsOfExperience,
    int? matchScore,
    String? matchReason,
    bool? isProfileComplete,
    String? gender,
    Map<String, dynamic>? preferences,
    DateTime? onboardingCompletedAt,
    bool? acceptingMentees,
    int? maxMentees,
    List<String>? reviews,
    List<double>? profileEmbedding,
    bool? isOnline,
    DateTime? lastSeen,
    List<String>? savedMentors,
    String? availabilityStatus,
    int? sessionsCompleted,
    Map<String, int>? endorsements,
    bool? isVerifiedCollegeUser,
    String? identityId,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      subtitle: subtitle ?? this.subtitle,
      tags: tags ?? this.tags,
      experience: experience ?? this.experience,
      mentees: mentees ?? this.mentees,
      collegeCode: collegeCode ?? this.collegeCode,
      bio: bio ?? this.bio,
      skills: skills ?? this.skills,
      interests: interests ?? this.interests,
      goals: goals ?? this.goals,
      department: department ?? this.department,
      year: year ?? this.year,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      matchScore: matchScore ?? this.matchScore,
      matchReason: matchReason ?? this.matchReason,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      gender: gender ?? this.gender,
      preferences: preferences ?? this.preferences,
      onboardingCompletedAt:
          onboardingCompletedAt ?? this.onboardingCompletedAt,
      acceptingMentees: acceptingMentees ?? this.acceptingMentees,
      maxMentees: maxMentees ?? this.maxMentees,
      reviews: reviews ?? this.reviews,
      profileEmbedding: profileEmbedding ?? this.profileEmbedding,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      savedMentors: savedMentors ?? this.savedMentors,
      availabilityStatus: availabilityStatus ?? this.availabilityStatus,
      sessionsCompleted: sessionsCompleted ?? this.sessionsCompleted,
      endorsements: endorsements ?? this.endorsements,
      isVerifiedCollegeUser:
          isVerifiedCollegeUser ?? this.isVerifiedCollegeUser,
      identityId: identityId ?? this.identityId,
    );
  }

  /// Returns total number of endorsements across all tags.
  int get totalEndorsements {
    return endorsements.values.fold(0, (acc, val) => acc + val);
  }

  /// Returns the tag with the most endorsements.
  String? get topEndorsementTag {
    if (endorsements.isEmpty) return null;
    return endorsements.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Returns a text summary for the Gemini matching prompt.
  String toMatchingDescription() {
    return '''
Name: $name
Role: $role
Department: ${department ?? 'Unknown'}
Year/Experience: ${year ?? experience ?? 'Unknown'}
Bio: ${bio ?? 'Not provided'}
Skills: ${skills.join(', ')}
Interests: ${interests.join(', ')}
Goals: ${goals.join(', ')}
Tags: ${tags.join(', ')}
''';
  }
}
