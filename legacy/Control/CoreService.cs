#if NET48
using System;
using System.ComponentModel;
using System.IO;
using System.IO.Pipes;
using System.Runtime.InteropServices;
using System.Security.Principal;
using System.Threading;
using System.Threading.Tasks;
using Windows.Win32;
using Windows.Win32.System.Services;

namespace Sora.Legacy.Control;

public static class CoreService
{
    public static async Task<CoreConnection> ConnectAsync(CancellationToken cancellation)
    {
        // GenericWrite includes creating new pipe instances, which the service
        // deliberately refuses to interactive users.
        const PipeAccessRights rights = PipeAccessRights.ReadData | PipeAccessRights.WriteData |
            PipeAccessRights.ReadAttributes | PipeAccessRights.WriteAttributes |
            PipeAccessRights.ReadPermissions | PipeAccessRights.Synchronize;
        var pipe = new NamedPipeClientStream(".", "sora-legacy-core-v1", rights,
            PipeOptions.Asynchronous, TokenImpersonationLevel.Identification, HandleInheritability.None);
        try
        {
            await pipe.ConnectAsync(5000, cancellation).ConfigureAwait(false);
            VerifyService(pipe);
            return await CoreConnection.OpenAsync(pipe, cancellation).ConfigureAwait(false);
        }
        catch
        {
            pipe.Dispose();
            throw;
        }
    }

    private static void VerifyService(NamedPipeClientStream pipe)
    {
        if (!PInvoke.GetNamedPipeServerProcessId(pipe.SafePipeHandle, out var pid))
            throw new Win32Exception(Marshal.GetLastWin32Error());
        using var manager = PInvoke.OpenSCManager((string?)null, (string?)null, PInvoke.SC_MANAGER_CONNECT);
        if (manager.IsInvalid) throw new Win32Exception(Marshal.GetLastWin32Error());
        using var service = PInvoke.OpenService(manager, "SoraLegacyCore", PInvoke.SERVICE_QUERY_STATUS);
        if (service.IsInvalid) throw new Win32Exception(Marshal.GetLastWin32Error());
        var buffer = new byte[Marshal.SizeOf<SERVICE_STATUS_PROCESS>()];
        if (!PInvoke.QueryServiceStatusEx(service, SC_STATUS_TYPE.SC_STATUS_PROCESS_INFO, buffer, out _))
            throw new Win32Exception(Marshal.GetLastWin32Error());
        var status = MemoryMarshal.Read<SERVICE_STATUS_PROCESS>(buffer);
        // Querying the SCM works without administrator rights. Reading a
        // LocalSystem process token would reject legitimate ordinary users.
        if (pid == 0 || status.dwProcessId != pid ||
            status.dwCurrentState != SERVICE_STATUS_CURRENT_STATE.SERVICE_RUNNING)
            throw new UnauthorizedAccessException("core.error.untrusted_service");
    }
}
#endif
