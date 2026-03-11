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
  final int matchScore; // computed field, not stored

  // Onboarding & preferences fields
  final bool isProfileComplete;
  final String? gender;
  final Map<String, dynamic>? preferences; // {connectWith, communicationStyle}
  final DateTime? onboardingCompletedAt;

  // Mentor-specific fields
  final bool acceptingMentees;
  final int maxMentees;

  // Vector embedding for semantic matchmaking
  final List<double>? profileEmbedding;

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
    this.isProfileComplete = false,
    this.gender,
    this.preferences,
    this.onboardingCompletedAt,
    this.acceptingMentees = false,
    this.maxMentees = 3,
    this.profileEmbedding,
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
      skills: (data['skills'] as List?)?.map((e) => e.toString()).toList() ?? [],
      interests: (data['interests'] as List?)?.map((e) => e.toString()).toList() ?? [],
      goals: (data['goals'] as List?)?.map((e) => e.toString()).toList() ?? [],
      department: data['department'] as String?,
      year: data['year'] as String?,
      yearsOfExperience: data['yearsOfExperience'] as int?,
      isProfileComplete: data['isProfileComplete'] as bool? ?? false,
      gender: data['gender'] as String?,
      preferences: data['preferences'] is Map ? Map<String, dynamic>.from(data['preferences'] as Map) : null,
      onboardingCompletedAt: (data['onboardingCompletedAt'] as Timestamp?)?.toDate(),
      acceptingMentees: data['acceptingMentees'] as bool? ?? false,
      maxMentees: data['maxMentees'] as int? ?? 3,
      profileEmbedding: (data['profileEmbedding'] as List?)?.map((e) => (e as num?)?.toDouble() ?? 0.0).toList(),
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
      skills: (data['skills'] as List?)?.map((e) => e.toString()).toList() ?? [],
      interests: (data['interests'] as List?)?.map((e) => e.toString()).toList() ?? [],
      goals: (data['goals'] as List?)?.map((e) => e.toString()).toList() ?? [],
      department: data['department'] as String?,
      year: data['year'] as String?,
      yearsOfExperience: data['yearsOfExperience'] as int?,
      isProfileComplete: data['isProfileComplete'] as bool? ?? false,
      gender: data['gender'] as String?,
      preferences: data['preferences'] is Map ? Map<String, dynamic>.from(data['preferences'] as Map) : null,
      onboardingCompletedAt: (data['onboardingCompletedAt'] as Timestamp?)?.toDate(),
      acceptingMentees: data['acceptingMentees'] as bool? ?? false,
      maxMentees: data['maxMentees'] as int? ?? 3,
      profileEmbedding: (data['profileEmbedding'] as List?)?.map((e) => (e as num?)?.toDouble() ?? 0.0).toList(),
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
    bool? isProfileComplete,
    String? gender,
    Map<String, dynamic>? preferences,
    DateTime? onboardingCompletedAt,
    bool? acceptingMentees,
    int? maxMentees,
    List<double>? profileEmbedding,
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
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      gender: gender ?? this.gender,
      preferences: preferences ?? this.preferences,
      onboardingCompletedAt: onboardingCompletedAt ?? this.onboardingCompletedAt,
      acceptingMentees: acceptingMentees ?? this.acceptingMentees,
      maxMentees: maxMentees ?? this.maxMentees,
      profileEmbedding: profileEmbedding ?? this.profileEmbedding,
    );
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
