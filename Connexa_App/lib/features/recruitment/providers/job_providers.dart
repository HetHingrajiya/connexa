import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connexa/features/recruitment/models/job_models.dart';
import 'package:connexa/features/recruitment/services/job_recruitment_service.dart';

class JobListingsState {
  const JobListingsState({
    this.jobs = const <JobOpeningSummary>[],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
    this.selectedJobType = 'All',
    this.selectedWorkplaceType = 'All',
    this.city = '',
    this.page = 1,
    this.totalCount = 0,
    this.hasMore = false,
  });

  final List<JobOpeningSummary> jobs;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;
  final String selectedJobType;
  final String selectedWorkplaceType;
  final String city;
  final int page;
  final int totalCount;
  final bool hasMore;

  JobListingsState copyWith({
    List<JobOpeningSummary>? jobs,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    String? selectedJobType,
    String? selectedWorkplaceType,
    String? city,
    int? page,
    int? totalCount,
    bool? hasMore,
  }) {
    return JobListingsState(
      jobs: jobs ?? this.jobs,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedJobType: selectedJobType ?? this.selectedJobType,
      selectedWorkplaceType: selectedWorkplaceType ?? this.selectedWorkplaceType,
      city: city ?? this.city,
      page: page ?? this.page,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class JobListingsNotifier extends StateNotifier<JobListingsState> {
  JobListingsNotifier(this._service) : super(const JobListingsState()) {
    loadJobs();
  }

  final JobRecruitmentService _service;

  Future<void> loadJobs() async {
    state = state.copyWith(isLoading: true, errorMessage: null, page: 1);
    try {
      final (List<JobOpeningSummary> list, int total) =
          await _service.searchJobs(
        query: state.searchQuery,
        jobType: state.selectedJobType,
        workplaceType: state.selectedWorkplaceType,
        city: state.city,
        page: 1,
        pageSize: 20,
      );

      state = state.copyWith(
        jobs: list,
        isLoading: false,
        totalCount: total,
        hasMore: list.length < total,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> search(String query) async {
    state = state.copyWith(searchQuery: query);
    await loadJobs();
  }

  Future<void> setJobType(String jobType) async {
    state = state.copyWith(selectedJobType: jobType);
    await loadJobs();
  }

  Future<void> setWorkplaceType(String workplaceType) async {
    state = state.copyWith(selectedWorkplaceType: workplaceType);
    await loadJobs();
  }

  Future<void> setCity(String city) async {
    state = state.copyWith(city: city);
    await loadJobs();
  }

  Future<void> loadNextPage() async {
    if (state.isLoading || !state.hasMore) return;

    final int nextPage = state.page + 1;
    try {
      final (List<JobOpeningSummary> list, int total) =
          await _service.searchJobs(
        query: state.searchQuery,
        jobType: state.selectedJobType,
        workplaceType: state.selectedWorkplaceType,
        city: state.city,
        page: nextPage,
        pageSize: 20,
      );

      final List<JobOpeningSummary> merged = <JobOpeningSummary>[
        ...state.jobs,
        ...list
      ];
      state = state.copyWith(
        jobs: merged,
        page: nextPage,
        totalCount: total,
        hasMore: merged.length < total,
      );
    } catch (_) {
      // Keep existing list on pagination failure
    }
  }

  Future<void> refresh() async => loadJobs();
}

final StateNotifierProvider<JobListingsNotifier, JobListingsState>
    jobListingsProvider =
    StateNotifierProvider<JobListingsNotifier, JobListingsState>(
  (Ref ref) => JobListingsNotifier(ref.watch(jobRecruitmentServiceProvider)),
);

class MyJobPostingsState {
  const MyJobPostingsState({
    this.jobs = const <JobOpeningSummary>[],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<JobOpeningSummary> jobs;
  final bool isLoading;
  final String? errorMessage;
}

class MyJobPostingsNotifier extends StateNotifier<MyJobPostingsState> {
  MyJobPostingsNotifier(this._service) : super(const MyJobPostingsState()) {
    load();
  }

  final JobRecruitmentService _service;

  Future<void> load() async {
    state = MyJobPostingsState(
      jobs: state.jobs,
      isLoading: true,
    );
    try {
      final List<JobOpeningSummary> list = await _service.getMyPostedJobs();
      state = MyJobPostingsState(jobs: list, isLoading: false);
    } catch (e) {
      state = MyJobPostingsState(
        jobs: state.jobs,
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> closeJob(int id) async {
    try {
      final bool ok = await _service.closeJobOpening(id);
      if (ok) {
        state = MyJobPostingsState(
          jobs: state.jobs.map((j) {
            if (j.id == id) {
              return JobOpeningSummary(
                id: j.id,
                memberId: j.memberId,
                employerName: j.employerName,
                employerCompanyName: j.employerCompanyName,
                employerCity: j.employerCity,
                employerState: j.employerState,
                isEmployerVerified: j.isEmployerVerified,
                title: j.title,
                department: j.department,
                industryId: j.industryId,
                industryName: j.industryName,
                jobType: j.jobType,
                workplaceType: j.workplaceType,
                city: j.city,
                state: j.state,
                minExperienceYears: j.minExperienceYears,
                maxExperienceYears: j.maxExperienceYears,
                minSalary: j.minSalary,
                maxSalary: j.maxSalary,
                salaryPeriod: j.salaryPeriod,
                openingsCount: j.openingsCount,
                status: JobOpeningStatus.closed,
                applicationsCount: j.applicationsCount,
                viewCount: j.viewCount,
                createdAtUtc: j.createdAtUtc,
                applicationDeadlineUtc: j.applicationDeadlineUtc,
              );
            }
            return j;
          }).toList(),
          isLoading: false,
        );
      }
      return ok;
    } catch (_) {
      return false;
    }
  }

  Future<void> refresh() async => load();
}

final StateNotifierProvider<MyJobPostingsNotifier, MyJobPostingsState>
    myJobPostingsProvider =
    StateNotifierProvider<MyJobPostingsNotifier, MyJobPostingsState>(
  (Ref ref) => MyJobPostingsNotifier(ref.watch(jobRecruitmentServiceProvider)),
);

class MyJobApplicationsState {
  const MyJobApplicationsState({
    this.applications = const <JobApplicationSummary>[],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<JobApplicationSummary> applications;
  final bool isLoading;
  final String? errorMessage;
}

class MyJobApplicationsNotifier
    extends StateNotifier<MyJobApplicationsState> {
  MyJobApplicationsNotifier(this._service)
      : super(const MyJobApplicationsState()) {
    load();
  }

  final JobRecruitmentService _service;

  Future<void> load() async {
    state = MyJobApplicationsState(
      applications: state.applications,
      isLoading: true,
    );
    try {
      final List<JobApplicationSummary> list =
          await _service.getMyApplications();
      state = MyJobApplicationsState(applications: list, isLoading: false);
    } catch (e) {
      state = MyJobApplicationsState(
        applications: state.applications,
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> withdraw(int id) async {
    try {
      final bool ok = await _service.withdrawApplication(id);
      if (ok) {
        state = MyJobApplicationsState(
          applications: state.applications.map((a) {
            if (a.id == id) {
              return JobApplicationSummary(
                id: a.id,
                applicationNumber: a.applicationNumber,
                jobOpeningId: a.jobOpeningId,
                jobTitle: a.jobTitle,
                employerCompanyName: a.employerCompanyName,
                applicantMemberId: a.applicantMemberId,
                fullName: a.fullName,
                email: a.email,
                phone: a.phone,
                currentCompany: a.currentCompany,
                currentDesignation: a.currentDesignation,
                yearsOfExperience: a.yearsOfExperience,
                expectedSalary: a.expectedSalary,
                resumeUrl: a.resumeUrl,
                resumeFileName: a.resumeFileName,
                status: JobApplicationStatus.withdrawn,
                statusName: 'Withdrawn',
                createdAtUtc: a.createdAtUtc,
              );
            }
            return a;
          }).toList(),
          isLoading: false,
        );
      }
      return ok;
    } catch (_) {
      return false;
    }
  }

  Future<void> refresh() async => load();
}

final StateNotifierProvider<MyJobApplicationsNotifier,
        MyJobApplicationsState>
    myJobApplicationsProvider = StateNotifierProvider<
        MyJobApplicationsNotifier, MyJobApplicationsState>(
  (Ref ref) =>
      MyJobApplicationsNotifier(ref.watch(jobRecruitmentServiceProvider)),
);

final AutoDisposeFutureProviderFamily<JobOpeningDetail, int>
    jobDetailProvider =
    FutureProvider.autoDispose.family<JobOpeningDetail, int>(
  (Ref ref, int jobId) async {
    return ref.watch(jobRecruitmentServiceProvider).getJobById(jobId);
  },
);

final AutoDisposeFutureProviderFamily<JobApplicationDetail, int>
    jobApplicationDetailProvider =
    FutureProvider.autoDispose.family<JobApplicationDetail, int>(
  (Ref ref, int applicationId) async {
    return ref
        .watch(jobRecruitmentServiceProvider)
        .getApplicationById(applicationId);
  },
);

final AutoDisposeFutureProviderFamily<List<JobApplicationSummary>, int>
    jobApplicantsForPostProvider = FutureProvider.autoDispose
        .family<List<JobApplicationSummary>, int>(
  (Ref ref, int jobId) async {
    return ref
        .watch(jobRecruitmentServiceProvider)
        .getApplicationsForJob(jobId);
  },
);

