import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../../wallet/providers/wallet_provider.dart';
import '../data/project_models.dart';

class ClientProjectsState {
  const ClientProjectsState({
    this.projects = const [],
    this.proposals = const [],
    this.contracts = const [],
    this.loaded = false,
    this.error,
  });

  final List<ProjectPost> projects;
  final List<Proposal> proposals;
  final List<ContractModel> contracts;
  final bool loaded;
  final String? error;

  ProjectPost? project(String id) {
    for (final p in projects) {
      if (p.id == id) return p;
    }
    return null;
  }

  Proposal? proposal(String id) {
    for (final p in proposals) {
      if (p.id == id) return p;
    }
    return null;
  }

  ContractModel? contract(String id) {
    for (final c in contracts) {
      if (c.id == id) return c;
    }
    return null;
  }

  ContractModel? contractForProject(String projectId) {
    for (final c in contracts) {
      if (c.projectId == projectId) return c;
    }
    return null;
  }

  List<Proposal> proposalsFor(String projectId) =>
      proposals.where((p) => p.projectId == projectId).toList();

  List<ContractModel> get activeContracts =>
      contracts.where((c) => c.status == ContractStatus.active).toList();

  int get awaitingReview => contracts
      .where((c) => c.status == ContractStatus.active && c.awaitingReview)
      .length;

  ClientProjectsState copyWith({
    List<ProjectPost>? projects,
    List<Proposal>? proposals,
    List<ContractModel>? contracts,
    bool? loaded,
    String? error,
  }) => ClientProjectsState(
    projects: projects ?? this.projects,
    proposals: proposals ?? this.proposals,
    contracts: contracts ?? this.contracts,
    loaded: loaded ?? this.loaded,
    error: error,
  );
}

/// The client's freelance projects, proposals received and contracts.
/// Escrow funding, releases and refunds happen on the server; after each
/// money action the wallet is refreshed. Methods throw [ApiException].
class ClientProjectsNotifier extends StateNotifier<ClientProjectsState> {
  ClientProjectsNotifier(this._ref, {bool autoLoad = true})
    : super(const ClientProjectsState()) {
    if (autoLoad) load();
  }

  final Ref _ref;

  Future<void> load() async {
    try {
      final r = await Future.wait([
        api.get('/client/projects'),
        api.get('/client/proposals'),
        api.get('/contracts'),
      ]);
      if (!mounted) return;
      state = ClientProjectsState(
        projects: jMapList(r[0]).map(ProjectPost.fromJson).toList(),
        proposals: jMapList(r[1]).map(Proposal.fromJson).toList(),
        contracts: jMapList(r[2]).map(ContractModel.fromJson).toList(),
        loaded: true,
      );
    } on ApiException catch (e) {
      if (mounted) state = state.copyWith(loaded: true, error: e.message);
    }
  }

  Future<void> _refreshWallet() => _ref.read(walletProvider.notifier).load();

  void _putProject(ProjectPost p) {
    final exists = state.projects.any((x) => x.id == p.id);
    state = state.copyWith(
      projects: exists
          ? [for (final x in state.projects) x.id == p.id ? p : x]
          : [p, ...state.projects],
    );
  }

  void _putContract(ContractModel c) {
    final exists = state.contracts.any((x) => x.id == c.id);
    state = state.copyWith(
      contracts: exists
          ? [for (final x in state.contracts) x.id == c.id ? c : x]
          : [c, ...state.contracts],
    );
  }

  Future<ProjectPost> saveProject(
    ProjectPost project, {
    String visibility = 'Public',
  }) async {
    final isNew = project.id.isEmpty || state.project(project.id) == null;
    final body = project.toJson(visibility: visibility);
    final saved = ProjectPost.fromJson(
      jMap(
        isNew
            ? await api.post('/client/projects', body)
            : await api.patch('/client/projects/${project.id}', body),
      ),
    );
    _putProject(saved);
    return saved;
  }

  Future<void> setProjectStatus(String projectId, ProjectStatus status) async {
    _putProject(
      ProjectPost.fromJson(
        jMap(
          await api.patch('/client/projects/$projectId/status', {
            'status': status.name,
          }),
        ),
      ),
    );
  }

  Future<void> deleteProject(String projectId) async {
    await api.delete('/client/projects/$projectId');
    state = state.copyWith(
      projects: state.projects.where((p) => p.id != projectId).toList(),
      proposals: state.proposals
          .where((p) => p.projectId != projectId)
          .toList(),
    );
  }

  /// Opening a proposal marks it viewed for the freelancer.
  Future<void> markViewed(String proposalId) async {
    try {
      await api.get('/client/proposals/$proposalId');
    } on ApiException catch (_) {
      // Best effort — the details are already on screen.
    }
  }

  Future<void> setProposalStatus(
    String proposalId,
    ProposalStatus status,
  ) async {
    final p = Proposal.fromJson(
      jMap(
        await api.patch('/client/proposals/$proposalId', {
          'status': status == ProposalStatus.received ? 'viewed' : status.name,
        }),
      ),
    );
    state = state.copyWith(
      proposals: [for (final x in state.proposals) x.id == p.id ? p : x],
    );
  }

  /// Hires the freelancer; the server funds milestone 1 from the wallet.
  Future<ContractModel> hire(
    String proposalId,
    List<Milestone> milestones,
  ) async {
    final contract = ContractModel.fromJson(
      jMap(
        await api.post('/client/proposals/$proposalId/hire', {
          'milestones': [for (final m in milestones) m.toJson()],
        }),
      ),
    );
    await Future.wait([load(), _refreshWallet()]);
    return contract;
  }

  Future<void> _contractAction(String path, [Object? body]) async {
    _putContract(ContractModel.fromJson(jMap(await api.post(path, body))));
  }

  Future<void> fundMilestone(String contractId, int index) async {
    await _contractAction('/contracts/$contractId/milestones/$index/fund');
    await _refreshWallet();
  }

  Future<void> releaseMilestone(String contractId, int index) async {
    await _contractAction('/contracts/$contractId/milestones/$index/release');
    await _refreshWallet();
  }

  Future<void> requestRevision(String contractId, int index, String note) =>
      _contractAction('/contracts/$contractId/milestones/$index/revision', {
        'note': note,
      });

  Future<void> addMilestone(String contractId, Milestone milestone) =>
      _contractAction('/contracts/$contractId/milestones', milestone.toJson());

  Future<void> endContract(
    String contractId,
    double rating,
    String review,
  ) async {
    await _contractAction('/contracts/$contractId/end', {
      'rating': rating,
      'review': review,
    });
    await Future.wait([load(), _refreshWallet()]);
  }
}

final clientProjectsProvider =
    StateNotifierProvider<ClientProjectsNotifier, ClientProjectsState>((ref) {
      final userId = ref.watch(sessionUserIdProvider);
      return ClientProjectsNotifier(ref, autoLoad: userId != null);
    });
