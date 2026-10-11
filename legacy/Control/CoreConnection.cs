using System;
using System.Collections.Concurrent;
using System.IO;
using System.Threading;
using System.Threading.Tasks;
using Google.Protobuf;
using Sora.Core.V1;
using StreamJsonRpc;

namespace Sora.Legacy.Control;

public sealed class CoreConnection : IDisposable
{
    private readonly Stream stream;
    private readonly JsonRpc rpc;
    private readonly ConcurrentDictionary<string, Action<string>> watches = new();
    private int disposed;

    public ApiVersion Version { get; private set; } = new();
    public ByteString Authenticator { get; private set; } = ByteString.Empty;
    public Task Completion => rpc.Completion;

    private CoreConnection(Stream stream)
    {
        this.stream = stream;
        var handler = new NewLineDelimitedMessageHandler(stream, stream, new JsonMessageFormatter());
        rpc = new JsonRpc(handler);
        rpc.AddLocalRpcMethod("CoreEvent", (Action<string, string>)ReceiveEvent);
        rpc.StartListening();
    }

    // The caller opens and verifies the OS endpoint before handing ownership
    // of its stream to the connection; the handshake never uses a TCP port.
    public static async Task<CoreConnection> OpenAsync(Stream stream, CancellationToken cancellation)
    {
        var connection = new CoreConnection(stream);
        try
        {
            using var timeout = CancellationTokenSource.CreateLinkedTokenSource(cancellation);
            timeout.CancelAfter(TimeSpan.FromSeconds(8));
            var response = await connection.CallAsync(new HandshakeRequest
            {
                ClientVersion = new ApiVersion { Major = 1, Minor = 7, MinSupportedMinor = 7 }
            }, HandshakeResponse.Parser, timeout.Token).ConfigureAwait(false);
            if (response.Error != null || response.ControlAuthenticator.Length != 32)
                throw new InvalidDataException(response.Error?.UserMessageKey ?? "core.error.unauthenticated");
            connection.Version = response.NegotiatedVersion;
            connection.Authenticator = response.ControlAuthenticator;
            return connection;
        }
        catch
        {
            connection.Dispose();
            throw;
        }
    }

    public async Task<T> CallAsync<T>(IMessage request, MessageParser<T> parser, CancellationToken cancellation)
        where T : IMessage<T>
    {
        if (Volatile.Read(ref disposed) != 0) throw new ObjectDisposedException(nameof(CoreConnection));
        var json = await rpc.InvokeWithParameterObjectAsync<string>(Method(request),
            new { payload = Google.Protobuf.JsonFormatter.Default.Format(request) }, cancellation).ConfigureAwait(false);
        return parser.ParseJson(json);
    }

    public async Task WatchAsync<T>(IMessage request, MessageParser<T> parser, IProgress<T> progress,
        CancellationToken cancellation) where T : IMessage<T>
    {
        if (Volatile.Read(ref disposed) != 0) throw new ObjectDisposedException(nameof(CoreConnection));
        var id = Guid.NewGuid().ToString("N");
        watches[id] = payload => progress.Report(parser.ParseJson(payload));
        try
        {
            await rpc.InvokeWithParameterObjectAsync<object>(Method(request),
                new { payload = Google.Protobuf.JsonFormatter.Default.Format(request), streamId = id }, cancellation)
                .ConfigureAwait(false);
            cancellation.ThrowIfCancellationRequested();
        }
        finally
        {
            watches.TryRemove(id, out _);
        }
    }

    private void ReceiveEvent(string streamId, string payload)
    {
        if (Volatile.Read(ref disposed) == 0 && watches.TryGetValue(streamId, out var receive)) receive(payload);
    }

    private static string Method(IMessage request)
    {
        var name = request.Descriptor.Name;
        if (!name.EndsWith("Request", StringComparison.Ordinal)) throw new ArgumentException("A control request is required.", nameof(request));
        return name.Substring(0, name.Length - "Request".Length);
    }

    public void Dispose()
    {
        if (Interlocked.Exchange(ref disposed, 1) != 0) return;
        watches.Clear();
        Authenticator = ByteString.Empty;
        rpc.Dispose();
        stream.Dispose();
    }
}
