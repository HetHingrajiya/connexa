import 'package:flutter_test/flutter_test.dart';

import 'package:connexa/features/job_work/models/job_work_models.dart';

void main() {
  group('Job Work Models Tests', () {
    test('JobWorkRequirementStatus parsing', () {
      expect(JobWorkRequirementStatus.fromString('Open'), JobWorkRequirementStatus.open);
      expect(JobWorkRequirementStatus.fromString('Closed'), JobWorkRequirementStatus.closed);
      expect(JobWorkRequirementStatus.fromString('Cancelled'), JobWorkRequirementStatus.cancelled);
      expect(JobWorkRequirementStatus.fromString('nonexistent'), JobWorkRequirementStatus.open);
    });

    test('MaterialResponsibility parsing', () {
      expect(MaterialResponsibility.fromString('BuyerSupplied'), MaterialResponsibility.buyerSupplied);
      expect(MaterialResponsibility.fromString('contractorsupplied'), MaterialResponsibility.contractorSupplied);
      expect(MaterialResponsibility.fromString('sharedornegotiable'), MaterialResponsibility.sharedOrNegotiable);
      expect(MaterialResponsibility.buyerSupplied.label, 'Buyer Supplied');
      expect(MaterialResponsibility.contractorSupplied.label, 'Contractor Supplied');
      expect(MaterialResponsibility.sharedOrNegotiable.label, 'Negotiable / Shared');
    });

    test('JobWorkQuotationStatus parsing', () {
      expect(JobWorkQuotationStatus.fromString('Submitted'), JobWorkQuotationStatus.submitted);
      expect(JobWorkQuotationStatus.fromString('RevisionRequested'), JobWorkQuotationStatus.revisionRequested);
      expect(JobWorkQuotationStatus.fromString('Accepted'), JobWorkQuotationStatus.accepted);
      expect(JobWorkQuotationStatus.fromString('Rejected'), JobWorkQuotationStatus.rejected);
      expect(JobWorkQuotationStatus.fromString('Withdrawn'), JobWorkQuotationStatus.withdrawn);
      expect(JobWorkQuotationStatus.fromString('unknown'), JobWorkQuotationStatus.submitted);
      expect(JobWorkQuotationStatus.submitted.label, 'Submitted');
      expect(JobWorkQuotationStatus.accepted.label, 'Accepted');
    });

    test('JobWorkOrderStatus parsing', () {
      expect(JobWorkOrderStatus.fromString('PendingConfirmation'), JobWorkOrderStatus.pendingConfirmation);
      expect(JobWorkOrderStatus.fromString('Confirmed'), JobWorkOrderStatus.confirmed);
      expect(JobWorkOrderStatus.fromString('processing'), JobWorkOrderStatus.processing);
      expect(JobWorkOrderStatus.fromString('Completed'), JobWorkOrderStatus.completed);
      expect(JobWorkOrderStatus.fromString('Cancelled'), JobWorkOrderStatus.cancelled);
      expect(JobWorkOrderStatus.fromString('rejected'), JobWorkOrderStatus.rejected);
      expect(JobWorkOrderStatus.confirmed.label, 'Confirmed');
      expect(JobWorkOrderStatus.completed.label, 'Completed');
    });

    test('JobWorkRequirement JSON roundtrip', () {
      final now = DateTime.utc(2026, 11, 2, 10, 0, 0);
      final json = <String, dynamic>{
        'id': 101,
        'requirementNumber': 'JWR-20261102-12345',
        'ownerMemberId': 12,
        'ownerFullName': 'Rajesh Sharma',
        'ownerCompanyName': 'Apex Engineering',
        'title': 'High Precision CNC Milling for Turbine Impeller',
        'description': 'Machining turbine impellers with tight tolerances.',
        'industryId': 1,
        'industryName': 'Heavy Machinery',
        'jobWorkProcess': 'CNC Milling',
        'machineType': '5-Axis VMC',
        'materialType': 'SS316 Stainless Steel',
        'materialResponsibility': 'BuyerSupplied',
        'quantity': 50.0,
        'unitOfMeasurement': 'Pcs',
        'requiredTolerance': '±0.005 mm',
        'location': 'Sanand GIDC, Ahmedabad',
        'targetBudget': 1250.0,
        'status': 'Open',
        'createdAtUtc': now.toIso8601String(),
        'quotationsCount': 3,
        'hasQuoted': true,
        'isOwner': true,
        'attachments': <Map<String, dynamic>>[
          {
            'id': 1,
            'jobWorkRequirementId': 101,
            'uploadedByMemberId': 12,
            'originalFileName': 'turbine_impeller_blueprint.pdf',
            'storedFileName': 'guid.pdf',
            'fileExtension': '.pdf',
            'fileSizeBytes': 2048500,
            'contentType': 'application/pdf',
            'downloadUrl': '/api/jobworks/attachments/1',
            'uploadedAtUtc': now.toIso8601String(),
          }
        ],
      };

      final req = JobWorkRequirement.fromJson(json);
      expect(req.id, 101);
      expect(req.requirementNumber, 'JWR-20261102-12345');
      expect(req.jobWorkProcess, 'CNC Milling');
      expect(req.materialResponsibility, MaterialResponsibility.buyerSupplied);
      expect(req.materialResponsibility.label, 'Buyer Supplied');
      expect(req.ownerMemberId, 12);
      expect(req.isOwner, isTrue);
      expect(req.status, JobWorkRequirementStatus.open);
      expect(req.attachments.length, 1);
      expect(req.attachments.first.formattedFileSize, '2.0 MB');
    });

    test('JobWorkQuotation JSON roundtrip and status styling', () {
      final now = DateTime.utc(2026, 11, 2, 12, 0, 0);
      final json = <String, dynamic>{
        'id': 501,
        'quotationNumber': 'JWQ-20261102-ABCDE',
        'jobWorkRequirementId': 101,
        'requirementNumber': 'JWR-20261102-12345',
        'requirementTitle': 'High Precision CNC Milling',
        'contractorMemberId': 25,
        'contractorFullName': 'Anil Patel',
        'contractorCompanyName': 'Precision Tech Machining',
        'offeredUnitPrice': 1100.0,
        'quantity': 50.0,
        'subtotal': 55000.0,
        'taxRatePercent': 18.0,
        'taxAmount': 9900.0,
        'otherCharges': 0.0,
        'totalAmount': 64900.0,
        'leadTimeDays': 14,
        'machineProposed': 'Haas VF-4 5-Axis VMC',
        'status': 'Submitted',
        'createdAtUtc': now.toIso8601String(),
      };

      final quote = JobWorkQuotation.fromJson(json);
      expect(quote.id, 501);
      expect(quote.totalAmount, 64900.0);
      expect(quote.leadTimeDays, 14);
      expect(quote.leadTimeFormatted, '14 days');
      expect(quote.status, JobWorkQuotationStatus.submitted);
      expect(quote.status.label, 'Submitted');
    });

    test('JobWorkOrder JSON roundtrip and status flow', () {
      final now = DateTime.utc(2026, 11, 2, 14, 0, 0);
      final json = <String, dynamic>{
        'id': 901,
        'orderNumber': 'JWO-20261102-77777',
        'jobWorkRequirementId': 101,
        'requirementNumber': 'JWR-20261102-12345',
        'jobWorkQuotationId': 501,
        'quotationNumber': 'JWQ-20261102-ABCDE',
        'buyerMemberId': 12,
        'buyerFullName': 'Rajesh Sharma',
        'buyerCompanyName': 'Apex Engineering',
        'contractorMemberId': 25,
        'contractorFullName': 'Anil Patel',
        'contractorCompanyName': 'Precision Tech Machining',
        'jobTitle': 'High Precision CNC Milling',
        'process': 'CNC Milling',
        'quantity': 50.0,
        'unitOfMeasurement': 'Pcs',
        'agreedUnitPrice': 1100.0,
        'subtotal': 55000.0,
        'taxAmount': 9900.0,
        'otherCharges': 0.0,
        'totalAmount': 64900.0,
        'leadTimeDays': 14,
        'deliveryLocation': 'Sanand GIDC, Ahmedabad',
        'status': 'Processing',
        'createdAtUtc': now.toIso8601String(),
        'isBuyer': true,
        'isContractor': false,
        'statusHistory': <Map<String, dynamic>>[
          {
            'id': 1,
            'jobWorkOrderId': 901,
            'previousStatus': 'Confirmed',
            'newStatus': 'Processing',
            'changedByMemberId': 25,
            'changedByMemberName': 'Anil Patel',
            'changedByCompanyName': 'Precision Tech Machining',
            'remarks': 'Raw material received, machining started on Haas VMC.',
            'changedAtUtc': now.toIso8601String(),
          }
        ],
      };

      final order = JobWorkOrder.fromJson(json);
      expect(order.id, 901);
      expect(order.orderNumber, 'JWO-20261102-77777');
      expect(order.status, JobWorkOrderStatus.processing);
      expect(order.isContractor, isFalse);
      expect(order.isBuyer, isTrue);
      expect(order.statusHistory.length, 1);
      expect(order.statusHistory.first.newStatus, 'Processing');
    });
  });
}
