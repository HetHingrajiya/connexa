import 'package:flutter/material.dart';
import 'package:connexa/core/theme/theme.dart';

enum JobOpeningStatus {
  open,
  closed,
  cancelled;

  static JobOpeningStatus fromInt(int value) {
    switch (value) {
      case 1:
        return JobOpeningStatus.open;
      case 2:
        return JobOpeningStatus.closed;
      case 3:
        return JobOpeningStatus.cancelled;
      default:
        return JobOpeningStatus.open;
    }
  }

  static JobOpeningStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'closed':
        return JobOpeningStatus.closed;
      case 'cancelled':
        return JobOpeningStatus.cancelled;
      case 'open':
      default:
        return JobOpeningStatus.open;
    }
  }

  int toInt() {
    switch (this) {
      case JobOpeningStatus.open:
        return 1;
      case JobOpeningStatus.closed:
        return 2;
      case JobOpeningStatus.cancelled:
        return 3;
    }
  }

  String get label {
    switch (this) {
      case JobOpeningStatus.open:
        return 'Open';
      case JobOpeningStatus.closed:
        return 'Closed';
      case JobOpeningStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case JobOpeningStatus.open:
        return AppColors.success;
      case JobOpeningStatus.closed:
        return AppColors.textMuted;
      case JobOpeningStatus.cancelled:
        return AppColors.error;
    }
  }
}

enum JobApplicationStatus {
  submitted,
  underReview,
  shortlisted,
  rejected,
  accepted,
  withdrawn;

  static JobApplicationStatus fromInt(int value) {
    switch (value) {
      case 1:
        return JobApplicationStatus.submitted;
      case 2:
        return JobApplicationStatus.underReview;
      case 3:
        return JobApplicationStatus.shortlisted;
      case 4:
        return JobApplicationStatus.rejected;
      case 5:
        return JobApplicationStatus.accepted;
      case 6:
        return JobApplicationStatus.withdrawn;
      default:
        return JobApplicationStatus.submitted;
    }
  }

  static JobApplicationStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'underreview':
      case 'under_review':
        return JobApplicationStatus.underReview;
      case 'shortlisted':
        return JobApplicationStatus.shortlisted;
      case 'rejected':
        return JobApplicationStatus.rejected;
      case 'accepted':
        return JobApplicationStatus.accepted;
      case 'withdrawn':
        return JobApplicationStatus.withdrawn;
      case 'submitted':
      default:
        return JobApplicationStatus.submitted;
    }
  }

  int toInt() {
    switch (this) {
      case JobApplicationStatus.submitted:
        return 1;
      case JobApplicationStatus.underReview:
        return 2;
      case JobApplicationStatus.shortlisted:
        return 3;
      case JobApplicationStatus.rejected:
        return 4;
      case JobApplicationStatus.accepted:
        return 5;
      case JobApplicationStatus.withdrawn:
        return 6;
    }
  }

  String get label {
    switch (this) {
      case JobApplicationStatus.submitted:
        return 'Submitted';
      case JobApplicationStatus.underReview:
        return 'Under Review';
      case JobApplicationStatus.shortlisted:
        return 'Shortlisted';
      case JobApplicationStatus.rejected:
        return 'Rejected';
      case JobApplicationStatus.accepted:
        return 'Accepted';
      case JobApplicationStatus.withdrawn:
        return 'Withdrawn';
    }
  }

  Color get color {
    switch (this) {
      case JobApplicationStatus.submitted:
        return AppColors.warning;
      case JobApplicationStatus.underReview:
        return AppColors.primary;
      case JobApplicationStatus.shortlisted:
        return AppColors.secondary;
      case JobApplicationStatus.accepted:
        return AppColors.success;
      case JobApplicationStatus.rejected:
        return AppColors.error;
      case JobApplicationStatus.withdrawn:
        return AppColors.textMuted;
    }
  }
}

