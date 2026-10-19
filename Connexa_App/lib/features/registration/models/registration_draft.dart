import 'package:flutter/material.dart';

import 'package:connexa/features/registration/models/industry_master_data.dart';

/// Professional profile types available during initial registration.
enum ProfileType {
  businessCompany(
    'Business / Company',
    'Registered enterprise, corporation, or proprietorship',
    Icons.business_rounded,
  ),
  employeeJobSeeker(
    'Employee / Job Seeker',
    'Industry professional, executive, or job applicant',
    Icons.badge_outlined,
  ),
  serviceEngineer(
    'Service Engineer / Technician',
    'Technical specialist, maintenance, or field engineer',
    Icons.build_circle_outlined,
  ),
  traderSupplier(
    'Trader / Supplier',
    'Wholesaler, distributor, or material vendor',
    Icons.inventory_2_outlined,
  ),
  contractorJobWorker(
    'Contractor / Job Worker',
    'Industrial contractor, fabrication, or project laborer',
    Icons.handyman_outlined,
  );

  const ProfileType(this.label, this.description, this.icon);

  final String label;
  final String description;
  final IconData icon;
}

/// Standard business types/capabilities shared across enterprise and trading profiles.
enum BusinessCapability {
  manufacturer('Manufacturer'),
  jobWorker('Job Worker'),
  trader('Trader'),
  supplier('Supplier'),
  distributor('Distributor'),
  contractor('Contractor'),
  serviceProvider('Service Provider');

  const BusinessCapability(this.label);
  final String label;
}

/// Profile details for Business / Company registrations.
class BusinessProfileDetails {
  const BusinessProfileDetails({
    this.companyName = '',
    this.businessCapabilities = const <BusinessCapability>{},
    this.businessDescription = '',
    this.industry,
    this.industrySelection,
  });

  final String companyName;
  final Set<BusinessCapability> businessCapabilities;
  final String businessDescription;
  final String? industry;
  final IndustrySelection? industrySelection;

  BusinessProfileDetails copyWith({
    String? companyName,
    Set<BusinessCapability>? businessCapabilities,
    String? businessDescription,
    String? industry,
    IndustrySelection? industrySelection,
  }) {
    return BusinessProfileDetails(
      companyName: companyName ?? this.companyName,
      businessCapabilities: businessCapabilities ?? this.businessCapabilities,
      businessDescription: businessDescription ?? this.businessDescription,
      industry: industry ?? this.industry,
      industrySelection: industrySelection ?? this.industrySelection,
    );
  }
}

/// Profile details for Employee / Job Seeker registrations.
class EmployeeProfileDetails {
  const EmployeeProfileDetails({
    this.jobTitle = '',
    this.skills = '',
    this.experience = '',
    this.preferredJobType = '',
  });

  final String jobTitle;
  final String skills;
  final String experience;
  final String preferredJobType;

  EmployeeProfileDetails copyWith({
    String? jobTitle,
    String? skills,
    String? experience,
    String? preferredJobType,
  }) {
    return EmployeeProfileDetails(
      jobTitle: jobTitle ?? this.jobTitle,
      skills: skills ?? this.skills,
      experience: experience ?? this.experience,
      preferredJobType: preferredJobType ?? this.preferredJobType,
    );
  }
}

/// Profile details for Service Engineer / Technician registrations.
class ServiceEngineerProfileDetails {
  const ServiceEngineerProfileDetails({
    this.specialization = '',
    this.supportedEquipment = '',
    this.yearsOfExperience = '',
    this.serviceCoverage = '',
  });

  final String specialization;
  final String supportedEquipment;
  final String yearsOfExperience;
  final String serviceCoverage;

  ServiceEngineerProfileDetails copyWith({
    String? specialization,
    String? supportedEquipment,
    String? yearsOfExperience,
    String? serviceCoverage,
  }) {
    return ServiceEngineerProfileDetails(
      specialization: specialization ?? this.specialization,
      supportedEquipment: supportedEquipment ?? this.supportedEquipment,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      serviceCoverage: serviceCoverage ?? this.serviceCoverage,
    );
  }
}

/// Profile details for Trader / Supplier registrations.
class TraderProfileDetails {
  const TraderProfileDetails({
    this.tradingName = '',
    this.capabilities = const <BusinessCapability>{},
    this.productsSupplied = '',
    this.serviceCoverage = '',
  });

  final String tradingName;
  final Set<BusinessCapability> capabilities;
  final String productsSupplied;
  final String serviceCoverage;

  TraderProfileDetails copyWith({
    String? tradingName,
    Set<BusinessCapability>? capabilities,
    String? productsSupplied,
    String? serviceCoverage,
  }) {
    return TraderProfileDetails(
      tradingName: tradingName ?? this.tradingName,
      capabilities: capabilities ?? this.capabilities,
      productsSupplied: productsSupplied ?? this.productsSupplied,
      serviceCoverage: serviceCoverage ?? this.serviceCoverage,
    );
  }
}

