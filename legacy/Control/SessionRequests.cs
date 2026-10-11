using System;
using System.IO;
using System.Threading;
using System.Threading.Channels;
using System.Threading.Tasks;
using Sora.Core.V1;

namespace Sora.Legacy.Control;

public sealed class SessionRequests
{
    private readonly CoreConnection core;
    private readonly object gate = new();
    private readonly CancellationTokenSource lifetime = new();
    private readonly Channel<Command> commands;
    private readonly Task processing;
    private CancellationTokenSource? connecting;
    private long version;
    private bool stopped;

    public SessionRequests(CoreConnection core)
    {
        this.core = core;
        commands = Channel.CreateBounded<Command>(new BoundedChannelOptions(1)
        {
            SingleReader = true, SingleWriter = false,
            AllowSynchronousContinuations = false, FullMode = BoundedChannelFullMode.DropOldest
        }, command => command.Completion.TrySetCanceled());
        processing = ProcessAsync();
    }

    public Task<SessionStatus> SetAsync(SessionPlan? plan, bool killSwitch = false)
    {
        lock (gate)
        {
            if (stopped) throw new ObjectDisposedException(nameof(SessionRequests));
            var command = new Command(++version, plan?.Clone(), killSwitch);
            // Wait for the current RPC result before issuing its replacement.
            // Cancelling the client future would hide ongoing core cleanup.
            if (!commands.Writer.TryWrite(command)) command.Completion.TrySetCanceled();
            return command.Completion.Task;
        }
    }

    private async Task ProcessAsync()
    {
        try
        {
            while (await commands.Reader.WaitToReadAsync(lifetime.Token).ConfigureAwait(false))
            {
                if (!commands.Reader.TryRead(out var command)) continue;
                try { command.Completion.TrySetResult(await ApplyAsync(command).ConfigureAwait(false)); }
                catch (OperationCanceledException) { command.Completion.TrySetCanceled(); }
                catch (Exception error) { command.Completion.TrySetException(error); }
            }
        }
        catch (OperationCanceledException) when (lifetime.IsCancellationRequested) { return; }
        finally
        {
            while (commands.Reader.TryRead(out var command)) command.Completion.TrySetCanceled();
        }
    }

    private async Task<SessionStatus> ApplyAsync(Command command)
    {
        using var attempt = CancellationTokenSource.CreateLinkedTokenSource(lifetime.Token);
        attempt.CancelAfter(TimeSpan.FromSeconds(45));
        lock (gate)
        {
            if (stopped || command.Version != version) throw new OperationCanceledException();
            connecting = attempt;
        }
        try
        {
            if (command.Plan == null)
            {
                attempt.CancelAfter(TimeSpan.FromSeconds(25));
                var disconnected = await core.CallAsync(new DisconnectRequest
                {
                    ApiVersion = core.Version, ControlAuthenticator = core.Authenticator,
                    RequestId = Guid.NewGuid().ToString("N")
                }, DisconnectResponse.Parser, attempt.Token).ConfigureAwait(false);
                if (disconnected.Error != null) throw new InvalidOperationException(disconnected.Error.UserMessageKey);
                return disconnected.Status ?? throw new InvalidDataException("Missing session status.");
            }
            // Connect validates the new plan before releasing the old session.
            // An explicit Disconnect here would defeat that protection.
            var connected = await core.CallAsync(new ConnectRequest
            {
                ApiVersion = core.Version, ControlAuthenticator = core.Authenticator,
                RequestId = Guid.NewGuid().ToString("N"), SessionPlan = command.Plan, KillSwitch = command.KillSwitch
            }, ConnectResponse.Parser, attempt.Token).ConfigureAwait(false);
            lock (gate)
            {
                if (stopped || command.Version != version) throw new OperationCanceledException();
                if (connected.Error != null) throw new InvalidOperationException(connected.Error.UserMessageKey);
                return connected.Status ?? throw new InvalidDataException("Missing session status.");
            }
        }
        finally
        {
            lock (gate)
            {
                if (ReferenceEquals(connecting, attempt)) connecting = null;
            }
        }
    }

    public async Task StopAsync()
    {
        lock (gate)
        {
            if (!stopped)
            {
                stopped = true;
                commands.Writer.TryComplete();
                connecting?.Cancel();
                lifetime.Cancel();
            }
        }
        await processing.ConfigureAwait(false);
        lock (gate) lifetime.Dispose();
    }

    private sealed class Command(long version, SessionPlan? plan, bool killSwitch)
    {
        public long Version { get; } = version;
        public SessionPlan? Plan { get; } = plan;
        public bool KillSwitch { get; } = killSwitch;
        public TaskCompletionSource<SessionStatus> Completion { get; } = new(TaskCreationOptions.RunContinuationsAsynchronously);
    }
}