class JobOpeningSummary {
  const JobOpeningSummary({
    required this.id,
    required this.memberId,
    required this.employerName,
    this.employerCompanyName,
    this.employerCity,
    this.employerState,
    required this.isEmployerVerified,
    required this.title,
    this.department,
    this.industryId,
    this.industryName,
    required this.jobType,
    required this.workplaceType,
    required this.city,
    required this.state,
    required this.minExperienceYears,
    this.maxExperienceYears,
    this.minSalary,
    this.maxSalary,
    required this.salaryPeriod,
    required this.openingsCount,
    required this.status,
    required this.applicationsCount,
    required this.viewCount,
    required this.createdAtUtc,
    this.applicationDeadlineUtc,
  });

  factory JobOpeningSummary.fromJson(Map<String, dynamic> json) {
    return JobOpeningSummary(
      id: json['id'] as int? ?? 0,
      memberId: json['memberId'] as int? ?? 0,
      employerName: json['employerName'] as String? ?? 'Employer',
      employerCompanyName: json['employerCompanyName'] as String?,
      employerCity: json['employerCity'] as String?,
      employerState: json['employerState'] as String?,
      isEmployerVerified: json['isEmployerVerified'] as bool? ?? false,
      title: json['title'] as String? ?? '',
      department: json['department'] as String?,
      industryId: json['industryId'] as int?,
      industryName: json['industryName'] as String?,
      jobType: json['jobType'] as String? ?? 'Full-time',
      workplaceType: json['workplaceType'] as String? ?? 'On-site',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      minExperienceYears: json['minExperienceYears'] as int? ?? 0,
      maxExperienceYears: json['maxExperienceYears'] as int?,
      minSalary: (json['minSalary'] as num?)?.toDouble(),
      maxSalary: (json['maxSalary'] as num?)?.toDouble(),
      salaryPeriod: json['salaryPeriod'] as String? ?? 'Per Month',
      openingsCount: json['openingsCount'] as int? ?? 1,
      status: json['status'] is int
          ? JobOpeningStatus.fromInt(json['status'] as int)
          : JobOpeningStatus.fromString(json['status'] as String?),
      applicationsCount: json['applicationsCount'] as int? ?? 0,
      viewCount: json['viewCount'] as int? ?? 0,
      createdAtUtc: DateTime.tryParse(json['createdAtUtc'] as String? ?? '') ??
          DateTime.now().toUtc(),
      applicationDeadlineUtc: json['applicationDeadlineUtc'] != null
          ? DateTime.tryParse(json['applicationDeadlineUtc'] as String)
          : null,
    );
  }

  final int id;
  final int memberId;
  final String employerName;
  final String? employerCompanyName;
  final String? employerCity;
  final String? employerState;
  final bool isEmployerVerified;
  final String title;
  final String? department;
  final int? industryId;
  final String? industryName;
  final String jobType;
  final String workplaceType;
  final String city;
  final String state;
  final int minExperienceYears;
  final int? maxExperienceYears;
  final double? minSalary;
  final double? maxSalary;
  final String salaryPeriod;
  final int openingsCount;
  final JobOpeningStatus status;
  final int applicationsCount;
  final int viewCount;
  final DateTime createdAtUtc;
  final DateTime? applicationDeadlineUtc;

  String get experienceDisplay {
    if (minExperienceYears == 0 && (maxExperienceYears == null || maxExperienceYears == 0)) {
      return 'Fresher / Any Experience';
    }
    if (maxExperienceYears != null && maxExperienceYears! > minExperienceYears) {
      return '$minExperienceYears - $maxExperienceYears yrs';
    }
    return '$minExperienceYears+ yrs';
  }

  String get salaryDisplay {
    if (minSalary == null && maxSalary == null) return 'Salary Undisclosed';
    if (minSalary != null && maxSalary != null) {
      return '₹${minSalary!.toStringAsFixed(0)} - ₹${maxSalary!.toStringAsFixed(0)} / $salaryPeriod';
    }
    if (minSalary != null) {
      return 'From ₹${minSalary!.toStringAsFixed(0)} / $salaryPeriod';
    }
    return 'Up to ₹${maxSalary!.toStringAsFixed(0)} / $salaryPeriod';
  }
}

