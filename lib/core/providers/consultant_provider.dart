import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/consultant.dart';
import '../repositories/consultant_repository.dart';

class ConsultantProvider extends ChangeNotifier {
  ConsultantProvider(this._repo) {
    // Defer past the current build frame. The constructor is invoked lazily
    // by ChangeNotifierProvider during a build() call. Calling
    // notifyListeners() synchronously here would call markNeedsBuild() on a
    // widget that is already building, triggering the _dependents.isEmpty
    // assertion in InheritedElement.
    scheduleMicrotask(_loadAll);
  }

  final ConsultantRepository _repo;
  Timer? _debounce;
  bool _disposed = false;

  // Full unfiltered list — used by HomeScreen.
  List<Consultant> _allConsultants = [];
  // Filtered search results — used by SearchScreen.
  List<Consultant> _consultants = [];

  String _searchQuery = '';
  String? _selectedDomain;
  // Start true so the first frame already shows a loading indicator without
  // needing a synchronous notifyListeners() call in the constructor.
  bool _isLoading = true;
  String? _error;

  List<Consultant> get allConsultants => _allConsultants;
  List<Consultant> get consultants => _consultants;
  String get searchQuery => _searchQuery;
  String? get selectedDomain => _selectedDomain;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Loads every consultant once — for HomeScreen's local chip filter.
  // Called via scheduleMicrotask so it never runs inside a build().
  Future<void> _loadAll() async {
    _error = null;
    try {
      _allConsultants = await _repo.search();
      _consultants = List.from(_allConsultants);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  void onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _searchQuery = query;
      _fetch();
    });
  }

  void selectDomain(String? domain) {
    _selectedDomain = domain;
    _fetch();
  }

  void clearSearch() {
    _debounce?.cancel();
    _searchQuery = '';
    _fetch();
  }

  // Updates the filtered search list only. Called from user interactions
  // (tap, timer), never from build, so the leading notifyListeners() is safe.
  Future<void> _fetch() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _consultants = await _repo.search(
        query: _searchQuery.isEmpty ? null : _searchQuery,
        domain: _selectedDomain,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    super.dispose();
  }
}
