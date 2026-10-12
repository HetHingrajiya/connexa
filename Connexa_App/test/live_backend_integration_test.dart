import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:connexa/core/constants/api_constants.dart';
import 'package:connexa/features/registration/models/industry_master_data.dart';
import 'package:connexa/features/registration/services/industry_master_data_service.dart';

void main() {
  group('Live Backend Integration Tests (E:\\Connexa_API on port 5000)', () {
    late Dio liveDio;
    late IndustryMasterDataService service;

    setUp(() {
      liveDio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          headers: <String, dynamic>{
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );
      service = IndustryMasterDataService(liveDio);
    });

    test('Live /health responds with status ok', () async {
      final Response<dynamic> response = await liveDio.get<dynamic>('/health');
      expect(response.statusCode, 200);
      expect((response.data as Map)['status'], 'ok');
    });

    test(
      'Live Master Data 4-tier hierarchy loads genuine database records and validates parent-child integrity',
      () async {
        // 1. Fetch real Industries
        final List<Industry> industries = await service.getIndustries();
        expect(industries, isNotEmpty);
        expect(industries.any((Industry i) => i.id == 'ind_mfg'), isTrue);

        final Industry mfgIndustry = industries.firstWhere(
          (Industry i) => i.id == 'ind_mfg',
        );
        expect(mfgIndustry.name, 'Manufacturing & Heavy Engineering');

        // 2. Fetch real Business Groups for ind_mfg
        final List<BusinessGroup> businessGroups = await service
            .getBusinessGroups(mfgIndustry.id);
        expect(businessGroups, isNotEmpty);
        for (final BusinessGroup group in businessGroups) {
          expect(group.industryId, mfgIndustry.id);
        }

        final BusinessGroup machGroup = businessGroups.firstWhere(
          (BusinessGroup g) => g.id == 'bg_mach',
        );
        expect(machGroup.name, 'Machinery & Equipment');

        // 3. Fetch real SubGroups for bg_mach
        final List<SubGroup> subGroups = await service.getSubGroups(
          machGroup.id,
        );
        expect(subGroups, isNotEmpty);
        for (final SubGroup sg in subGroups) {
          expect(sg.businessGroupId, machGroup.id);
        }

        final SubGroup cncSubGroup = subGroups.firstWhere(
          (SubGroup sg) => sg.id == 'sg_cnc',
        );
        expect(cncSubGroup.name, 'CNC & Machine Tools');

        // 4. Fetch real Categories for sg_cnc
        final List<Category> categories = await service.getCategories(
          cncSubGroup.id,
        );
        expect(categories, isNotEmpty);
        for (final Category cat in categories) {
          expect(cat.subGroupId, cncSubGroup.id);
        }

        final Category latheCat = categories.firstWhere(
          (Category c) => c.id == 'cat_lathe',
        );
        expect(latheCat.name, 'CNC Lathes & Turning Centers');

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
  });
}