class JobOpeningDetail extends JobOpeningSummary {
  const JobOpeningDetail({
    required super.id,
    required super.memberId,
    required super.employerName,
    super.employerCompanyName,
    super.employerCity,
    super.employerState,
    required super.isEmployerVerified,
    required super.title,
    super.department,
    super.industryId,
    super.industryName,
    required super.jobType,
    required super.workplaceType,
    required super.city,
    required super.state,
    required super.minExperienceYears,
    super.maxExperienceYears,
    super.minSalary,
    super.maxSalary,
    required super.salaryPeriod,
    required super.openingsCount,
    required super.status,
    required super.applicationsCount,
    required super.viewCount,
    required super.createdAtUtc,
    super.applicationDeadlineUtc,
    required this.description,
    this.address,
    this.businessGroupId,
    this.subGroupId,
    this.categoryId,
    this.requiredSkillsJson,
    this.educationRequirements,
    this.updatedAtUtc,
    required this.isOwner,
    required this.hasApplied,
    this.myApplicationId,
  });

  factory JobOpeningDetail.fromJson(Map<String, dynamic> json) {
    return JobOpeningDetail(
      id: json['id'] as int? ?? 0,
      memberId: json['memberId'] as int? ?? 0,
      employerName: json['employerName'] as String? ?? 'Employer',
      employerCompanyName: json['employerCompanyName'] as String?,
      employerCity: json['employerCity'] as String?,
      employerState: json['employerState'] as String?,
      isEmployerVerified: json['isEmployerVerified'] as bool? ?? false,
      title: json['title'] as String? ?? '',
      department: json['department'] as String?,
      industryId: json['industryId'] as int?,
      industryName: json['industryName'] as String?,
      jobType: json['jobType'] as String? ?? 'Full-time',
      workplaceType: json['workplaceType'] as String? ?? 'On-site',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      minExperienceYears: json['minExperienceYears'] as int? ?? 0,
      maxExperienceYears: json['maxExperienceYears'] as int?,
      minSalary: (json['minSalary'] as num?)?.toDouble(),
      maxSalary: (json['maxSalary'] as num?)?.toDouble(),
      salaryPeriod: json['salaryPeriod'] as String? ?? 'Per Month',
      openingsCount: json['openingsCount'] as int? ?? 1,
      status: json['status'] is int
          ? JobOpeningStatus.fromInt(json['status'] as int)
          : JobOpeningStatus.fromString(json['status'] as String?),
      applicationsCount: json['applicationsCount'] as int? ?? 0,
      viewCount: json['viewCount'] as int? ?? 0,
      createdAtUtc: DateTime.tryParse(json['createdAtUtc'] as String? ?? '') ??
          DateTime.now().toUtc(),
      applicationDeadlineUtc: json['applicationDeadlineUtc'] != null
          ? DateTime.tryParse(json['applicationDeadlineUtc'] as String)
          : null,
      description: json['description'] as String? ?? '',
      address: json['address'] as String?,
      businessGroupId: json['businessGroupId'] as int?,
      subGroupId: json['subGroupId'] as int?,
      categoryId: json['categoryId'] as int?,
      requiredSkillsJson: json['requiredSkillsJson'] as String?,
      educationRequirements: json['educationRequirements'] as String?,
      updatedAtUtc: json['updatedAtUtc'] != null
          ? DateTime.tryParse(json['updatedAtUtc'] as String)
          : null,
      isOwner: json['isOwner'] as bool? ?? false,
      hasApplied: json['hasApplied'] as bool? ?? false,
      myApplicationId: json['myApplicationId'] as int?,
    );
  }

  final String description;
  final String? address;
  final int? businessGroupId;
  final int? subGroupId;
  final int? categoryId;
  final String? requiredSkillsJson;
  final String? educationRequirements;
  final DateTime? updatedAtUtc;
  final bool isOwner;
  final bool hasApplied;
  final int? myApplicationId;
}

class CreateJobOpeningRequest {
  const CreateJobOpeningRequest({
    required this.title,
    required this.description,
    this.department,
    this.industryId,
    this.businessGroupId,
    this.subGroupId,
    this.categoryId,
    this.jobType = 'Full-time',
    this.workplaceType = 'On-site',
    required this.city,
    required this.state,
    this.address,
    this.minExperienceYears = 0,
    this.maxExperienceYears,
    this.minSalary,
    this.maxSalary,
    this.salaryPeriod = 'Per Month',
    this.requiredSkillsJson,
    this.educationRequirements,
    this.openingsCount = 1,
    this.applicationDeadlineUtc,
  });

