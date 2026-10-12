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
  });

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

  RegistrationDraft copyWith({
    String? fullName,
    String? countryCode,
    String? mobileNumber,
    String? email,
    ProfileType? profileType,
    BusinessProfileDetails? businessDetails,
    EmployeeProfileDetails? employeeDetails,
    ServiceEngineerProfileDetails? serviceEngineerDetails,
    TraderProfileDetails? traderDetails,
    ContractorProfileDetails? contractorDetails,
  }) {
    return RegistrationDraft(
      fullName: fullName ?? this.fullName,
      countryCode: countryCode ?? this.countryCode,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      email: email ?? this.email,
      profileType: profileType ?? this.profileType,
      businessDetails: businessDetails ?? this.businessDetails,
      employeeDetails: employeeDetails ?? this.employeeDetails,
      serviceEngineerDetails:
          serviceEngineerDetails ?? this.serviceEngineerDetails,
      traderDetails: traderDetails ?? this.traderDetails,
      contractorDetails: contractorDetails ?? this.contractorDetails,
    );
  }
}
