import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:connexa/core/network/api_client.dart';
import 'package:connexa/features/auth/models/auth_models.dart';
import 'package:connexa/features/recruitment/models/job_models.dart';

final Provider<JobRecruitmentService> jobRecruitmentServiceProvider =
    Provider<JobRecruitmentService>((Ref ref) {
  final Dio dio = ref.watch(dioProvider);
  return JobRecruitmentService(dio);
});

class JobRecruitmentService {
  JobRecruitmentService(this._dio);

  final Dio _dio;

  Future<(List<JobOpeningSummary> jobs, int totalCount)> searchJobs({
    String? query,
    int? industryId,
    String? jobType,
    String? workplaceType,
    String? city,
    String? state,
    int? minExperience,
    int? maxExperience,
    double? minSalary,
    JobOpeningStatus? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get(
        '/api/v1/jobs',
        queryParameters: <String, dynamic>{
          if (query != null && query.isNotEmpty) 'query': query,
          if (industryId != null && industryId > 0) 'industryId': industryId,
          if (jobType != null && jobType != 'All') 'jobType': jobType,
          if (workplaceType != null && workplaceType != 'All')
            'workplaceType': workplaceType,
          if (city != null && city.isNotEmpty) 'city': city,
          if (state != null && state.isNotEmpty) 'state': state,
          'minExperience': ?minExperience,
          'maxExperience': ?maxExperience,
          'minSalary': ?minSalary,
          if (status != null) 'status': status.toInt(),
          'page': page,
          'pageSize': pageSize,
        },
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] is List) {
        final List<JobOpeningSummary> list = (data['data'] as List)
            .map((e) => JobOpeningSummary.fromJson(e as Map<String, dynamic>))
            .toList();
        final int totalCount = data['count'] as int? ?? list.length;
        return (list, totalCount);
      }

      return (<JobOpeningSummary>[], 0);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<JobOpeningDetail> getJobById(int id) async {
    try {
      final Response<dynamic> response = await _dio.get('/api/v1/jobs/$id');
      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] != null) {
        return JobOpeningDetail.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw const AuthException('Job opening not found.');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<JobOpeningSummary>> getMyPostedJobs() async {
    try {
      final Response<dynamic> response = await _dio.get('/api/v1/jobs/my');
      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] is List) {
        return (data['data'] as List)
            .map((e) => JobOpeningSummary.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return <JobOpeningSummary>[];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<JobOpeningDetail> createJobOpening(CreateJobOpeningRequest request) async {
    try {
      final Response<dynamic> response = await _dio.post(
        '/api/v1/jobs',
        data: request.toJson(),
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] != null) {
        return JobOpeningDetail.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw const AuthException('Failed to create job opening.');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<JobOpeningDetail> updateJobOpening(
      int id, UpdateJobOpeningRequest request) async {
    try {
      final Response<dynamic> response = await _dio.put(
        '/api/v1/jobs/$id',
        data: request.toJson(),
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] != null) {
        return JobOpeningDetail.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw const AuthException('Failed to update job opening.');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> closeJobOpening(int id) async {
    try {
      final Response<dynamic> response =
          await _dio.put('/api/v1/jobs/$id/close');
      final dynamic data = response.data;
      return data is Map<String, dynamic> && data['success'] == true;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<JobApplicationDetail> applyForJob(
      SubmitJobApplicationRequest request) async {
    try {
      final Response<dynamic> response = await _dio.post(
        '/api/v1/job-applications',
        data: request.toJson(),
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] != null) {
        return JobApplicationDetail.fromJson(
            data['data'] as Map<String, dynamic>);
      }
      throw const AuthException('Failed to submit application.');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<JobApplicationSummary>> getMyApplications() async {
    try {
      final Response<dynamic> response =
          await _dio.get('/api/v1/job-applications/my');
      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] is List) {
        return (data['data'] as List)
            .map((e) => JobApplicationSummary.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return <JobApplicationSummary>[];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<JobApplicationSummary>> getApplicationsForJob(int jobId) async {
    try {
      final Response<dynamic> response =
          await _dio.get('/api/v1/job-applications/job/$jobId');
      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] is List) {
        return (data['data'] as List)
            .map((e) => JobApplicationSummary.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return <JobApplicationSummary>[];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<JobApplicationDetail> getApplicationById(int id) async {
    try {
      final Response<dynamic> response =
          await _dio.get('/api/v1/job-applications/$id');
      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] != null) {
        return JobApplicationDetail.fromJson(
            data['data'] as Map<String, dynamic>);
      }
      throw const AuthException('Job application not found.');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<JobApplicationDetail> updateApplicationStatus(
    int id,
    UpdateJobApplicationStatusRequest request,
  ) async {
    try {
      final Response<dynamic> response = await _dio.put(
        '/api/v1/job-applications/$id/status',
        data: request.toJson(),
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] != null) {
        return JobApplicationDetail.fromJson(
            data['data'] as Map<String, dynamic>);
      }
      throw const AuthException('Failed to update application status.');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> withdrawApplication(int id) async {
    try {
      final Response<dynamic> response =
          await _dio.put('/api/v1/job-applications/$id/withdraw');
      final dynamic data = response.data;
      return data is Map<String, dynamic> && data['success'] == true;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  AuthException _handleError(DioException e) {
    if (e.response?.data is Map<String, dynamic>) {
      final Map<String, dynamic> map =
          e.response!.data as Map<String, dynamic>;
      final String message = map['message'] as String? ??
          map['error'] as String? ??
          'An error occurred';
      return AuthException(
        message,
        statusCode: e.response?.statusCode,
      );
    }
    return AuthException(
      e.message ?? 'Network connection error',
      statusCode: e.response?.statusCode,
    );
  }
}