/// Profile details for Contractor / Job Worker registrations.
class ContractorProfileDetails {
  const ContractorProfileDetails({
    this.workName = '',
    this.workCapabilities = const <String>{},
    this.industry,
    this.industrySelection,
    this.processesSupported = '',
    this.workCoverage = '',
  });

  final String workName;
  final Set<String> workCapabilities;
  final String? industry;
  final IndustrySelection? industrySelection;
  final String processesSupported;
  final String workCoverage;

  ContractorProfileDetails copyWith({
    String? workName,
    Set<String>? workCapabilities,
    String? industry,
    IndustrySelection? industrySelection,
    String? processesSupported,
    String? workCoverage,
  }) {
    return ContractorProfileDetails(
      workName: workName ?? this.workName,
      workCapabilities: workCapabilities ?? this.workCapabilities,
      industry: industry ?? this.industry,
      industrySelection: industrySelection ?? this.industrySelection,
      processesSupported: processesSupported ?? this.processesSupported,
      workCoverage: workCoverage ?? this.workCoverage,
    );
  }
}

/// In-memory data model storing the uncommitted registration draft state across steps.
class RegistrationDraft {
  const RegistrationDraft({
    this.fullName = '',
    this.countryCode = '+91',
    this.mobileNumber = '',
    this.email = '',
    this.profileType,
    this.businessDetails,
    this.employeeDetails,
    this.serviceEngineerDetails,
    this.traderDetails,
    this.contractorDetails,
    this.registrationFlowId = '',
    this.verificationGrant,
    this.verificationGrantExpiresAt,
    this.verifiedMethod,
    this.verifiedDestination,
    bool? consentAgreed,
  }) : _consentAgreed = consentAgreed ?? false;

  // Step 4 Basic Details
  final String fullName;
  final String countryCode;
  final String mobileNumber;
  final String email;
  final ProfileType? profileType;

  // Step 5 Profile-Specific Details
  final BusinessProfileDetails? businessDetails;
  final EmployeeProfileDetails? employeeDetails;
  final ServiceEngineerProfileDetails? serviceEngineerDetails;
  final TraderProfileDetails? traderDetails;
  final ContractorProfileDetails? contractorDetails;

  // Step 6 Verification State (Either WhatsApp Phone OR Email)
  final String registrationFlowId;
  final String? verificationGrant;
  final DateTime? verificationGrantExpiresAt;
  final String? verifiedMethod; // 'whatsapp' or 'email'
  final String? verifiedDestination; // e.g. masked phone or masked email
  final bool? _consentAgreed;

  /// Whether the user has consented to accurate details declaration.
  bool get consentAgreed => _consentAgreed ?? false;

  /// Whether either phone or email has been verified server-side with an active verification grant.
  bool get isVerified =>
      verificationGrant != null &&
      verificationGrant!.isNotEmpty &&
      (verificationGrantExpiresAt == null ||
          verificationGrantExpiresAt!.isAfter(DateTime.now()));

  /// Backward-compatible phone verified check.
  bool get isPhoneVerified =>
      isVerified &&
      (verifiedMethod == null ||
          verifiedMethod == 'whatsapp' ||
          verifiedMethod == 'phone');

  /// Email verified check.
  bool get isEmailVerified => isVerified && verifiedMethod == 'email';

  RegistrationDraft copyWith({
    String? fullName,
    String? countryCode,
    String? mobileNumber,
    String? email,
    ProfileType? profileType,
    BusinessProfileDetails? businessDetails,
    bool clearBusinessDetails = false,
    EmployeeProfileDetails? employeeDetails,
    bool clearEmployeeDetails = false,
    ServiceEngineerProfileDetails? serviceEngineerDetails,
    bool clearServiceEngineerDetails = false,
    TraderProfileDetails? traderDetails,
    bool clearTraderDetails = false,
    ContractorProfileDetails? contractorDetails,
    bool clearContractorDetails = false,
    String? registrationFlowId,
    String? verificationGrant,
    DateTime? verificationGrantExpiresAt,
    bool clearVerificationGrant = false,
    String? verifiedMethod,
    String? verifiedDestination,
    bool? consentAgreed,
  }) {
    return RegistrationDraft(
      fullName: fullName ?? this.fullName,
      countryCode: countryCode ?? this.countryCode,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      email: email ?? this.email,
      profileType: profileType ?? this.profileType,
      businessDetails: clearBusinessDetails
          ? null
          : (businessDetails ?? this.businessDetails),
      employeeDetails: clearEmployeeDetails
          ? null
          : (employeeDetails ?? this.employeeDetails),
      serviceEngineerDetails: clearServiceEngineerDetails
          ? null
          : (serviceEngineerDetails ?? this.serviceEngineerDetails),
      traderDetails: clearTraderDetails
          ? null
          : (traderDetails ?? this.traderDetails),
      contractorDetails: clearContractorDetails
          ? null
          : (contractorDetails ?? this.contractorDetails),
      registrationFlowId: registrationFlowId ?? this.registrationFlowId,
      verificationGrant: clearVerificationGrant
          ? null
          : (verificationGrant ?? this.verificationGrant),
      verificationGrantExpiresAt: clearVerificationGrant
          ? null
          : (verificationGrantExpiresAt ?? this.verificationGrantExpiresAt),
      verifiedMethod: clearVerificationGrant
          ? null
          : (verifiedMethod ?? this.verifiedMethod),
      verifiedDestination: clearVerificationGrant
          ? null
          : (verifiedDestination ?? this.verifiedDestination),
      consentAgreed: consentAgreed ?? this.consentAgreed,
    );
  }

