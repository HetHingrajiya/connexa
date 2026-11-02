import 'package:flutter_test/flutter_test.dart';
import 'package:connexa/features/services/models/service_models.dart';

void main() {
  group('Service Marketplace Models & DTO Tests', () {
    test('ServiceInquiryStatus enum mappings', () {
      expect(ServiceInquiryStatus.fromInt(1), ServiceInquiryStatus.pending);
      expect(ServiceInquiryStatus.fromInt(2), ServiceInquiryStatus.underReview);
      expect(ServiceInquiryStatus.fromInt(3), ServiceInquiryStatus.responded);
      expect(ServiceInquiryStatus.fromInt(4), ServiceInquiryStatus.accepted);
      expect(ServiceInquiryStatus.fromInt(5), ServiceInquiryStatus.declined);
      expect(ServiceInquiryStatus.fromInt(6), ServiceInquiryStatus.closed);

      expect(ServiceInquiryStatus.fromString('under_review'), ServiceInquiryStatus.underReview);
      expect(ServiceInquiryStatus.fromString('responded'), ServiceInquiryStatus.responded);
      expect(ServiceInquiryStatus.fromString('accepted'), ServiceInquiryStatus.accepted);
      expect(ServiceInquiryStatus.fromString('declined'), ServiceInquiryStatus.declined);
      expect(ServiceInquiryStatus.fromString('closed'), ServiceInquiryStatus.closed);

      expect(ServiceInquiryStatus.pending.toInt(), 1);
      expect(ServiceInquiryStatus.responded.toInt(), 3);
      expect(ServiceInquiryStatus.accepted.label, 'Accepted');
    });

    test('ServiceSummary deserialization from JSON', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'id': 101,
        'memberId': 42,
        'providerName': 'Rajesh Sharma',
        'providerCompanyName': 'Sharma CNC Works',
        'providerCity': 'Ahmedabad',
        'providerState': 'Gujarat',
        'title': 'High Precision CNC Milling Service',
        'description': '3-axis and 5-axis CNC machining up to 10 microns.',
        'serviceCategory': 'Machining',
        'industryId': 3,
        'industryName': 'Heavy Machinery',
        'serviceType': 'Job-Work',
        'pricingModel': 'Per Hour',
        'startingPrice': 750.0,
        'priceUnit': 'hr',
        'turnaroundTime': '3-5 business days',
        'coverageArea': 'Gujarat & Maharashtra',
        'location': 'Ahmedabad',
        'imagesJson': '["img1.jpg", "img2.jpg"]',
        'isActive': true,
        'viewCount': 128,
        'createdAtUtc': '2026-11-02T10:00:00Z',
      };

      final ServiceSummary summary = ServiceSummary.fromJson(json);

      expect(summary.id, 101);
      expect(summary.memberId, 42);
      expect(summary.providerName, 'Rajesh Sharma');
      expect(summary.providerCompanyName, 'Sharma CNC Works');
      expect(summary.serviceCategory, 'Machining');
      expect(summary.startingPrice, 750.0);
      expect(summary.priceUnit, 'hr');
      expect(summary.isActive, isTrue);
      expect(summary.viewCount, 128);
    });

    test('ServiceDetail deserialization and ownership flag', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'id': 102,
        'memberId': 42,
        'providerName': 'Rajesh Sharma',
        'providerCompanyName': 'Sharma CNC Works',
        'providerEmail': 'rajesh@sharmacnc.in',
        'providerPhone': '+919876543210',
        'providerCity': 'Ahmedabad',
        'providerState': 'Gujarat',
        'title': 'Industrial Sheet Metal Fabrication',
        'description': 'Laser cutting, CNC bending, and TIG/MIG welding.',
        'serviceCategory': 'Fabrication',
        'industryId': 3,
        'industryName': 'Heavy Machinery',
        'serviceType': 'On-Site / Off-Site',
        'pricingModel': 'Quote-Based',
        'startingPrice': 5000.0,
        'priceUnit': 'project',
        'turnaroundTime': '7 days',
        'coverageArea': 'Pan-India',
        'location': 'Ahmedabad',
        'tagsJson': '["laser cutting", "bending", "welding"]',
        'imagesJson': '["sheet1.jpg"]',
        'certifications': 'ISO 9001:2015',
        'yearsOfExperience': 12,
        'isActive': true,
        'viewCount': 250,
        'createdAtUtc': '2026-11-01T08:00:00Z',
        'updatedAtUtc': '2026-11-02T12:00:00Z',
        'inquiryCount': 5,
        'isOwner': true,
      };

      final ServiceDetail detail = ServiceDetail.fromJson(json);

      expect(detail.id, 102);
      expect(detail.isOwner, isTrue);
      expect(detail.inquiryCount, 5);
      expect(detail.certifications, 'ISO 9001:2015');
      expect(detail.yearsOfExperience, 12);
      expect(detail.providerEmail, 'rajesh@sharmacnc.in');
    });

    test('CreateServiceRequest serialization', () {
      const CreateServiceRequest req = CreateServiceRequest(
        title: 'Transformer Rewinding & Overhaul',
        description: 'Complete inspection and rewinding up to 500 kVA.',
        serviceCategory: 'Electrical',
        industryId: 2,
        serviceType: 'On-Site',
        pricingModel: 'Fixed Price',
        startingPrice: 15000.0,
        priceUnit: 'unit',
        turnaroundTime: '4 days',
        coverageArea: 'Vadodara & Surat',
        location: 'Vadodara',
        certifications: 'BEE Certified',
        yearsOfExperience: 8,
      );

      final Map<String, dynamic> json = req.toJson();

      expect(json['title'], 'Transformer Rewinding & Overhaul');
      expect(json['serviceCategory'], 'Electrical');
      expect(json['industryId'], 2);
      expect(json['startingPrice'], 15000.0);
      expect(json['certifications'], 'BEE Certified');
      expect(json['yearsOfExperience'], 8);
    });

    test('UpdateServiceRequest serialization', () {
      const UpdateServiceRequest req = UpdateServiceRequest(
        title: 'Transformer Rewinding Updated',
        description: 'Updated scope with vacuum pressure impregnation.',
        serviceCategory: 'Electrical',
        startingPrice: 18000.0,
        isActive: false,
      );

      final Map<String, dynamic> json = req.toJson();

      expect(json['title'], 'Transformer Rewinding Updated');
      expect(json['startingPrice'], 18000.0);
      expect(json['isActive'], isFalse);
    });

    test('ServiceInquiry and History parsing from JSON', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'id': 501,
        'inquiryNumber': 'INQ-SRV-202611-001',
        'serviceId': 101,
        'serviceTitle': 'High Precision CNC Milling',
        'serviceCategory': 'Machining',
        'senderMemberId': 15,
        'senderName': 'Amit Patel',
        'senderCompanyName': 'Patel Engineering',
        'senderEmail': 'amit@pateleng.com',
        'senderPhone': '+919898989898',
        'recipientMemberId': 42,
        'recipientName': 'Rajesh Sharma',
        'recipientCompanyName': 'Sharma CNC Works',
        'subject': 'Inquiry for 50 CNC Impeller Units',
        'requirementDescription': 'Need SS316 impellers machined with +/- 0.02mm tolerance.',
        'scopeOfWork': 'Raw material provided by us, tooling by contractor.',
        'location': 'Ahmedabad',
        'preferredStartDate': '2026-11-15T00:00:00Z',
        'estimatedBudget': 50000.0,
        'urgency': 'High',
        'status': 3,
        'statusName': 'Responded',
        'responseMessage': 'We can deliver in 10 days at 950 INR/unit.',
        'respondedAtUtc': '2026-11-02T16:00:00Z',
        'createdAtUtc': '2026-11-02T10:00:00Z',
        'statusHistory': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 1,
            'previousStatus': null,
            'newStatus': 1,
            'statusName': 'Pending',
            'changedByMemberId': 15,
            'changedByName': 'Amit Patel',
            'changedAtUtc': '2026-11-02T10:00:00Z',
            'remarks': 'Inquiry submitted',
          },
          <String, dynamic>{
            'id': 2,
            'previousStatus': 1,
            'newStatus': 3,
            'statusName': 'Responded',
            'changedByMemberId': 42,
            'changedByName': 'Rajesh Sharma',
            'changedAtUtc': '2026-11-02T16:00:00Z',
            'remarks': 'Response sent with quotation',
          },
        ],
      };

      final ServiceInquiry inquiry = ServiceInquiry.fromJson(json);

      expect(inquiry.id, 501);
      expect(inquiry.inquiryNumber, 'INQ-SRV-202611-001');
      expect(inquiry.status, ServiceInquiryStatus.responded);
      expect(inquiry.urgency, 'High');
      expect(inquiry.estimatedBudget, 50000.0);
      expect(inquiry.responseMessage, 'We can deliver in 10 days at 950 INR/unit.');
      expect(inquiry.statusHistory.length, 2);
      expect(inquiry.statusHistory.first.newStatus, ServiceInquiryStatus.pending);
      expect(inquiry.statusHistory.last.newStatus, ServiceInquiryStatus.responded);
    });

    test('CreateServiceInquiryRequest serialization', () {
      final DateTime testDate = DateTime.utc(2026, 11, 20);
      final CreateServiceInquiryRequest req = CreateServiceInquiryRequest(
        serviceId: 101,
        subject: 'Custom Shaft Machining',
        requirementDescription: '10 shafts with EN8 steel.',
        scopeOfWork: 'Turning and keyway slotting.',
        location: 'Surat',
        preferredStartDate: testDate,
        estimatedBudget: 25000.0,
        urgency: 'Immediate',
      );

      final Map<String, dynamic> json = req.toJson();

      expect(json['serviceId'], 101);
      expect(json['subject'], 'Custom Shaft Machining');
      expect(json['scopeOfWork'], 'Turning and keyway slotting.');
      expect(json['location'], 'Surat');
      expect(json['preferredStartDate'], testDate.toIso8601String());
      expect(json['estimatedBudget'], 25000.0);
      expect(json['urgency'], 'Immediate');
    });

    test('RespondServiceInquiryRequest serialization', () {
      const RespondServiceInquiryRequest req = RespondServiceInquiryRequest(
        responseMessage: 'We accept your request. Calling you shortly.',
        acceptInquiry: true,
      );

      final Map<String, dynamic> json = req.toJson();

      expect(json['responseMessage'], 'We accept your request. Calling you shortly.');
      expect(json['acceptInquiry'], isTrue);
    });
  });
}
