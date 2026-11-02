import 'package:flutter_test/flutter_test.dart';
import 'package:connexa/features/recruitment/models/job_models.dart';

void main() {
  group('Job Recruitment Models & DTO Tests', () {
    test('JobOpeningStatus enum parsing and mapping', () {
      expect(JobOpeningStatus.fromInt(1), JobOpeningStatus.open);
      expect(JobOpeningStatus.fromInt(2), JobOpeningStatus.closed);
      expect(JobOpeningStatus.fromInt(3), JobOpeningStatus.cancelled);

      expect(JobOpeningStatus.fromString('open'), JobOpeningStatus.open);
      expect(JobOpeningStatus.fromString('closed'), JobOpeningStatus.closed);
      expect(JobOpeningStatus.fromString('cancelled'), JobOpeningStatus.cancelled);

      expect(JobOpeningStatus.open.toInt(), 1);
      expect(JobOpeningStatus.open.label, 'Open');
    });

    test('JobApplicationStatus enum parsing and mapping', () {
      expect(JobApplicationStatus.fromInt(1), JobApplicationStatus.submitted);
      expect(JobApplicationStatus.fromInt(2), JobApplicationStatus.underReview);
      expect(JobApplicationStatus.fromInt(3), JobApplicationStatus.shortlisted);
      expect(JobApplicationStatus.fromInt(4), JobApplicationStatus.rejected);
      expect(JobApplicationStatus.fromInt(5), JobApplicationStatus.accepted);
      expect(JobApplicationStatus.fromInt(6), JobApplicationStatus.withdrawn);

      expect(JobApplicationStatus.fromString('under_review'), JobApplicationStatus.underReview);
      expect(JobApplicationStatus.fromString('shortlisted'), JobApplicationStatus.shortlisted);
      expect(JobApplicationStatus.fromString('withdrawn'), JobApplicationStatus.withdrawn);

      expect(JobApplicationStatus.submitted.toInt(), 1);
      expect(JobApplicationStatus.shortlisted.label, 'Shortlisted');
    });

    test('JobOpeningSummary deserialization and formatted helpers', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'id': 10,
        'memberId': 301,
        'employerName': 'Rajesh Sharma',
        'employerCompanyName': 'Sharma Precision Tools',
        'employerCity': 'Rajkot',
        'employerState': 'Gujarat',
        'isEmployerVerified': true,
        'title': 'Senior CNC VMC Operator',
        'department': 'Production',
        'industryId': 1,
        'industryName': 'Industrial Machinery',
        'jobType': 'Full-time',
        'workplaceType': 'On-site',
        'city': 'Rajkot',
        'state': 'Gujarat',
        'minExperienceYears': 3,
        'maxExperienceYears': 6,
        'minSalary': 35000.0,
        'maxSalary': 45000.0,
        'salaryPeriod': 'Per Month',
        'openingsCount': 2,
        'status': 1,
        'applicationsCount': 7,
        'viewCount': 85,
        'createdAtUtc': '2026-11-02T10:00:00Z',
      };

      final JobOpeningSummary summary = JobOpeningSummary.fromJson(json);

      expect(summary.id, 10);
      expect(summary.memberId, 301);
      expect(summary.title, 'Senior CNC VMC Operator');
      expect(summary.isEmployerVerified, isTrue);
      expect(summary.experienceDisplay, '3 - 6 yrs');
      expect(summary.salaryDisplay, '₹35000 - ₹45000 / Per Month');
      expect(summary.status, JobOpeningStatus.open);
      expect(summary.applicationsCount, 7);
    });

    test('JobOpeningDetail deserialization and ownership', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'id': 11,
        'memberId': 301,
        'employerName': 'Rajesh Sharma',
        'employerCompanyName': 'Sharma Precision Tools',
        'isEmployerVerified': true,
        'title': 'Lead Quality Engineer',
        'jobType': 'Full-time',
        'workplaceType': 'On-site',
        'city': 'Rajkot',
        'state': 'Gujarat',
        'minExperienceYears': 5,
        'maxExperienceYears': null,
        'minSalary': 50000.0,
        'maxSalary': null,
        'salaryPeriod': 'Per Month',
        'openingsCount': 1,
        'status': 'open',
        'applicationsCount': 3,
        'viewCount': 42,
        'createdAtUtc': '2026-11-01T08:00:00Z',
        'description': 'Responsible for CMM inspection and ISO audits.',
        'requiredSkillsJson': 'CMM, ISO 9001, GD&T',
        'educationRequirements': 'B.E. Mechanical',
        'isOwner': true,
        'hasApplied': false,
        'myApplicationId': null,
      };

      final JobOpeningDetail detail = JobOpeningDetail.fromJson(json);

      expect(detail.id, 11);
      expect(detail.isOwner, isTrue);
      expect(detail.hasApplied, isFalse);
      expect(detail.experienceDisplay, '5+ yrs');
      expect(detail.salaryDisplay, 'From ₹50000 / Per Month');
      expect(detail.requiredSkillsJson, 'CMM, ISO 9001, GD&T');
      expect(detail.educationRequirements, 'B.E. Mechanical');
    });

    test('CreateJobOpeningRequest and UpdateJobOpeningRequest serialization', () {
      const CreateJobOpeningRequest req = CreateJobOpeningRequest(
        title: 'Maintenance Electrician',
        description: 'Troubleshooting PLC and motor drives.',
        department: 'Maintenance',
        city: 'Surat',
        state: 'Gujarat',
        minExperienceYears: 2,
        minSalary: 28000.0,
        openingsCount: 2,
        requiredSkillsJson: 'PLC, VFD, Wiring',
      );

      final Map<String, dynamic> json = req.toJson();

      expect(json['title'], 'Maintenance Electrician');
      expect(json['department'], 'Maintenance');
      expect(json['city'], 'Surat');
      expect(json['minExperienceYears'], 2);
      expect(json['minSalary'], 28000.0);
      expect(json['openingsCount'], 2);
      expect(json['requiredSkillsJson'], 'PLC, VFD, Wiring');

      const UpdateJobOpeningRequest updateReq = UpdateJobOpeningRequest(
        title: 'Maintenance Electrician Lead',
        description: 'Updated description with team lead scope.',
        city: 'Surat',
        state: 'Gujarat',
        status: JobOpeningStatus.closed,
      );

      final Map<String, dynamic> updateJson = updateReq.toJson();
      expect(updateJson['title'], 'Maintenance Electrician Lead');
      expect(updateJson['status'], 2);
    });

    test('SubmitJobApplicationRequest serialization', () {
      const SubmitJobApplicationRequest req = SubmitJobApplicationRequest(
        jobOpeningId: 10,
        fullName: 'Bhavin Patel',
        email: 'bhavin@example.com',
        phone: '+919876543210',
        currentCompany: 'ABC Engineering',
        currentDesignation: 'CNC Turner',
        yearsOfExperience: 4,
        expectedSalary: 38000.0,
        noticePeriodDays: 15,
        coverLetter: '4 years operating Fanuc CNC lathes with tight tolerances.',
        resumeUrl: 'https://storage.connexa.test/resumes/bhavin.pdf',
        resumeFileName: 'bhavin_resume.pdf',
      );

      final Map<String, dynamic> json = req.toJson();

      expect(json['jobOpeningId'], 10);
      expect(json['fullName'], 'Bhavin Patel');
      expect(json['email'], 'bhavin@example.com');
      expect(json['phone'], '+919876543210');
      expect(json['yearsOfExperience'], 4);
      expect(json['expectedSalary'], 38000.0);
      expect(json['noticePeriodDays'], 15);
      expect(json['resumeUrl'], 'https://storage.connexa.test/resumes/bhavin.pdf');
    });

    test('JobApplicationDetail and status history parsing from JSON', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'id': 201,
        'applicationNumber': 'APP-JOB-202611-1001',
        'jobOpeningId': 10,
        'jobTitle': 'Senior CNC VMC Operator',
        'employerCompanyName': 'Sharma Precision Tools',
        'applicantMemberId': 45,
        'fullName': 'Bhavin Patel',
        'email': 'bhavin@example.com',
        'phone': '+919876543210',
        'currentCompany': 'ABC Engineering',
        'currentDesignation': 'CNC Turner',
        'yearsOfExperience': 4,
        'expectedSalary': 38000.0,
        'noticePeriodDays': 15,
        'coverLetter': '4 years operating Fanuc CNC lathes.',
        'resumeUrl': 'https://storage.connexa.test/resumes/bhavin.pdf',
        'resumeFileName': 'bhavin_resume.pdf',
        'status': 3,
        'statusName': 'Shortlisted',
        'employerNotes': 'Strong machine references',
        'createdAtUtc': '2026-11-02T12:00:00Z',
        'statusHistory': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 1,
            'previousStatus': null,
            'newStatus': 1,
            'statusName': 'Submitted',
            'changedByMemberId': 45,
            'changedByName': 'Bhavin Patel',
            'remarks': 'Application submitted',
            'changedAtUtc': '2026-11-02T12:00:00Z',
          },
          <String, dynamic>{
            'id': 2,
            'previousStatus': 1,
            'newStatus': 3,
            'statusName': 'Shortlisted',
            'changedByMemberId': 301,
            'changedByName': 'Rajesh Sharma',
            'remarks': 'Candidate shortlisted for interview',
            'changedAtUtc': '2026-11-02T14:00:00Z',
          },
        ],
      };

      final JobApplicationDetail app = JobApplicationDetail.fromJson(json);

      expect(app.id, 201);
      expect(app.applicationNumber, 'APP-JOB-202611-1001');
      expect(app.status, JobApplicationStatus.shortlisted);
      expect(app.employerNotes, 'Strong machine references');
      expect(app.statusHistory.length, 2);
      expect(app.statusHistory.first.newStatus, JobApplicationStatus.submitted);
      expect(app.statusHistory.last.newStatus, JobApplicationStatus.shortlisted);
      expect(app.statusHistory.last.changedByName, 'Rajesh Sharma');
    });

    test('UpdateJobApplicationStatusRequest serialization', () {
      const UpdateJobApplicationStatusRequest req = UpdateJobApplicationStatusRequest(
        status: JobApplicationStatus.accepted,
        remarks: 'Offer letter dispatched via email',
        employerNotes: 'Starting on 15th of next month',
      );

      final Map<String, dynamic> json = req.toJson();

      expect(json['status'], 5);
      expect(json['remarks'], 'Offer letter dispatched via email');
      expect(json['employerNotes'], 'Starting on 15th of next month');
    });
  });
}

