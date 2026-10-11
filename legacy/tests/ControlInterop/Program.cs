using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Pipes;
using System.Linq;
using System.Net.Sockets;
using System.Threading;
using System.Threading.Tasks;
using Google.Protobuf;
using Sora.Core.V1;
using Sora.Legacy.Control;
using StreamJsonRpc;

using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(20));
using Stream stream = await OpenEndpoint(args[0], timeout.Token);
using var connection = await CoreConnection.OpenAsync(stream, timeout.Token);
if (connection.Version.Minor != 7 || connection.Authenticator.Length != 32) throw new Exception("Handshake failed.");

var imported = await connection.CallAsync(new ParseImportRequest
{
    ApiVersion = connection.Version,
    RequestId = "dotnet-import",
    Payload = ByteString.CopyFromUtf8("socks5://user:secret@127.0.0.1:1080#Сервер")
}, ParseImportResponse.Parser, timeout.Token);
if (imported.Error != null || imported.SessionPlan.Outbounds.Count != 1) throw new Exception("Import failed.");

var query = await connection.CallAsync(new QueryLogsRequest
{
    ApiVersion = connection.Version, ControlAuthenticator = connection.Authenticator
}, QueryLogsResponse.Parser, timeout.Token);
if (query.Error != null || query.Entries.Count != 1 || query.Entries[0].Message != "transport integration started")
    throw new Exception("Shared log center failed.");

foreach (LogExportFormat format in Enum.GetValues(typeof(LogExportFormat)))
{
    var export = await connection.CallAsync(new ExportLogsRequest
    {
        ApiVersion = connection.Version, ControlAuthenticator = connection.Authenticator, Format = format, Category = "all"
    }, ExportLogsResponse.Parser, timeout.Token);
    if (export.Error != null || export.Data.Length == 0 || !export.FileName.StartsWith("sora-log_", StringComparison.Ordinal))
        throw new Exception("Export failed: " + format);
}

try
{
    await connection.CallAsync(new QueryLogsRequest
    {
        ApiVersion = connection.Version, ControlAuthenticator = ByteString.CopyFrom(new byte[32])
    }, QueryLogsResponse.Parser, timeout.Token);
    throw new Exception("Invalid authenticator accepted.");
}
catch (RemoteInvocationException)
{
    Console.WriteLine("PASS authenticated protobuf contract and eight export formats");
}

var statusCalls = Enumerable.Range(0, 100).Select(_ => connection.CallAsync(new GetStatusRequest
{
    ApiVersion = connection.Version
}, GetStatusResponse.Parser, timeout.Token));
var statuses = await Task.WhenAll(statusCalls);
if (statuses.Any(status => status.Error != null)) throw new Exception("Concurrent status failed.");

using var cancelWatches = CancellationTokenSource.CreateLinkedTokenSource(timeout.Token);
var starts = new List<Task>();
var watches = new List<Task>();
for (var index = 0; index < 8; index++)
{
    var received = new TaskCompletionSource<bool>(TaskCreationOptions.RunContinuationsAsynchronously);
    starts.Add(received.Task);
    watches.Add(connection.WatchAsync(new WatchLogsRequest
    {
        ApiVersion = connection.Version, ControlAuthenticator = connection.Authenticator
    }, LogEntry.Parser, new Progress<LogEntry>(_ => received.TrySetResult(true)), cancelWatches.Token));
}
await Task.WhenAny(Task.WhenAll(starts), Task.Delay(5000, timeout.Token));
if (starts.Any(task => !task.IsCompleted)) throw new Exception("A watch did not start.");
await connection.CallAsync(new DisconnectRequest
{
    ApiVersion = connection.Version, RequestId = "dotnet-stop", ControlAuthenticator = connection.Authenticator
}, DisconnectResponse.Parser, timeout.Token);
cancelWatches.Cancel();
foreach (var watch in watches)
{
    try { await watch; throw new Exception("A watch ignored cancellation."); }
    catch (OperationCanceledException) { }
}
await connection.CallAsync(new GetStatusRequest { ApiVersion = connection.Version }, GetStatusResponse.Parser, timeout.Token);
Console.WriteLine("PASS 100 concurrent calls, eight live watches, cancellation and disconnect");

var requests = new SessionRequests(connection);
try
{
    await requests.SetAsync(imported.SessionPlan);
    throw new Exception("The transport-only fixture unexpectedly started an engine.");
}
catch (InvalidOperationException error) when (error.Message.StartsWith("core.", StringComparison.Ordinal))
{
    Console.WriteLine("PASS a backend start failure reaches the session caller");
}
var rapid = new List<Task<SessionStatus>>();
for (var index = 0; index < 200; index++)
{
    var plan = imported.SessionPlan.Clone();
    plan.Engines.Clear();
    plan.Engines.Add(new[] { "sing-box", "xray", "mihomo" }[index % 3]);
    plan.TunnelMode = index % 2 == 0 ? TunnelMode.System : TunnelMode.Application;
    rapid.Add(requests.SetAsync(index % 5 == 0 ? null : plan));
}
var final = await requests.SetAsync(null);
if (final.Connection.Value != ConnectionStateValue.Disconnected)
    throw new Exception("The last requested disconnect did not win.");
foreach (var task in rapid)
{
    try { await task; }
    catch (OperationCanceledException) { continue; }
    catch (InvalidOperationException error) when (error.Message.StartsWith("core.", StringComparison.Ordinal)) { continue; }
}
await requests.StopAsync();
await requests.StopAsync();
try { _ = requests.SetAsync(null); throw new Exception("A stopped queue accepted another command."); }
catch (ObjectDisposedException) { Console.WriteLine("PASS bounded session queue: 200 mixed choices, final disconnect, idempotent shutdown"); }

static async Task<Stream> OpenEndpoint(string endpoint, CancellationToken cancellation)
{
    if (endpoint.StartsWith(@"\\.\pipe\", StringComparison.Ordinal))
    {
        var pipe = new NamedPipeClientStream(".", endpoint.Substring(@"\\.\pipe\".Length), PipeDirection.InOut, PipeOptions.Asynchronous);
        try { await pipe.ConnectAsync(5000, cancellation); return pipe; }
        catch { pipe.Dispose(); throw; }
    }
#if NET8_0
    var socket = new Socket(AddressFamily.Unix, SocketType.Stream, ProtocolType.Unspecified);
    try { await socket.ConnectAsync(new UnixDomainSocketEndPoint(endpoint), cancellation); return new NetworkStream(socket, ownsSocket: true); }
    catch { socket.Dispose(); throw; }
#else
    throw new PlatformNotSupportedException("The .NET Framework integration executable requires a Windows named pipe.");
#endif
}
