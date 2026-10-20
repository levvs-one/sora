// This is a generated file - do not edit.
//
// Generated from sora/core/v1/core_control.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'core_control.pb.dart' as $0;

export 'core_control.pb.dart';

/// CoreControl is the local control-plane API for the Sora core service.
@$pb.GrpcServiceName('sora.core.v1.CoreControl')
class CoreControlClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  CoreControlClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.ConnectResponse> connect(
    $0.ConnectRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$connect, request, options: options);
  }

  $grpc.ResponseFuture<$0.DisconnectResponse> disconnect(
    $0.DisconnectRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$disconnect, request, options: options);
  }

  $grpc.ResponseFuture<$0.GetStatusResponse> getStatus(
    $0.GetStatusRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getStatus, request, options: options);
  }

  $grpc.ResponseStream<$0.CoreEvent> watchEvents(
    $0.WatchEventsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$watchEvents, $async.Stream.fromIterable([request]),
        options: options);
  }

  $grpc.ResponseFuture<$0.ParseImportResponse> parseImport(
    $0.ParseImportRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$parseImport, request, options: options);
  }

  $grpc.ResponseFuture<$0.FetchSubscriptionResponse> fetchSubscription(
    $0.FetchSubscriptionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$fetchSubscription, request, options: options);
  }

  $grpc.ResponseStream<$0.ProbeResult> probeServers(
    $0.ProbeServersRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$probeServers, $async.Stream.fromIterable([request]),
        options: options);
  }

  $grpc.ResponseFuture<$0.GetStatsResponse> getStats(
    $0.GetStatsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getStats, request, options: options);
  }

  $grpc.ResponseFuture<$0.RunDiagnosticsResponse> runDiagnostics(
    $0.RunDiagnosticsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$runDiagnostics, request, options: options);
  }

  $grpc.ResponseFuture<$0.ExportDiagnosticsResponse> exportDiagnostics(
    $0.ExportDiagnosticsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$exportDiagnostics, request, options: options);
  }

  $grpc.ResponseFuture<$0.SetKillSwitchResponse> setKillSwitch(
    $0.SetKillSwitchRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setKillSwitch, request, options: options);
  }

  $grpc.ResponseFuture<$0.HandshakeResponse> handshake(
    $0.HandshakeRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$handshake, request, options: options);
  }

  /// Since 1.3. What the "About" screen shows about the core. Nothing in it is
  /// personal, so it needs no authenticator.
  $grpc.ResponseFuture<$0.GetAboutResponse> getAbout(
    $0.GetAboutRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getAbout, request, options: options);
  }

  /// Since 1.3. The routing presets and what each of them sends direct.
  $grpc.ResponseFuture<$0.GetRoutingPresetsResponse> getRoutingPresets(
    $0.GetRoutingPresetsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getRoutingPresets, request, options: options);
  }

  /// Since 1.3. The log center: one bounded in-memory record of the core and
  /// every engine. Every call needs the control authenticator, because the
  /// record and the connection list describe where a person goes.
  $grpc.ResponseFuture<$0.QueryLogsResponse> queryLogs(
    $0.QueryLogsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$queryLogs, request, options: options);
  }

  $grpc.ResponseStream<$0.LogEntry> watchLogs(
    $0.WatchLogsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$watchLogs, $async.Stream.fromIterable([request]),
        options: options);
  }

  $grpc.ResponseFuture<$0.ExportLogsResponse> exportLogs(
    $0.ExportLogsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$exportLogs, request, options: options);
  }

  $grpc.ResponseFuture<$0.ClearLogsResponse> clearLogs(
    $0.ClearLogsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$clearLogs, request, options: options);
  }

  $grpc.ResponseFuture<$0.GetLogSettingsResponse> getLogSettings(
    $0.GetLogSettingsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getLogSettings, request, options: options);
  }

  $grpc.ResponseFuture<$0.SetLogSettingsResponse> setLogSettings(
    $0.SetLogSettingsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setLogSettings, request, options: options);
  }

  /// Since 1.3. The connection center: live connections of the session.
  $grpc.ResponseFuture<$0.ListConnectionsResponse> listConnections(
    $0.ListConnectionsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listConnections, request, options: options);
  }

  $grpc.ResponseFuture<$0.CloseConnectionResponse> closeConnection(
    $0.CloseConnectionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$closeConnection, request, options: options);
  }

  /// Since 1.3. Subscriptions the core keeps and updates by itself, so they stay
  /// current while the interface is closed. The link of a subscription is its
  /// credential: the core stores it encrypted and omits it from states.
  $grpc.ResponseFuture<$0.SaveSubscriptionResponse> saveSubscription(
    $0.SaveSubscriptionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$saveSubscription, request, options: options);
  }

  $grpc.ResponseFuture<$0.ListSubscriptionsResponse> listSubscriptions(
    $0.ListSubscriptionsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listSubscriptions, request, options: options);
  }

  $grpc.ResponseFuture<$0.DeleteSubscriptionResponse> deleteSubscription(
    $0.DeleteSubscriptionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteSubscription, request, options: options);
  }

  $grpc.ResponseFuture<$0.RefreshSubscriptionResponse> refreshSubscription(
    $0.RefreshSubscriptionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$refreshSubscription, request, options: options);
  }

  $grpc.ResponseStream<$0.SubscriptionState> watchSubscriptions(
    $0.WatchSubscriptionsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$watchSubscriptions, $async.Stream.fromIterable([request]),
        options: options);
  }

  /// Since 1.6. Returns the stored subscription link only on an authenticated
  /// explicit request to open its page. Clients must not cache or log it.
  $grpc.ResponseFuture<$0.GetSubscriptionLinkResponse> getSubscriptionLink(
    $0.GetSubscriptionLinkRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getSubscriptionLink, request, options: options);
  }

  /// PutSecret and DeleteSecret manage the credential material the core keeps.
  /// They exist because the rest of the contract carries only references: a plan
  /// names a secret, and these two calls are the only way a secret ever reaches
  /// the core. Keeping them separate means no other method can be turned into a
  /// way to read a stored credential.
  $grpc.ResponseFuture<$0.PutSecretResponse> putSecret(
    $0.PutSecretRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$putSecret, request, options: options);
  }

  $grpc.ResponseFuture<$0.DeleteSecretResponse> deleteSecret(
    $0.DeleteSecretRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteSecret, request, options: options);
  }

  /// Since 1.8. DNS leak diagnostics: which resolvers the session uses versus
  /// what the OS would use, and whether the kill switch covers DNS. Requires
  /// the control authenticator: the answers describe the machine's network.
  $grpc.ResponseFuture<$0.CheckDnsLeaksResponse> checkDnsLeaks(
    $0.CheckDnsLeaksRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$checkDnsLeaks, request, options: options);
  }

  /// Since 1.9. Throughput benchmark: measures real download goodput through
  /// each server by spinning up a temporary engine session. Streams progress
  /// samples; each server reports done=true once. Requires the control
  /// authenticator: benchmarks burn traffic and spawn engine processes.
  $grpc.ResponseStream<$0.BandwidthSample> benchmarkServers(
    $0.BenchmarkServersRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$benchmarkServers, $async.Stream.fromIterable([request]),
        options: options);
  }

  /// Since 1.9. RETIRED (2026-10-20, PASS1 M3): no client ever called
  /// this RPC - the app keeps its benchmark history locally - so the
  /// core no longer implements it (callers get Unimplemented) and the
  /// stored history behind it was removed. The messages stay for wire
  /// compatibility; do not build on this method.
  $grpc.ResponseFuture<$0.GetBenchmarksResponse> getBenchmarks(
    $0.GetBenchmarksRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getBenchmarks, request, options: options);
  }

  /// Since 1.9. User overrides on top of a subscription: renames, hidden
  /// servers, extra rules and pinned order survive subscription refreshes.
  $grpc.ResponseFuture<$0.SaveSubscriptionOverrideResponse>
      saveSubscriptionOverride(
    $0.SaveSubscriptionOverrideRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$saveSubscriptionOverride, request,
        options: options);
  }

  $grpc.ResponseFuture<$0.GetSubscriptionOverrideResponse>
      getSubscriptionOverride(
    $0.GetSubscriptionOverrideRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getSubscriptionOverride, request,
        options: options);
  }

  /// Since 1.10. Network profiles with automatic matching: the core watches
  /// the network fingerprint and reports ProfileMatched events when a saved
  /// profile matches the current network. Requires the control authenticator:
  /// profiles describe the machine's networks.
  $grpc.ResponseFuture<$0.ListProfilesResponse> listProfiles(
    $0.ListProfilesRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listProfiles, request, options: options);
  }

  $grpc.ResponseFuture<$0.SaveProfileResponse> saveProfile(
    $0.SaveProfileRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$saveProfile, request, options: options);
  }

  $grpc.ResponseFuture<$0.DeleteProfileResponse> deleteProfile(
    $0.DeleteProfileRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteProfile, request, options: options);
  }

  $grpc.ResponseFuture<$0.GetNetworkFingerprintResponse> getNetworkFingerprint(
    $0.GetNetworkFingerprintRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getNetworkFingerprint, request, options: options);
  }

  /// Since 1.10. Probes a proxy chain of 2-3 servers: per-hop reachability,
  /// the summed latency estimate, and which installed engines can carry it.
  /// Requires the control authenticator: probes burn traffic.
  $grpc.ResponseFuture<$0.ProbeChainResponse> probeChain(
    $0.ProbeChainRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$probeChain, request, options: options);
  }

  // method descriptors

  static final _$connect =
      $grpc.ClientMethod<$0.ConnectRequest, $0.ConnectResponse>(
          '/sora.core.v1.CoreControl/Connect',
          ($0.ConnectRequest value) => value.writeToBuffer(),
          $0.ConnectResponse.fromBuffer);
  static final _$disconnect =
      $grpc.ClientMethod<$0.DisconnectRequest, $0.DisconnectResponse>(
          '/sora.core.v1.CoreControl/Disconnect',
          ($0.DisconnectRequest value) => value.writeToBuffer(),
          $0.DisconnectResponse.fromBuffer);
  static final _$getStatus =
      $grpc.ClientMethod<$0.GetStatusRequest, $0.GetStatusResponse>(
          '/sora.core.v1.CoreControl/GetStatus',
          ($0.GetStatusRequest value) => value.writeToBuffer(),
          $0.GetStatusResponse.fromBuffer);
  static final _$watchEvents =
      $grpc.ClientMethod<$0.WatchEventsRequest, $0.CoreEvent>(
          '/sora.core.v1.CoreControl/WatchEvents',
          ($0.WatchEventsRequest value) => value.writeToBuffer(),
          $0.CoreEvent.fromBuffer);
  static final _$parseImport =
      $grpc.ClientMethod<$0.ParseImportRequest, $0.ParseImportResponse>(
          '/sora.core.v1.CoreControl/ParseImport',
          ($0.ParseImportRequest value) => value.writeToBuffer(),
          $0.ParseImportResponse.fromBuffer);
  static final _$fetchSubscription = $grpc.ClientMethod<
          $0.FetchSubscriptionRequest, $0.FetchSubscriptionResponse>(
      '/sora.core.v1.CoreControl/FetchSubscription',
      ($0.FetchSubscriptionRequest value) => value.writeToBuffer(),
      $0.FetchSubscriptionResponse.fromBuffer);
  static final _$probeServers =
      $grpc.ClientMethod<$0.ProbeServersRequest, $0.ProbeResult>(
          '/sora.core.v1.CoreControl/ProbeServers',
          ($0.ProbeServersRequest value) => value.writeToBuffer(),
          $0.ProbeResult.fromBuffer);
  static final _$getStats =
      $grpc.ClientMethod<$0.GetStatsRequest, $0.GetStatsResponse>(
          '/sora.core.v1.CoreControl/GetStats',
          ($0.GetStatsRequest value) => value.writeToBuffer(),
          $0.GetStatsResponse.fromBuffer);
  static final _$runDiagnostics =
      $grpc.ClientMethod<$0.RunDiagnosticsRequest, $0.RunDiagnosticsResponse>(
          '/sora.core.v1.CoreControl/RunDiagnostics',
          ($0.RunDiagnosticsRequest value) => value.writeToBuffer(),
          $0.RunDiagnosticsResponse.fromBuffer);
  static final _$exportDiagnostics = $grpc.ClientMethod<
          $0.ExportDiagnosticsRequest, $0.ExportDiagnosticsResponse>(
      '/sora.core.v1.CoreControl/ExportDiagnostics',
      ($0.ExportDiagnosticsRequest value) => value.writeToBuffer(),
      $0.ExportDiagnosticsResponse.fromBuffer);
  static final _$setKillSwitch =
      $grpc.ClientMethod<$0.SetKillSwitchRequest, $0.SetKillSwitchResponse>(
          '/sora.core.v1.CoreControl/SetKillSwitch',
          ($0.SetKillSwitchRequest value) => value.writeToBuffer(),
          $0.SetKillSwitchResponse.fromBuffer);
  static final _$handshake =
      $grpc.ClientMethod<$0.HandshakeRequest, $0.HandshakeResponse>(
          '/sora.core.v1.CoreControl/Handshake',
          ($0.HandshakeRequest value) => value.writeToBuffer(),
          $0.HandshakeResponse.fromBuffer);
  static final _$getAbout =
      $grpc.ClientMethod<$0.GetAboutRequest, $0.GetAboutResponse>(
          '/sora.core.v1.CoreControl/GetAbout',
          ($0.GetAboutRequest value) => value.writeToBuffer(),
          $0.GetAboutResponse.fromBuffer);
  static final _$getRoutingPresets = $grpc.ClientMethod<
          $0.GetRoutingPresetsRequest, $0.GetRoutingPresetsResponse>(
      '/sora.core.v1.CoreControl/GetRoutingPresets',
      ($0.GetRoutingPresetsRequest value) => value.writeToBuffer(),
      $0.GetRoutingPresetsResponse.fromBuffer);
  static final _$queryLogs =
      $grpc.ClientMethod<$0.QueryLogsRequest, $0.QueryLogsResponse>(
          '/sora.core.v1.CoreControl/QueryLogs',
          ($0.QueryLogsRequest value) => value.writeToBuffer(),
          $0.QueryLogsResponse.fromBuffer);
  static final _$watchLogs =
      $grpc.ClientMethod<$0.WatchLogsRequest, $0.LogEntry>(
          '/sora.core.v1.CoreControl/WatchLogs',
          ($0.WatchLogsRequest value) => value.writeToBuffer(),
          $0.LogEntry.fromBuffer);
  static final _$exportLogs =
      $grpc.ClientMethod<$0.ExportLogsRequest, $0.ExportLogsResponse>(
          '/sora.core.v1.CoreControl/ExportLogs',
          ($0.ExportLogsRequest value) => value.writeToBuffer(),
          $0.ExportLogsResponse.fromBuffer);
  static final _$clearLogs =
      $grpc.ClientMethod<$0.ClearLogsRequest, $0.ClearLogsResponse>(
          '/sora.core.v1.CoreControl/ClearLogs',
          ($0.ClearLogsRequest value) => value.writeToBuffer(),
          $0.ClearLogsResponse.fromBuffer);
  static final _$getLogSettings =
      $grpc.ClientMethod<$0.GetLogSettingsRequest, $0.GetLogSettingsResponse>(
          '/sora.core.v1.CoreControl/GetLogSettings',
          ($0.GetLogSettingsRequest value) => value.writeToBuffer(),
          $0.GetLogSettingsResponse.fromBuffer);
  static final _$setLogSettings =
      $grpc.ClientMethod<$0.SetLogSettingsRequest, $0.SetLogSettingsResponse>(
          '/sora.core.v1.CoreControl/SetLogSettings',
          ($0.SetLogSettingsRequest value) => value.writeToBuffer(),
          $0.SetLogSettingsResponse.fromBuffer);
  static final _$listConnections =
      $grpc.ClientMethod<$0.ListConnectionsRequest, $0.ListConnectionsResponse>(
          '/sora.core.v1.CoreControl/ListConnections',
          ($0.ListConnectionsRequest value) => value.writeToBuffer(),
          $0.ListConnectionsResponse.fromBuffer);
  static final _$closeConnection =
      $grpc.ClientMethod<$0.CloseConnectionRequest, $0.CloseConnectionResponse>(
          '/sora.core.v1.CoreControl/CloseConnection',
          ($0.CloseConnectionRequest value) => value.writeToBuffer(),
          $0.CloseConnectionResponse.fromBuffer);
  static final _$saveSubscription = $grpc.ClientMethod<
          $0.SaveSubscriptionRequest, $0.SaveSubscriptionResponse>(
      '/sora.core.v1.CoreControl/SaveSubscription',
      ($0.SaveSubscriptionRequest value) => value.writeToBuffer(),
      $0.SaveSubscriptionResponse.fromBuffer);
  static final _$listSubscriptions = $grpc.ClientMethod<
          $0.ListSubscriptionsRequest, $0.ListSubscriptionsResponse>(
      '/sora.core.v1.CoreControl/ListSubscriptions',
      ($0.ListSubscriptionsRequest value) => value.writeToBuffer(),
      $0.ListSubscriptionsResponse.fromBuffer);
  static final _$deleteSubscription = $grpc.ClientMethod<
          $0.DeleteSubscriptionRequest, $0.DeleteSubscriptionResponse>(
      '/sora.core.v1.CoreControl/DeleteSubscription',
      ($0.DeleteSubscriptionRequest value) => value.writeToBuffer(),
      $0.DeleteSubscriptionResponse.fromBuffer);
  static final _$refreshSubscription = $grpc.ClientMethod<
          $0.RefreshSubscriptionRequest, $0.RefreshSubscriptionResponse>(
      '/sora.core.v1.CoreControl/RefreshSubscription',
      ($0.RefreshSubscriptionRequest value) => value.writeToBuffer(),
      $0.RefreshSubscriptionResponse.fromBuffer);
  static final _$watchSubscriptions =
      $grpc.ClientMethod<$0.WatchSubscriptionsRequest, $0.SubscriptionState>(
          '/sora.core.v1.CoreControl/WatchSubscriptions',
          ($0.WatchSubscriptionsRequest value) => value.writeToBuffer(),
          $0.SubscriptionState.fromBuffer);
  static final _$getSubscriptionLink = $grpc.ClientMethod<
          $0.GetSubscriptionLinkRequest, $0.GetSubscriptionLinkResponse>(
      '/sora.core.v1.CoreControl/GetSubscriptionLink',
      ($0.GetSubscriptionLinkRequest value) => value.writeToBuffer(),
      $0.GetSubscriptionLinkResponse.fromBuffer);
  static final _$putSecret =
      $grpc.ClientMethod<$0.PutSecretRequest, $0.PutSecretResponse>(
          '/sora.core.v1.CoreControl/PutSecret',
          ($0.PutSecretRequest value) => value.writeToBuffer(),
          $0.PutSecretResponse.fromBuffer);
  static final _$deleteSecret =
      $grpc.ClientMethod<$0.DeleteSecretRequest, $0.DeleteSecretResponse>(
          '/sora.core.v1.CoreControl/DeleteSecret',
          ($0.DeleteSecretRequest value) => value.writeToBuffer(),
          $0.DeleteSecretResponse.fromBuffer);
  static final _$checkDnsLeaks =
      $grpc.ClientMethod<$0.CheckDnsLeaksRequest, $0.CheckDnsLeaksResponse>(
          '/sora.core.v1.CoreControl/CheckDnsLeaks',
          ($0.CheckDnsLeaksRequest value) => value.writeToBuffer(),
          $0.CheckDnsLeaksResponse.fromBuffer);
  static final _$benchmarkServers =
      $grpc.ClientMethod<$0.BenchmarkServersRequest, $0.BandwidthSample>(
          '/sora.core.v1.CoreControl/BenchmarkServers',
          ($0.BenchmarkServersRequest value) => value.writeToBuffer(),
          $0.BandwidthSample.fromBuffer);
  static final _$getBenchmarks =
      $grpc.ClientMethod<$0.GetBenchmarksRequest, $0.GetBenchmarksResponse>(
          '/sora.core.v1.CoreControl/GetBenchmarks',
          ($0.GetBenchmarksRequest value) => value.writeToBuffer(),
          $0.GetBenchmarksResponse.fromBuffer);
  static final _$saveSubscriptionOverride = $grpc.ClientMethod<
          $0.SaveSubscriptionOverrideRequest,
          $0.SaveSubscriptionOverrideResponse>(
      '/sora.core.v1.CoreControl/SaveSubscriptionOverride',
      ($0.SaveSubscriptionOverrideRequest value) => value.writeToBuffer(),
      $0.SaveSubscriptionOverrideResponse.fromBuffer);
  static final _$getSubscriptionOverride = $grpc.ClientMethod<
          $0.GetSubscriptionOverrideRequest,
          $0.GetSubscriptionOverrideResponse>(
      '/sora.core.v1.CoreControl/GetSubscriptionOverride',
      ($0.GetSubscriptionOverrideRequest value) => value.writeToBuffer(),
      $0.GetSubscriptionOverrideResponse.fromBuffer);
  static final _$listProfiles =
      $grpc.ClientMethod<$0.ListProfilesRequest, $0.ListProfilesResponse>(
          '/sora.core.v1.CoreControl/ListProfiles',
          ($0.ListProfilesRequest value) => value.writeToBuffer(),
          $0.ListProfilesResponse.fromBuffer);
  static final _$saveProfile =
      $grpc.ClientMethod<$0.SaveProfileRequest, $0.SaveProfileResponse>(
          '/sora.core.v1.CoreControl/SaveProfile',
          ($0.SaveProfileRequest value) => value.writeToBuffer(),
          $0.SaveProfileResponse.fromBuffer);
  static final _$deleteProfile =
      $grpc.ClientMethod<$0.DeleteProfileRequest, $0.DeleteProfileResponse>(
          '/sora.core.v1.CoreControl/DeleteProfile',
          ($0.DeleteProfileRequest value) => value.writeToBuffer(),
          $0.DeleteProfileResponse.fromBuffer);
  static final _$getNetworkFingerprint = $grpc.ClientMethod<
          $0.GetNetworkFingerprintRequest, $0.GetNetworkFingerprintResponse>(
      '/sora.core.v1.CoreControl/GetNetworkFingerprint',
      ($0.GetNetworkFingerprintRequest value) => value.writeToBuffer(),
      $0.GetNetworkFingerprintResponse.fromBuffer);
  static final _$probeChain =
      $grpc.ClientMethod<$0.ProbeChainRequest, $0.ProbeChainResponse>(
          '/sora.core.v1.CoreControl/ProbeChain',
          ($0.ProbeChainRequest value) => value.writeToBuffer(),
          $0.ProbeChainResponse.fromBuffer);
}