  final String title;
  final String description;
  final String? department;
  final int? industryId;
  final int? businessGroupId;
  final int? subGroupId;
  final int? categoryId;
  final String jobType;
  final String workplaceType;
  final String city;
  final String state;
  final String? address;
  final int minExperienceYears;
  final int? maxExperienceYears;
  final double? minSalary;
  final double? maxSalary;
  final String salaryPeriod;
  final String? requiredSkillsJson;
  final String? educationRequirements;
  final int openingsCount;
  final DateTime? applicationDeadlineUtc;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'title': title.trim(),
        'description': description.trim(),
        if (department != null && department!.isNotEmpty) 'department': department!.trim(),
        if (industryId != null) 'industryId': industryId,
        if (businessGroupId != null) 'businessGroupId': businessGroupId,
        if (subGroupId != null) 'subGroupId': subGroupId,
        if (categoryId != null) 'categoryId': categoryId,
        'jobType': jobType,
        'workplaceType': workplaceType,
        'city': city.trim(),
        'state': state.trim(),
        if (address != null && address!.isNotEmpty) 'address': address!.trim(),
        'minExperienceYears': minExperienceYears,
        if (maxExperienceYears != null) 'maxExperienceYears': maxExperienceYears,
        if (minSalary != null) 'minSalary': minSalary,
        if (maxSalary != null) 'maxSalary': maxSalary,
        'salaryPeriod': salaryPeriod,
        if (requiredSkillsJson != null && requiredSkillsJson!.isNotEmpty)
          'requiredSkillsJson': requiredSkillsJson!.trim(),
        if (educationRequirements != null && educationRequirements!.isNotEmpty)
          'educationRequirements': educationRequirements!.trim(),
        'openingsCount': openingsCount,
        if (applicationDeadlineUtc != null)
          'applicationDeadlineUtc': applicationDeadlineUtc!.toIso8601String(),
      };
}

class UpdateJobOpeningRequest extends CreateJobOpeningRequest {
  const UpdateJobOpeningRequest({
    required super.title,
    required super.description,
    super.department,
    super.industryId,
    super.businessGroupId,
    super.subGroupId,
    super.categoryId,
    super.jobType,
    super.workplaceType,
    required super.city,
    required super.state,
    super.address,
    super.minExperienceYears,
    super.maxExperienceYears,
    super.minSalary,
    super.maxSalary,
    super.salaryPeriod,
    super.requiredSkillsJson,
    super.educationRequirements,
    super.openingsCount,
    super.applicationDeadlineUtc,
    this.status = JobOpeningStatus.open,
  });

  final JobOpeningStatus status;

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = super.toJson();
    map['status'] = status.toInt();
    return map;
  }
}

class JobApplicationStatusHistory {
  const JobApplicationStatusHistory({
    required this.id,
    this.previousStatus,
    required this.newStatus,
    required this.statusName,
    required this.changedByMemberId,
    required this.changedByName,
    this.remarks,
    required this.changedAtUtc,
  });

  factory JobApplicationStatusHistory.fromJson(Map<String, dynamic> json) {
    return JobApplicationStatusHistory(
      id: json['id'] as int? ?? 0,
      previousStatus: json['previousStatus'] != null
          ? JobApplicationStatus.fromInt(json['previousStatus'] as int)
          : null,
      newStatus: JobApplicationStatus.fromInt(json['newStatus'] as int? ?? 1),
      statusName: json['statusName'] as String? ?? 'Submitted',
      changedByMemberId: json['changedByMemberId'] as int? ?? 0,
      changedByName: json['changedByName'] as String? ?? 'Member',
      remarks: json['remarks'] as String?,
      changedAtUtc: DateTime.tryParse(json['changedAtUtc'] as String? ?? '') ??
          DateTime.now().toUtc(),
    );
  }

