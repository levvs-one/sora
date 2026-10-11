using System;
using System.IO;
using System.IO.Pipes;
using System.Security.Principal;
using System.Threading;
using Sora.Core.V1;
using Sora.Legacy.Control;

using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(20));
if (args.Length == 1 && args[0] == "--spoof")
{
    using var server = new NamedPipeServerStream("sora-legacy-core-v1", PipeDirection.InOut, 1,
        PipeTransmissionMode.Byte, PipeOptions.Asynchronous);
    var accepting = server.WaitForConnectionAsync(timeout.Token);
    var connection = CoreService.ConnectAsync(timeout.Token);
    await accepting;
    try
    {
        using var unexpected = await connection;
        throw new Exception("An unregistered pipe server was trusted.");
    }
    catch (UnauthorizedAccessException)
    {
        var input = new byte[1];
        if (await server.ReadAsync(input, 0, 1, timeout.Token) != 0)
            throw new Exception("A handshake was sent before verifying the service.");
        Console.WriteLine("PASS a spoofed pipe is rejected before any RPC bytes");
    }
    return;
}

if (new WindowsPrincipal(WindowsIdentity.GetCurrent()).IsInRole(WindowsBuiltInRole.Administrator))
    throw new Exception("The service check must run without administrator rights.");
using var core = await CoreService.ConnectAsync(timeout.Token);
var status = await core.CallAsync(new GetStatusRequest { ApiVersion = core.Version },
    GetStatusResponse.Parser, timeout.Token);
if (status.Error != null || status.Status.Connection.Value != ConnectionStateValue.Disconnected)
    throw new Exception("The freshly installed core is not disconnected.");
var subscriptions = await core.CallAsync(new ListSubscriptionsRequest
{
    ApiVersion = core.Version, ControlAuthenticator = core.Authenticator
}, ListSubscriptionsResponse.Parser, timeout.Token);
if (subscriptions.Error != null || subscriptions.Subscriptions.Count != 0)
    throw new Exception("The isolated service subscription store was not reached.");
foreach (LogExportFormat format in Enum.GetValues(typeof(LogExportFormat)))
{
    var export = await core.CallAsync(new ExportLogsRequest
    {
        ApiVersion = core.Version, ControlAuthenticator = core.Authenticator, Format = format, Category = "all"
    }, ExportLogsResponse.Parser, timeout.Token);
    if (export.Error != null || export.Data.Length == 0)
        throw new Exception("The ordinary user cannot export logs: " + format);
}
Console.WriteLine("PASS ordinary user: SCM pipe identity, handshake, status, subscriptions and eight exports");