  /// Returns validation error messages for Basic Details (Step 1).
  List<String> get basicDetailsValidationErrors {
    final List<String> errors = <String>[];
    final String trimmedName = fullName.trim();
    if (trimmedName.isEmpty) {
      errors.add('Full name is required');
    } else if (trimmedName.length < 2) {
      errors.add('Full name must be at least 2 characters');
    }

    final String trimmedPhone = mobileNumber.trim();
    if (trimmedPhone.isEmpty) {
      errors.add('Mobile number is required');
    } else if (countryCode == '+91') {
      final RegExp indianPhoneRegex = RegExp(r'^[6-9]\d{9}$');
      if (!indianPhoneRegex.hasMatch(trimmedPhone)) {
        errors.add('A valid 10-digit Indian mobile number is required');
      }
    } else {
      final RegExp generalPhoneRegex = RegExp(r'^\d{7,15}$');
      if (!generalPhoneRegex.hasMatch(trimmedPhone)) {
        errors.add('A valid mobile number (7–15 digits) is required');
      }
    }

    final String trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      errors.add('Email address is required');
    } else {
      final RegExp emailRegex = RegExp(
        r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
      );
      if (!emailRegex.hasMatch(trimmedEmail)) {
        errors.add('A valid email address is required');
      }
    }

    if (profileType == null) {
      errors.add('Profile role selection is required');
    }

    return errors;
  }

  /// Returns validation error messages for Profile-Specific Details (Step 2).
  List<String> get profileDetailsValidationErrors {
    final List<String> errors = <String>[];
    if (profileType == null) {
      return errors;
    }

    switch (profileType!) {
      case ProfileType.businessCompany:
        if (businessDetails == null) {
          errors.add('Business profile details are missing');
        } else {
          if (businessDetails!.companyName.trim().isEmpty) {
            errors.add('Company / Business name is required');
          }
          if (businessDetails!.businessCapabilities.isEmpty) {
            errors.add('At least one business capability must be selected');
          }
          if (businessDetails!.industrySelection == null ||
              !businessDetails!.industrySelection!.isComplete) {
            errors.add(
              'Complete 4-tier industry classification is required (Industry, Group, SubGroup, Category)',
            );
          }
        }
      case ProfileType.employeeJobSeeker:
        if (employeeDetails == null) {
          errors.add('Employee profile details are missing');
        } else {
          if (employeeDetails!.jobTitle.trim().isEmpty) {
            errors.add('Profession / Job title is required');
          }
        }
      case ProfileType.serviceEngineer:
        if (serviceEngineerDetails == null) {
          errors.add('Service engineer profile details are missing');
        } else {
          if (serviceEngineerDetails!.specialization.trim().isEmpty) {
            errors.add('Technical specialization is required');
          }
        }
      case ProfileType.traderSupplier:
        if (traderDetails == null) {
          errors.add('Trader profile details are missing');
        } else {
          if (traderDetails!.tradingName.trim().isEmpty) {
            errors.add('Business / Trading name is required');
          }
          if (traderDetails!.capabilities.isEmpty) {
            errors.add('At least one supplier capability must be selected');
          }
        }
      case ProfileType.contractorJobWorker:
        if (contractorDetails == null) {
          errors.add('Contractor profile details are missing');
        } else {
          if (contractorDetails!.workName.trim().isEmpty) {
            errors.add('Business / Work name is required');
          }
          if (contractorDetails!.workCapabilities.isEmpty) {
            errors.add('At least one work capability must be selected');
          }
          if (contractorDetails!.industrySelection == null ||
              !contractorDetails!.industrySelection!.isComplete) {
            errors.add(
              'Complete 4-tier industry classification is required (Industry, Group, SubGroup, Category)',
            );
          }
        }
    }

    return errors;
  }

  /// Aggregated list of all validation errors across Step 1 and Step 2.
  List<String> get allValidationErrors => <String>[
    ...basicDetailsValidationErrors,
    ...profileDetailsValidationErrors,
  ];

  /// Whether the draft passes all Step 1 and Step 2 validation requirements.
  bool get isCompleteAndValid => allValidationErrors.isEmpty;
}