  final int id;
  final JobApplicationStatus? previousStatus;
  final JobApplicationStatus newStatus;
  final String statusName;
  final int changedByMemberId;
  final String changedByName;
  final String? remarks;
  final DateTime changedAtUtc;
}

class JobApplicationSummary {
  const JobApplicationSummary({
    required this.id,
    required this.applicationNumber,
    required this.jobOpeningId,
    required this.jobTitle,
    this.employerCompanyName,
    required this.applicantMemberId,
    required this.fullName,
    required this.email,
    required this.phone,
    this.currentCompany,
    this.currentDesignation,
    required this.yearsOfExperience,
    this.expectedSalary,
    this.resumeUrl,
    this.resumeFileName,
    required this.status,
    required this.statusName,
    required this.createdAtUtc,
  });

  factory JobApplicationSummary.fromJson(Map<String, dynamic> json) {
    return JobApplicationSummary(
      id: json['id'] as int? ?? 0,
      applicationNumber: json['applicationNumber'] as String? ?? '',
      jobOpeningId: json['jobOpeningId'] as int? ?? 0,
      jobTitle: json['jobTitle'] as String? ?? 'Job Opening',
      employerCompanyName: json['employerCompanyName'] as String?,
      applicantMemberId: json['applicantMemberId'] as int? ?? 0,
      fullName: json['fullName'] as String? ?? 'Candidate',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      currentCompany: json['currentCompany'] as String?,
      currentDesignation: json['currentDesignation'] as String?,
      yearsOfExperience: json['yearsOfExperience'] as int? ?? 0,
      expectedSalary: (json['expectedSalary'] as num?)?.toDouble(),
      resumeUrl: json['resumeUrl'] as String?,
      resumeFileName: json['resumeFileName'] as String?,
      status: json['status'] is int
          ? JobApplicationStatus.fromInt(json['status'] as int)
          : JobApplicationStatus.fromString(json['status'] as String?),
      statusName: json['statusName'] as String? ?? 'Submitted',
      createdAtUtc: DateTime.tryParse(json['createdAtUtc'] as String? ?? '') ??
          DateTime.now().toUtc(),
    );
  }

  final int id;
  final String applicationNumber;
  final int jobOpeningId;
  final String jobTitle;
  final String? employerCompanyName;
  final int applicantMemberId;
  final String fullName;
  final String email;
  final String phone;
  final String? currentCompany;
  final String? currentDesignation;
  final int yearsOfExperience;
  final double? expectedSalary;
  final String? resumeUrl;
  final String? resumeFileName;
  final JobApplicationStatus status;
  final String statusName;
  final DateTime createdAtUtc;
}

class JobApplicationDetail extends JobApplicationSummary {
  const JobApplicationDetail({
    required super.id,
    required super.applicationNumber,
    required super.jobOpeningId,
    required super.jobTitle,
    super.employerCompanyName,
    required super.applicantMemberId,
    required super.fullName,
    required super.email,
    required super.phone,
    super.currentCompany,
    super.currentDesignation,
    required super.yearsOfExperience,
    super.expectedSalary,
    super.resumeUrl,
    super.resumeFileName,
    required super.status,
    required super.statusName,
    required super.createdAtUtc,
    this.noticePeriodDays,
    this.coverLetter,
    this.employerNotes,
    this.reviewedAtUtc,
    this.updatedAtUtc,
    this.jobOpening,
    this.statusHistory = const <JobApplicationStatusHistory>[],
  });

