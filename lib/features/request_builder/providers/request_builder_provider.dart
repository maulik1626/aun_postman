import 'package:aun_postman/domain/enums/http_method.dart';
import 'package:aun_postman/domain/models/collection.dart';
import 'package:aun_postman/domain/models/auth_config.dart';
import 'package:aun_postman/domain/models/http_request.dart';
import 'package:aun_postman/domain/models/key_value_pair.dart';
import 'package:aun_postman/domain/models/request_body.dart';
import 'package:aun_postman/domain/models/test_assertion.dart';
import 'package:aun_postman/features/collections/providers/collections_provider.dart';
import 'package:aun_postman/infrastructure/collection_repository.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'request_builder_provider.freezed.dart';
part 'request_builder_provider.g.dart';

@freezed
class RequestBuilderState with _$RequestBuilderState {
  const factory RequestBuilderState({
    @Default(HttpMethod.get) HttpMethod method,
    @Default('') String url,
    @Default([]) List<RequestParam> params,
    @Default([]) List<RequestHeader> headers,
    @Default(NoBody()) RequestBody body,
    @Default(NoAuth()) AuthConfig auth,
    String? loadedRequestUid,
    String? collectionUid,
    String? folderUid,
    @Default('New Request') String name,
    @Default(false) bool isDirty,
    @Default([]) List<TestAssertion> assertions,
  }) = _RequestBuilderState;
}

@riverpod
class RequestBuilder extends _$RequestBuilder {
  static const _uuid = Uuid();

  @override
  RequestBuilderState build() => const RequestBuilderState();

  void setMethod(HttpMethod method) =>
      state = state.copyWith(method: method, isDirty: true);

  void setUrl(String url) => state = state.copyWith(url: url, isDirty: true);

  void setName(String name) =>
      state = state.copyWith(name: name, isDirty: true);

  void setParams(List<RequestParam> params) =>
      state = state.copyWith(params: params, isDirty: true);

  void setHeaders(List<RequestHeader> headers) =>
      state = state.copyWith(headers: headers, isDirty: true);

  void setBody(RequestBody body) =>
      state = state.copyWith(body: body, isDirty: true);

  void setAuth(AuthConfig auth) =>
      state = state.copyWith(auth: auth, isDirty: true);

  void setAssertions(List<TestAssertion> assertions) =>
      state = state.copyWith(assertions: assertions, isDirty: true);

  void loadFromRequest(HttpRequest request) {
    state = RequestBuilderState(
      method: request.method,
      url: request.url,
      params: request.params,
      headers: request.headers,
      body: request.body,
      auth: request.auth,
      loadedRequestUid: request.uid,
      collectionUid: request.collectionUid,
      folderUid: request.folderUid,
      name: request.name,
      isDirty: false,
    );
  }

  HttpRequest toRequest() {
    final now = DateTime.now();
    return HttpRequest(
      uid: state.loadedRequestUid ?? _uuid.v4(),
      name: state.name,
      method: state.method,
      url: state.url,
      params: state.params,
      headers: state.headers,
      body: state.body,
      auth: state.auth,
      collectionUid: state.collectionUid,
      folderUid: state.folderUid,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> saveToCollection(String collectionUid) async {
    final now = DateTime.now();
    final repo = ref.read(collectionRepositoryProvider);
    final collection = repo.getByUid(collectionUid);
    if (collection == null) return;

    final folderUid = state.folderUid;
    final requestUid = state.loadedRequestUid ?? _uuid.v4();

    // Find original createdAt to preserve it
    DateTime createdAt = now;
    if (state.loadedRequestUid != null) {
      final existing = _findRequest(collection, state.loadedRequestUid!);
      if (existing != null) createdAt = existing.createdAt;
    }

    final request = HttpRequest(
      uid: requestUid,
      name: state.name,
      method: state.method,
      url: state.url,
      params: state.params,
      headers: state.headers,
      body: state.body,
      auth: state.auth,
      collectionUid: collectionUid,
      folderUid: folderUid,
      createdAt: createdAt,
      updatedAt: now,
    );

    late Collection updated;

    if (folderUid != null) {
      // Save into folder
      final folders = collection.folders.map((f) {
        if (f.uid != folderUid) return f;
        final idx = f.requests.indexWhere((r) => r.uid == requestUid);
        final reqs = [...f.requests];
        if (idx >= 0) {
          reqs[idx] = request;
        } else {
          reqs.add(request);
        }
        return f.copyWith(requests: reqs);
      }).toList();
      updated = collection.copyWith(folders: folders, updatedAt: now);
    } else {
      // Save to root
      final idx =
          collection.requests.indexWhere((r) => r.uid == requestUid);
      final reqs = [...collection.requests];
      if (idx >= 0) {
        reqs[idx] = request;
      } else {
        reqs.add(request);
      }
      updated = collection.copyWith(requests: reqs, updatedAt: now);
    }

    await repo.save(updated);
    ref.invalidate(collectionsProvider);
    state = state.copyWith(
      loadedRequestUid: requestUid,
      collectionUid: collectionUid,
      isDirty: false,
    );
  }

  HttpRequest? _findRequest(Collection collection, String uid) {
    for (final r in collection.requests) {
      if (r.uid == uid) return r;
    }
    for (final f in collection.folders) {
      for (final r in f.requests) {
        if (r.uid == uid) return r;
      }
    }
    return null;
  }
}
