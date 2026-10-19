import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:connexa/core/constants/api_constants.dart';
import 'package:connexa/core/errors/app_exceptions.dart';
import 'package:connexa/features/registration/models/industry_master_data.dart';
import 'package:connexa/features/registration/services/industry_master_data_service.dart';

void main() {
  group('Live Backend Integration Tests (Connexa.Api on port 5104)', () {
    late Dio liveDio;
    late IndustryMasterDataService service;

    setUp(() {
      liveDio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: <String, dynamic>{
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );
      service = IndustryMasterDataService(liveDio);
    });

    test('Live /health and /api/v1/health respond with status ok', () async {
      final Response<dynamic> rootHealth = await liveDio.get<dynamic>(
        '/health',
      );
      expect(rootHealth.statusCode, 200);
      expect((rootHealth.data as Map)['status'], 'ok');
      expect((rootHealth.data as Map)['service'], 'Connexa B2B API');

      final Response<dynamic> v1Health = await liveDio.get<dynamic>(
        '/api/v1/health',
      );
      expect(v1Health.statusCode, 200);
      expect((v1Health.data as Map)['status'], 'ok');
      expect((v1Health.data as Map)['version'], '1.0.0');
    });

    test(
      'Live Master Data 4-tier hierarchy for Manufacturing (MFG / ID: 4) validates real records',
      () async {
        // 1. Fetch real Industries
        final List<Industry> industries = await service.getIndustries();
        expect(industries.length, greaterThanOrEqualTo(4));
        expect(
          industries.any((Industry i) => i.id == 4 || i.code == 'MFG'),
          isTrue,
        );

        final Industry mfgIndustry = industries.firstWhere(
          (Industry i) => i.id == 4 || i.code == 'MFG',
        );
        expect(mfgIndustry.name, 'Manufacturing & Heavy Engineering');
        expect(mfgIndustry.code, 'MFG');

        // 2. Fetch real Business Groups for MFG (ID: 4)
        final List<BusinessGroup> businessGroups = await service
            .getBusinessGroups(mfgIndustry.id);
        expect(businessGroups.length, greaterThanOrEqualTo(2));
        for (final BusinessGroup group in businessGroups) {
          expect(group.industryId, mfgIndustry.id);
        }

        final BusinessGroup machGroup = businessGroups.firstWhere(
          (BusinessGroup g) => g.id == 3 || g.code == 'MACH',
        );
        expect(machGroup.name, 'Machinery & Equipment');
        expect(machGroup.code, 'MACH');

        // 3. Fetch real SubGroups for MACH (ID: 3)
        final List<SubGroup> subGroups = await service.getSubGroups(
          machGroup.id,
        );
        expect(subGroups.length, greaterThanOrEqualTo(2));
        for (final SubGroup sg in subGroups) {
          expect(sg.businessGroupId, machGroup.id);
        }

        final SubGroup cncSubGroup = subGroups.firstWhere(
          (SubGroup sg) => sg.id == 3 || sg.code == 'CNC',
        );
        expect(cncSubGroup.name, 'CNC & Machine Tools');
        expect(cncSubGroup.code, 'CNC');

        // 4. Fetch real Categories for CNC (ID: 3)
        final List<Category> categories = await service.getCategories(
          cncSubGroup.id,
        );
        expect(categories.length, greaterThanOrEqualTo(4));
        for (final Category cat in categories) {
          expect(cat.subGroupId, cncSubGroup.id);
        }

        final Category latheCat = categories.firstWhere(
          (Category c) => c.id == 13 || c.code == 'LATH',
        );
        expect(latheCat.name, 'CNC Lathes & Turning Centers');
        expect(latheCat.code, 'LATH');

        // 5. Construct complete IndustrySelection with real database IDs
        final IndustrySelection selection = IndustrySelection(
          industryId: mfgIndustry.id,
          industryName: mfgIndustry.name,
          businessGroupId: machGroup.id,
          businessGroupName: machGroup.name,
          subGroupId: cncSubGroup.id,
          subGroupName: cncSubGroup.name,
          categoryId: latheCat.id,
          categoryName: latheCat.name,
        );

        expect(selection.isComplete, isTrue);
        expect(
          selection.displayPath,
          'Manufacturing & Heavy Engineering > Machinery & Equipment > CNC & Machine Tools > CNC Lathes & Turning Centers',
        );
      },
    );

    test(
      'Live Master Data 4-tier hierarchy for Automotive (AUTO / ID: 1) validates real records',
      () async {
        // 1. Fetch real Industries
        final List<Industry> industries = await service.getIndustries();
        final Industry autoIndustry = industries.firstWhere(
          (Industry i) => i.id == 1 || i.code == 'AUTO',
        );
        expect(autoIndustry.name, 'Automotive & Mobility Solutions');

        // 2. Fetch Business Groups
        final List<BusinessGroup> groups = await service.getBusinessGroups(
          autoIndustry.id,
        );
        expect(groups, isNotEmpty);
        final BusinessGroup autoComp = groups.firstWhere(
          (BusinessGroup g) => g.id == 1 || g.code == 'ACOMP',
        );
        expect(autoComp.name, 'OEM Components & Sub-Assemblies');

        // 3. Fetch SubGroups
        final List<SubGroup> subGroups = await service.getSubGroups(
          autoComp.id,
        );
        expect(subGroups, isNotEmpty);
        final SubGroup chassis = subGroups.firstWhere(
          (SubGroup sg) => sg.id == 2 || sg.code == 'CHAS',
        );
        expect(chassis.name, 'Chassis & Braking Systems');

        // 4. Fetch Categories
        final List<Category> categories = await service.getCategories(
          chassis.id,
        );
        expect(categories, isNotEmpty);
        expect(
          categories.any((Category c) => c.id == 1 || c.code == 'AXLE'),
          isTrue,
        );
      },
    );

    test(
      'Non-existent parent ID throws ApiException with 404 status',
      () async {
        expect(
          () => service.getBusinessGroups(99999),
          throwsA(
            isA<ApiException>().having(
              (ApiException e) => e.statusCode,
              'statusCode',
              404,
            ),
          ),
        );
      },
    );
  });
}
