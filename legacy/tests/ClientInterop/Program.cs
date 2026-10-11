using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Security.Principal;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;
using Newtonsoft.Json.Linq;
using Sora.Core.V1;
using Sora.Legacy.Control;
using FormsControl = System.Windows.Forms.Control;

internal static class Program
{
    [STAThread]
    private static int Main(string[] args)
    {
        try
        {
            if (args.Length != 1) throw new ArgumentException("Expected the screenshot directory.");
            if (new WindowsPrincipal(WindowsIdentity.GetCurrent()).IsInRole(WindowsBuiltInRole.Administrator))
                throw new Exception("The GUI check must run without administrator rights.");
            Directory.CreateDirectory(args[0]);
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.SetUnhandledExceptionMode(UnhandledExceptionMode.ThrowException);
            var assembly = Assembly.Load("Sora.Legacy");
            var formType = assembly.GetType("Sora.Legacy.Client.MainForm", true)!;
            for (var cycle = 0; cycle < 3; cycle++)
            {
                using var form = (Form)Activator.CreateInstance(formType, true)!;
                form.ClientSize = new Size(920, 650);
                var fields = formType.GetFields(BindingFlags.Instance | BindingFlags.NonPublic)
                    .ToDictionary(field => field.Name, field => field.GetValue(form));
                var orb = (AntdUI.Button)fields["orb"]!;
                var error = (Label)fields["error"]!;
                var state = (Label)fields["state"]!;
                Exception? failure = null;
                form.Shown += async (_, _) =>
                {
                    try
                    {
                        using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(15));
                        while (!orb.Enabled) await Task.Delay(50, timeout.Token);
                        if (error.Text.Length != 0) throw new Exception("GUI startup: " + error.Text);
                        var controls = Descendants(form).ToArray();
                        if (controls.Count(control => control.Visible && (string?)control.Tag == "addSubscription") != 1)
                            throw new Exception("An empty subscription list must show exactly one add button.");
                        var language = controls.OfType<AntdUI.Select>().Single();
                        if (language.Items.Count != 31) throw new Exception("Missing language choices.");
                        foreach (var item in language.Items.Cast<AntdUI.SelectItem>())
                        {
                            var code = (string)item.Tag;
                            language.SelectedValue = code;
                            using var stream = assembly.GetManifestResourceStream("Sora.Legacy.Client.Assets.l10n.app_" + code + ".arb")
                                ?? throw new Exception("Missing language resource: " + code);
                            using var reader = new StreamReader(stream);
                            var expected = (string)JObject.Parse(reader.ReadToEnd())["stateOff"]!;
                            if (state.Text != expected) throw new Exception("Language was not applied: " + code);
                            if (cycle == 0 && code is "ru" or "zh_TW")
                            {
                                form.Refresh();
                                using var screenshot = new Bitmap(form.Width, form.Height);
                                form.DrawToBitmap(screenshot, new Rectangle(Point.Empty, form.Size));
                                screenshot.Save(Path.Combine(args[0], "legacy-" + code + ".png"), ImageFormat.Png);
                            }
                        }
                        language.SelectedValue = "ru";
                        Console.WriteLine("PASS GUI cycle " + cycle + ": service, one add button, 31 real language resources");
                    }
                    catch (Exception exception) { failure = exception; }
                    finally { form.Close(); }
                };
                Application.Run(form);
                if (failure != null) throw failure;
                if (!form.IsDisposed || Application.OpenForms.Count != 0)
                    throw new Exception("The GUI retained a window after closing.");
            }
            using var deadline = new CancellationTokenSource(TimeSpan.FromSeconds(8));
            using var connected = CoreService.ConnectAsync(deadline.Token).GetAwaiter().GetResult();
            var status = connected.CallAsync(new GetStatusRequest { ApiVersion = connected.Version },
                GetStatusResponse.Parser, deadline.Token).GetAwaiter().GetResult();
            if (status.Error != null || status.Status.Connection.Value != ConnectionStateValue.Disconnected)
                throw new Exception("Opening and closing the GUI changed the disconnected session.");
            Console.WriteLine("PASS ordinary-user GUI: three native opens/closes, service remains reachable and disconnected");
            return 0;
        }
        catch (Exception exception)
        {
            Console.Error.WriteLine(exception);
            return 1;
        }
    }

    private static IEnumerable<FormsControl> Descendants(FormsControl parent)
    {
        foreach (FormsControl child in parent.Controls)
        {
            yield return child;
            foreach (var nested in Descendants(child)) yield return nested;
        }
    }
}