@$pb.GrpcServiceName('sora.core.v1.CoreControl')
abstract class CoreControlServiceBase extends $grpc.Service {
  $core.String get $name => 'sora.core.v1.CoreControl';

  CoreControlServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.ConnectRequest, $0.ConnectResponse>(
        'Connect',
        connect_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ConnectRequest.fromBuffer(value),
        ($0.ConnectResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DisconnectRequest, $0.DisconnectResponse>(
        'Disconnect',
        disconnect_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.DisconnectRequest.fromBuffer(value),
        ($0.DisconnectResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetStatusRequest, $0.GetStatusResponse>(
        'GetStatus',
        getStatus_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetStatusRequest.fromBuffer(value),
        ($0.GetStatusResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.WatchEventsRequest, $0.CoreEvent>(
        'WatchEvents',
        watchEvents_Pre,
        false,
        true,
        ($core.List<$core.int> value) =>
            $0.WatchEventsRequest.fromBuffer(value),
        ($0.CoreEvent value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ParseImportRequest, $0.ParseImportResponse>(
            'ParseImport',
            parseImport_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ParseImportRequest.fromBuffer(value),
            ($0.ParseImportResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.FetchSubscriptionRequest,
            $0.FetchSubscriptionResponse>(
        'FetchSubscription',
        fetchSubscription_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.FetchSubscriptionRequest.fromBuffer(value),
        ($0.FetchSubscriptionResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ProbeServersRequest, $0.ProbeResult>(
        'ProbeServers',
        probeServers_Pre,
        false,
        true,
        ($core.List<$core.int> value) =>
            $0.ProbeServersRequest.fromBuffer(value),
        ($0.ProbeResult value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetStatsRequest, $0.GetStatsResponse>(
        'GetStats',
        getStats_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetStatsRequest.fromBuffer(value),
        ($0.GetStatsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.RunDiagnosticsRequest,
            $0.RunDiagnosticsResponse>(
        'RunDiagnostics',
        runDiagnostics_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.RunDiagnosticsRequest.fromBuffer(value),
        ($0.RunDiagnosticsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ExportDiagnosticsRequest,
            $0.ExportDiagnosticsResponse>(
        'ExportDiagnostics',
        exportDiagnostics_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ExportDiagnosticsRequest.fromBuffer(value),
        ($0.ExportDiagnosticsResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.SetKillSwitchRequest, $0.SetKillSwitchResponse>(
            'SetKillSwitch',
            setKillSwitch_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.SetKillSwitchRequest.fromBuffer(value),
            ($0.SetKillSwitchResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.HandshakeRequest, $0.HandshakeResponse>(
        'Handshake',
        handshake_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.HandshakeRequest.fromBuffer(value),
        ($0.HandshakeResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetAboutRequest, $0.GetAboutResponse>(
        'GetAbout',
        getAbout_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetAboutRequest.fromBuffer(value),
        ($0.GetAboutResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetRoutingPresetsRequest,
            $0.GetRoutingPresetsResponse>(
        'GetRoutingPresets',
        getRoutingPresets_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GetRoutingPresetsRequest.fromBuffer(value),
        ($0.GetRoutingPresetsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.QueryLogsRequest, $0.QueryLogsResponse>(
        'QueryLogs',
        queryLogs_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.QueryLogsRequest.fromBuffer(value),
        ($0.QueryLogsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.WatchLogsRequest, $0.LogEntry>(
        'WatchLogs',
        watchLogs_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.WatchLogsRequest.fromBuffer(value),
        ($0.LogEntry value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ExportLogsRequest, $0.ExportLogsResponse>(
        'ExportLogs',
        exportLogs_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ExportLogsRequest.fromBuffer(value),
        ($0.ExportLogsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ClearLogsRequest, $0.ClearLogsResponse>(
        'ClearLogs',
        clearLogs_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ClearLogsRequest.fromBuffer(value),
        ($0.ClearLogsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetLogSettingsRequest,
            $0.GetLogSettingsResponse>(
        'GetLogSettings',
        getLogSettings_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GetLogSettingsRequest.fromBuffer(value),
        ($0.GetLogSettingsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SetLogSettingsRequest,
            $0.SetLogSettingsResponse>(
        'SetLogSettings',
        setLogSettings_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.SetLogSettingsRequest.fromBuffer(value),
        ($0.SetLogSettingsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ListConnectionsRequest,
            $0.ListConnectionsResponse>(
        'ListConnections',
        listConnections_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ListConnectionsRequest.fromBuffer(value),
        ($0.ListConnectionsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.CloseConnectionRequest,
            $0.CloseConnectionResponse>(
        'CloseConnection',
        closeConnection_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.CloseConnectionRequest.fromBuffer(value),
        ($0.CloseConnectionResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SaveSubscriptionRequest,
            $0.SaveSubscriptionResponse>(
        'SaveSubscription',
        saveSubscription_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.SaveSubscriptionRequest.fromBuffer(value),
        ($0.SaveSubscriptionResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ListSubscriptionsRequest,
            $0.ListSubscriptionsResponse>(
        'ListSubscriptions',
        listSubscriptions_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ListSubscriptionsRequest.fromBuffer(value),
        ($0.ListSubscriptionsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DeleteSubscriptionRequest,
            $0.DeleteSubscriptionResponse>(
        'DeleteSubscription',
        deleteSubscription_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.DeleteSubscriptionRequest.fromBuffer(value),
        ($0.DeleteSubscriptionResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.RefreshSubscriptionRequest,
            $0.RefreshSubscriptionResponse>(
        'RefreshSubscription',
        refreshSubscription_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.RefreshSubscriptionRequest.fromBuffer(value),
        ($0.RefreshSubscriptionResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.WatchSubscriptionsRequest, $0.SubscriptionState>(
            'WatchSubscriptions',
            watchSubscriptions_Pre,
            false,
            true,
            ($core.List<$core.int> value) =>
                $0.WatchSubscriptionsRequest.fromBuffer(value),
            ($0.SubscriptionState value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetSubscriptionLinkRequest,
            $0.GetSubscriptionLinkResponse>(
        'GetSubscriptionLink',
        getSubscriptionLink_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GetSubscriptionLinkRequest.fromBuffer(value),
        ($0.GetSubscriptionLinkResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.PutSecretRequest, $0.PutSecretResponse>(
        'PutSecret',
        putSecret_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.PutSecretRequest.fromBuffer(value),
        ($0.PutSecretResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.DeleteSecretRequest, $0.DeleteSecretResponse>(
            'DeleteSecret',
            deleteSecret_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.DeleteSecretRequest.fromBuffer(value),
            ($0.DeleteSecretResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.CheckDnsLeaksRequest, $0.CheckDnsLeaksResponse>(
            'CheckDnsLeaks',
            checkDnsLeaks_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.CheckDnsLeaksRequest.fromBuffer(value),
            ($0.CheckDnsLeaksResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.BenchmarkServersRequest, $0.BandwidthSample>(
            'BenchmarkServers',
            benchmarkServers_Pre,
            false,
            true,
            ($core.List<$core.int> value) =>
                $0.BenchmarkServersRequest.fromBuffer(value),
            ($0.BandwidthSample value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.GetBenchmarksRequest, $0.GetBenchmarksResponse>(
            'GetBenchmarks',
            getBenchmarks_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.GetBenchmarksRequest.fromBuffer(value),
            ($0.GetBenchmarksResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SaveSubscriptionOverrideRequest,
            $0.SaveSubscriptionOverrideResponse>(
        'SaveSubscriptionOverride',
        saveSubscriptionOverride_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.SaveSubscriptionOverrideRequest.fromBuffer(value),
        ($0.SaveSubscriptionOverrideResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetSubscriptionOverrideRequest,
            $0.GetSubscriptionOverrideResponse>(
        'GetSubscriptionOverride',
        getSubscriptionOverride_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GetSubscriptionOverrideRequest.fromBuffer(value),
        ($0.GetSubscriptionOverrideResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ListProfilesRequest, $0.ListProfilesResponse>(
            'ListProfiles',
            listProfiles_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ListProfilesRequest.fromBuffer(value),
            ($0.ListProfilesResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.SaveProfileRequest, $0.SaveProfileResponse>(
            'SaveProfile',
            saveProfile_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.SaveProfileRequest.fromBuffer(value),
            ($0.SaveProfileResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.DeleteProfileRequest, $0.DeleteProfileResponse>(
            'DeleteProfile',
            deleteProfile_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.DeleteProfileRequest.fromBuffer(value),
            ($0.DeleteProfileResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetNetworkFingerprintRequest,
            $0.GetNetworkFingerprintResponse>(
        'GetNetworkFingerprint',
        getNetworkFingerprint_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GetNetworkFingerprintRequest.fromBuffer(value),
        ($0.GetNetworkFingerprintResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ProbeChainRequest, $0.ProbeChainResponse>(
        'ProbeChain',
        probeChain_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ProbeChainRequest.fromBuffer(value),
        ($0.ProbeChainResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.ConnectResponse> connect_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ConnectRequest> $request) async {
    return connect($call, await $request);
  }

  $async.Future<$0.ConnectResponse> connect(
      $grpc.ServiceCall call, $0.ConnectRequest request);

  $async.Future<$0.DisconnectResponse> disconnect_Pre($grpc.ServiceCall $call,
      $async.Future<$0.DisconnectRequest> $request) async {
    return disconnect($call, await $request);
  }

  $async.Future<$0.DisconnectResponse> disconnect(
      $grpc.ServiceCall call, $0.DisconnectRequest request);

  $async.Future<$0.GetStatusResponse> getStatus_Pre($grpc.ServiceCall $call,
      $async.Future<$0.GetStatusRequest> $request) async {
    return getStatus($call, await $request);
  }

  $async.Future<$0.GetStatusResponse> getStatus(
      $grpc.ServiceCall call, $0.GetStatusRequest request);

  $async.Stream<$0.CoreEvent> watchEvents_Pre($grpc.ServiceCall $call,
      $async.Future<$0.WatchEventsRequest> $request) async* {
    yield* watchEvents($call, await $request);
  }

  $async.Stream<$0.CoreEvent> watchEvents(
      $grpc.ServiceCall call, $0.WatchEventsRequest request);

  $async.Future<$0.ParseImportResponse> parseImport_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ParseImportRequest> $request) async {
    return parseImport($call, await $request);
  }

  $async.Future<$0.ParseImportResponse> parseImport(
      $grpc.ServiceCall call, $0.ParseImportRequest request);

  $async.Future<$0.FetchSubscriptionResponse> fetchSubscription_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.FetchSubscriptionRequest> $request) async {
    return fetchSubscription($call, await $request);
  }

  $async.Future<$0.FetchSubscriptionResponse> fetchSubscription(
      $grpc.ServiceCall call, $0.FetchSubscriptionRequest request);

  $async.Stream<$0.ProbeResult> probeServers_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ProbeServersRequest> $request) async* {
    yield* probeServers($call, await $request);
  }

  $async.Stream<$0.ProbeResult> probeServers(
      $grpc.ServiceCall call, $0.ProbeServersRequest request);

  $async.Future<$0.GetStatsResponse> getStats_Pre($grpc.ServiceCall $call,
      $async.Future<$0.GetStatsRequest> $request) async {
    return getStats($call, await $request);
  }

  $async.Future<$0.GetStatsResponse> getStats(
      $grpc.ServiceCall call, $0.GetStatsRequest request);

  $async.Future<$0.RunDiagnosticsResponse> runDiagnostics_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.RunDiagnosticsRequest> $request) async {
    return runDiagnostics($call, await $request);
  }

  $async.Future<$0.RunDiagnosticsResponse> runDiagnostics(
      $grpc.ServiceCall call, $0.RunDiagnosticsRequest request);

  $async.Future<$0.ExportDiagnosticsResponse> exportDiagnostics_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ExportDiagnosticsRequest> $request) async {
    return exportDiagnostics($call, await $request);
  }

  $async.Future<$0.ExportDiagnosticsResponse> exportDiagnostics(
      $grpc.ServiceCall call, $0.ExportDiagnosticsRequest request);

  $async.Future<$0.SetKillSwitchResponse> setKillSwitch_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.SetKillSwitchRequest> $request) async {
    return setKillSwitch($call, await $request);
  }

  $async.Future<$0.SetKillSwitchResponse> setKillSwitch(
      $grpc.ServiceCall call, $0.SetKillSwitchRequest request);

  $async.Future<$0.HandshakeResponse> handshake_Pre($grpc.ServiceCall $call,
      $async.Future<$0.HandshakeRequest> $request) async {
    return handshake($call, await $request);
  }

  $async.Future<$0.HandshakeResponse> handshake(
      $grpc.ServiceCall call, $0.HandshakeRequest request);

  $async.Future<$0.GetAboutResponse> getAbout_Pre($grpc.ServiceCall $call,
      $async.Future<$0.GetAboutRequest> $request) async {
    return getAbout($call, await $request);
  }

  $async.Future<$0.GetAboutResponse> getAbout(
      $grpc.ServiceCall call, $0.GetAboutRequest request);

  $async.Future<$0.GetRoutingPresetsResponse> getRoutingPresets_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetRoutingPresetsRequest> $request) async {
    return getRoutingPresets($call, await $request);
  }

  $async.Future<$0.GetRoutingPresetsResponse> getRoutingPresets(
      $grpc.ServiceCall call, $0.GetRoutingPresetsRequest request);

  $async.Future<$0.QueryLogsResponse> queryLogs_Pre($grpc.ServiceCall $call,
      $async.Future<$0.QueryLogsRequest> $request) async {
    return queryLogs($call, await $request);
  }

  $async.Future<$0.QueryLogsResponse> queryLogs(
      $grpc.ServiceCall call, $0.QueryLogsRequest request);

  $async.Stream<$0.LogEntry> watchLogs_Pre($grpc.ServiceCall $call,
      $async.Future<$0.WatchLogsRequest> $request) async* {
    yield* watchLogs($call, await $request);
  }

  $async.Stream<$0.LogEntry> watchLogs(
      $grpc.ServiceCall call, $0.WatchLogsRequest request);

  $async.Future<$0.ExportLogsResponse> exportLogs_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ExportLogsRequest> $request) async {
    return exportLogs($call, await $request);
  }

  $async.Future<$0.ExportLogsResponse> exportLogs(
      $grpc.ServiceCall call, $0.ExportLogsRequest request);

  $async.Future<$0.ClearLogsResponse> clearLogs_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ClearLogsRequest> $request) async {
    return clearLogs($call, await $request);
  }

  $async.Future<$0.ClearLogsResponse> clearLogs(
      $grpc.ServiceCall call, $0.ClearLogsRequest request);

  $async.Future<$0.GetLogSettingsResponse> getLogSettings_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetLogSettingsRequest> $request) async {
    return getLogSettings($call, await $request);
  }

  $async.Future<$0.GetLogSettingsResponse> getLogSettings(
      $grpc.ServiceCall call, $0.GetLogSettingsRequest request);

  $async.Future<$0.SetLogSettingsResponse> setLogSettings_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.SetLogSettingsRequest> $request) async {
    return setLogSettings($call, await $request);
  }

  $async.Future<$0.SetLogSettingsResponse> setLogSettings(
      $grpc.ServiceCall call, $0.SetLogSettingsRequest request);

  $async.Future<$0.ListConnectionsResponse> listConnections_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ListConnectionsRequest> $request) async {
    return listConnections($call, await $request);
  }

  $async.Future<$0.ListConnectionsResponse> listConnections(
      $grpc.ServiceCall call, $0.ListConnectionsRequest request);

  $async.Future<$0.CloseConnectionResponse> closeConnection_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.CloseConnectionRequest> $request) async {
    return closeConnection($call, await $request);
  }

  $async.Future<$0.CloseConnectionResponse> closeConnection(
      $grpc.ServiceCall call, $0.CloseConnectionRequest request);

  $async.Future<$0.SaveSubscriptionResponse> saveSubscription_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.SaveSubscriptionRequest> $request) async {
    return saveSubscription($call, await $request);
  }

  $async.Future<$0.SaveSubscriptionResponse> saveSubscription(
      $grpc.ServiceCall call, $0.SaveSubscriptionRequest request);

  $async.Future<$0.ListSubscriptionsResponse> listSubscriptions_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ListSubscriptionsRequest> $request) async {
    return listSubscriptions($call, await $request);
  }

  $async.Future<$0.ListSubscriptionsResponse> listSubscriptions(
      $grpc.ServiceCall call, $0.ListSubscriptionsRequest request);

  $async.Future<$0.DeleteSubscriptionResponse> deleteSubscription_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.DeleteSubscriptionRequest> $request) async {
    return deleteSubscription($call, await $request);
  }

  $async.Future<$0.DeleteSubscriptionResponse> deleteSubscription(
      $grpc.ServiceCall call, $0.DeleteSubscriptionRequest request);

  $async.Future<$0.RefreshSubscriptionResponse> refreshSubscription_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.RefreshSubscriptionRequest> $request) async {
    return refreshSubscription($call, await $request);
  }

  $async.Future<$0.RefreshSubscriptionResponse> refreshSubscription(
      $grpc.ServiceCall call, $0.RefreshSubscriptionRequest request);

  $async.Stream<$0.SubscriptionState> watchSubscriptions_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.WatchSubscriptionsRequest> $request) async* {
    yield* watchSubscriptions($call, await $request);
  }

  $async.Stream<$0.SubscriptionState> watchSubscriptions(
      $grpc.ServiceCall call, $0.WatchSubscriptionsRequest request);

  $async.Future<$0.GetSubscriptionLinkResponse> getSubscriptionLink_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetSubscriptionLinkRequest> $request) async {
    return getSubscriptionLink($call, await $request);
  }

  $async.Future<$0.GetSubscriptionLinkResponse> getSubscriptionLink(
      $grpc.ServiceCall call, $0.GetSubscriptionLinkRequest request);

  $async.Future<$0.PutSecretResponse> putSecret_Pre($grpc.ServiceCall $call,
      $async.Future<$0.PutSecretRequest> $request) async {
    return putSecret($call, await $request);
  }

  $async.Future<$0.PutSecretResponse> putSecret(
      $grpc.ServiceCall call, $0.PutSecretRequest request);

  $async.Future<$0.DeleteSecretResponse> deleteSecret_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.DeleteSecretRequest> $request) async {
    return deleteSecret($call, await $request);
  }

  $async.Future<$0.DeleteSecretResponse> deleteSecret(
      $grpc.ServiceCall call, $0.DeleteSecretRequest request);

  $async.Future<$0.CheckDnsLeaksResponse> checkDnsLeaks_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.CheckDnsLeaksRequest> $request) async {
    return checkDnsLeaks($call, await $request);
  }

  $async.Future<$0.CheckDnsLeaksResponse> checkDnsLeaks(
      $grpc.ServiceCall call, $0.CheckDnsLeaksRequest request);

  $async.Stream<$0.BandwidthSample> benchmarkServers_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.BenchmarkServersRequest> $request) async* {
    yield* benchmarkServers($call, await $request);
  }

  $async.Stream<$0.BandwidthSample> benchmarkServers(
      $grpc.ServiceCall call, $0.BenchmarkServersRequest request);

  $async.Future<$0.GetBenchmarksResponse> getBenchmarks_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetBenchmarksRequest> $request) async {
    return getBenchmarks($call, await $request);
  }

  $async.Future<$0.GetBenchmarksResponse> getBenchmarks(
      $grpc.ServiceCall call, $0.GetBenchmarksRequest request);

  $async.Future<$0.SaveSubscriptionOverrideResponse>
      saveSubscriptionOverride_Pre($grpc.ServiceCall $call,
          $async.Future<$0.SaveSubscriptionOverrideRequest> $request) async {
    return saveSubscriptionOverride($call, await $request);
  }

  $async.Future<$0.SaveSubscriptionOverrideResponse> saveSubscriptionOverride(
      $grpc.ServiceCall call, $0.SaveSubscriptionOverrideRequest request);

  $async.Future<$0.GetSubscriptionOverrideResponse> getSubscriptionOverride_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetSubscriptionOverrideRequest> $request) async {
    return getSubscriptionOverride($call, await $request);
  }

  $async.Future<$0.GetSubscriptionOverrideResponse> getSubscriptionOverride(
      $grpc.ServiceCall call, $0.GetSubscriptionOverrideRequest request);

  $async.Future<$0.ListProfilesResponse> listProfiles_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ListProfilesRequest> $request) async {
    return listProfiles($call, await $request);
  }

  $async.Future<$0.ListProfilesResponse> listProfiles(
      $grpc.ServiceCall call, $0.ListProfilesRequest request);

  $async.Future<$0.SaveProfileResponse> saveProfile_Pre($grpc.ServiceCall $call,
      $async.Future<$0.SaveProfileRequest> $request) async {
    return saveProfile($call, await $request);
  }

  $async.Future<$0.SaveProfileResponse> saveProfile(
      $grpc.ServiceCall call, $0.SaveProfileRequest request);

  $async.Future<$0.DeleteProfileResponse> deleteProfile_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.DeleteProfileRequest> $request) async {
    return deleteProfile($call, await $request);
  }

  $async.Future<$0.DeleteProfileResponse> deleteProfile(
      $grpc.ServiceCall call, $0.DeleteProfileRequest request);

  $async.Future<$0.GetNetworkFingerprintResponse> getNetworkFingerprint_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetNetworkFingerprintRequest> $request) async {
    return getNetworkFingerprint($call, await $request);
  }

  $async.Future<$0.GetNetworkFingerprintResponse> getNetworkFingerprint(
      $grpc.ServiceCall call, $0.GetNetworkFingerprintRequest request);

  $async.Future<$0.ProbeChainResponse> probeChain_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ProbeChainRequest> $request) async {
    return probeChain($call, await $request);
  }

  $async.Future<$0.ProbeChainResponse> probeChain(
      $grpc.ServiceCall call, $0.ProbeChainRequest request);
}