  factory JobApplicationDetail.fromJson(Map<String, dynamic> json) {
    return JobApplicationDetail(
      id: json['id'] as int? ?? 0,
      applicationNumber: json['applicationNumber'] as String? ?? '',
      jobOpeningId: json['jobOpeningId'] as int? ?? 0,
      jobTitle: json['jobTitle'] as String? ?? 'Job Opening',
      employerCompanyName: json['employerCompanyName'] as String?,
      applicantMemberId: json['applicantMemberId'] as int? ?? 0,
      fullName: json['fullName'] as String? ?? 'Candidate',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      currentCompany: json['currentCompany'] as String?,
      currentDesignation: json['currentDesignation'] as String?,
      yearsOfExperience: json['yearsOfExperience'] as int? ?? 0,
      expectedSalary: (json['expectedSalary'] as num?)?.toDouble(),
      resumeUrl: json['resumeUrl'] as String?,
      resumeFileName: json['resumeFileName'] as String?,
      status: json['status'] is int
          ? JobApplicationStatus.fromInt(json['status'] as int)
          : JobApplicationStatus.fromString(json['status'] as String?),
      statusName: json['statusName'] as String? ?? 'Submitted',
      createdAtUtc: DateTime.tryParse(json['createdAtUtc'] as String? ?? '') ??
          DateTime.now().toUtc(),
      noticePeriodDays: json['noticePeriodDays'] as int?,
      coverLetter: json['coverLetter'] as String?,
      employerNotes: json['employerNotes'] as String?,
      reviewedAtUtc: json['reviewedAtUtc'] != null
          ? DateTime.tryParse(json['reviewedAtUtc'] as String)
          : null,
      updatedAtUtc: json['updatedAtUtc'] != null
          ? DateTime.tryParse(json['updatedAtUtc'] as String)
          : null,
      jobOpening: json['jobOpening'] != null
          ? JobOpeningSummary.fromJson(json['jobOpening'] as Map<String, dynamic>)
          : null,
      statusHistory: (json['statusHistory'] as List<dynamic>?)
              ?.map((item) => JobApplicationStatusHistory.fromJson(
                  item as Map<String, dynamic>))
              .toList() ??
          const <JobApplicationStatusHistory>[],
    );
  }

  final int? noticePeriodDays;
  final String? coverLetter;
  final String? employerNotes;
  final DateTime? reviewedAtUtc;
  final DateTime? updatedAtUtc;
  final JobOpeningSummary? jobOpening;
  final List<JobApplicationStatusHistory> statusHistory;
}

class SubmitJobApplicationRequest {
  const SubmitJobApplicationRequest({
    required this.jobOpeningId,
    required this.fullName,
    required this.email,
    required this.phone,
    this.currentCompany,
    this.currentDesignation,
    this.yearsOfExperience = 0,
    this.expectedSalary,
    this.noticePeriodDays,
    this.coverLetter,
    this.resumeUrl,
    this.resumeFileName,
  });

  final int jobOpeningId;
  final String fullName;
  final String email;
  final String phone;
  final String? currentCompany;
  final String? currentDesignation;
  final int yearsOfExperience;
  final double? expectedSalary;
  final int? noticePeriodDays;
  final String? coverLetter;
  final String? resumeUrl;
  final String? resumeFileName;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'jobOpeningId': jobOpeningId,
        'fullName': fullName.trim(),
        'email': email.trim().toLowerCase(),
        'phone': phone.trim(),
        if (currentCompany != null && currentCompany!.isNotEmpty)
          'currentCompany': currentCompany!.trim(),
        if (currentDesignation != null && currentDesignation!.isNotEmpty)
          'currentDesignation': currentDesignation!.trim(),
        'yearsOfExperience': yearsOfExperience,
        if (expectedSalary != null) 'expectedSalary': expectedSalary,
        if (noticePeriodDays != null) 'noticePeriodDays': noticePeriodDays,
        if (coverLetter != null && coverLetter!.isNotEmpty)
          'coverLetter': coverLetter!.trim(),
        if (resumeUrl != null && resumeUrl!.isNotEmpty)
          'resumeUrl': resumeUrl!.trim(),
        if (resumeFileName != null && resumeFileName!.isNotEmpty)
          'resumeFileName': resumeFileName!.trim(),
      };
}

class UpdateJobApplicationStatusRequest {
  const UpdateJobApplicationStatusRequest({
    required this.status,
    this.remarks,
    this.employerNotes,
  });

  final JobApplicationStatus status;
  final String? remarks;
  final String? employerNotes;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'status': status.toInt(),
        if (remarks != null && remarks!.isNotEmpty) 'remarks': remarks!.trim(),
        if (employerNotes != null && employerNotes!.isNotEmpty)
          'employerNotes': employerNotes!.trim(),
      };
}

