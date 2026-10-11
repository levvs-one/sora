using System;
using System.Collections.Generic;
using System.Drawing;
using System.Globalization;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;
using Google.Protobuf;
using Newtonsoft.Json.Linq;
using Sora.Core.V1;
using Sora.Legacy.Control;
using Button = AntdUI.Button;
using FormsControl = System.Windows.Forms.Control;

namespace Sora.Legacy.Client;

internal sealed class MainForm : Form
{
    private static readonly Color Field = Color.FromArgb(235, 235, 240);
    private static readonly Color Background = Color.FromArgb(246, 246, 248);
    private readonly ClientSettings settings = new();
    private readonly Strings text;
    private readonly Font body = new("Segoe UI", 13, FontStyle.Regular, GraphicsUnit.Pixel);
    private readonly Font heading = new("Segoe UI", 22, FontStyle.Bold, GraphicsUnit.Pixel);
    private readonly Font strong = new("Segoe UI", 15, FontStyle.Bold, GraphicsUnit.Pixel);
    private readonly CancellationTokenSource lifetime = new();
    private readonly Dictionary<string, SubscriptionState> subscriptions = new();
    private readonly HashSet<string> collapsed = new(), hiddenDescriptions = new();
    private readonly Dictionary<string, uint> pings = new();
    private readonly FlowLayoutPanel cards = new() { Dock = DockStyle.Fill, AutoScroll = true, FlowDirection = FlowDirection.TopDown, WrapContents = false };
    private readonly FlowLayoutPanel center = new() { Dock = DockStyle.Fill, FlowDirection = FlowDirection.TopDown, WrapContents = false, Padding = new Padding(24, 36, 24, 24) };
    private readonly Label state = new() { Height = 48, TextAlign = ContentAlignment.MiddleCenter };
    private readonly Label error = new() { AutoSize = true, MaximumSize = new Size(460, 0), Margin = new Padding(0, 20, 0, 0) };
    private readonly AntdUI.Input search = new() { Dock = DockStyle.Top, Height = 44, Radius = 8 };
    private readonly System.Windows.Forms.Timer poll = new() { Interval = 1000 };
    private readonly Button orb, add, addAbove, retry, modes, apply;
    private CoreConnection? core;
    private SessionRequests? requests;
    private Task? subscriptionWatch;
    private CancellationTokenSource? probing;
    private SessionStatus? status;
    private bool desiredConnected, closing, polling, connectionPending;
    private long revision;

    public MainForm()
    {
        text = new Strings(settings.Language);
        Text = "Sora Legacy";
        Font = body;
        ForeColor = Color.FromArgb(31, 31, 33);
        BackColor = Background;
        MinimumSize = new Size(780, 560);
        ClientSize = new Size(1060, 720);
        AutoScaleMode = AutoScaleMode.Dpi;
        StartPosition = FormStartPosition.CenterScreen;
        var left = new Panel { Dock = DockStyle.Left, Width = 340, Padding = new Padding(16) };
        var bar = new FlowLayoutPanel { Dock = DockStyle.Top, AutoSize = true, WrapContents = false };
        addAbove = MakeButton("addSubscription", 300);
        addAbove.Click += async (_, _) => await Run(AddSubscription);
        bar.Controls.Add(addAbove);
        left.Controls.Add(cards);
        left.Controls.Add(search);
        left.Controls.Add(bar);
        search.TextChanged += (_, _) => RenderSubscriptions();
        cards.SizeChanged += (_, _) => RenderSubscriptions();

        orb = MakeButton("", 176);
        orb.Height = 176;
        orb.Shape = AntdUI.TShape.Circle;
        orb.Icon = text.Image("logo.png");
        orb.IconSize = new Size(92, 92);
        orb.Enabled = false;
        orb.Click += async (_, _) => await Run(() => ChooseConnection(!desiredConnected));
        add = MakeButton("addSubscription", 280);
        add.Click += async (_, _) => await Run(AddSubscription);
        retry = MakeButton("refresh", 280);
        retry.Click += async (_, _) => await Run(OpenCore);
        modes = MakeButton("modes", 280);
        modes.Click += (_, _) => ChooseModes();
        apply = MakeButton("reconnectNow", 340);
        apply.Visible = false;
        apply.Click += async (_, _) => await Run(() => ChooseConnection(true));
        center.Controls.AddRange(new FormsControl[] { MakeLanguageSelect(), state, orb, modes, apply, add, error, retry });
        center.SizeChanged += (_, _) =>
        {
            var width = center.ClientSize.Width - center.Padding.Horizontal;
            foreach (FormsControl control in center.Controls)
            {
                if (control == state) control.Width = width;
                control.Margin = new Padding(Math.Max(0, (width - control.Width) / 2), 8, 0, 8);
            }
        };
        Controls.Add(center);
        Controls.Add(left);
        Shown += async (_, _) => await Run(OpenCore);
        poll.Tick += async (_, _) =>
        {
            if (core == null || polling) return;
            polling = true;
            try { await ReadStatus(); }
            catch (OperationCanceledException) when (closing) { }
            catch { error.Text = text["errCore"]; retry.Visible = true; }
            finally { polling = false; }
        };
        ApplyText();
    }

    private Button MakeButton(string key, int width) => new()
    {
        Text = key.Length == 0 ? "" : text[key], Tag = key, Width = width, Height = 44,
        Radius = 8, BorderWidth = 0, BackColor = Color.White, BackHover = Field,
        BackActive = Field, ForeColor = ForeColor, ForeHover = ForeColor,
        Font = body, Margin = new Padding(0, 4, 0, 4), WaveSize = 0
    };

    private AntdUI.Select MakeLanguageSelect()
    {
        var select = new AntdUI.Select { Width = 240, Height = 40, Radius = 8, Font = body, BackColor = Color.White, ForeColor = ForeColor, MaxCount = 8 };
        var items = text.Languages.Cast<JObject>().Select(language => new AntdUI.SelectItem(
            text.Image("flags." + language["country"] + ".png"), (string)language["native"]!, (string)language["code"]!)
        { SubText = (string?)language["english"] }).ToArray();
        foreach (var item in items) select.Items.Add(item);
        select.SelectedValue = settings.Language;
        select.FilterChanged += (_, query) => text.Languages.Cast<JObject>()
            .Where(language => string.Join(" ", language.Properties().Select(value => value.Value.ToString()))
                .IndexOf(query, StringComparison.OrdinalIgnoreCase) >= 0)
            .Select(language => (object)items.Single(item => (string)item.Tag == (string)language["code"]!)).ToList();
        select.SelectedValueChanged += (_, choice) =>
        {
            if (choice.Value is not string code || !text.Languages.Any(language => (string?)language["code"] == code)) return;
            settings.Language = code;
            settings.Save();
            text.SetLanguage(code);
            ApplyText();
        };
        return select;
    }

    private void ApplyText()
    {
        foreach (var button in new[] { add, addAbove, retry, modes, apply }) button.Text = text[(string)button.Tag];
        search.PlaceholderText = text["search"];
        state.Font = heading;
        RenderStatus();
        RenderSubscriptions();
    }

    private async Task OpenCore()
    {
        if (core != null) return;
        retry.Loading = true;
        var connected = await CoreService.ConnectAsync(lifetime.Token);
        if (closing) { connected.Dispose(); return; }
        ListSubscriptionsResponse listed;
        try
        {
            using var timeout = CancellationTokenSource.CreateLinkedTokenSource(lifetime.Token);
            timeout.CancelAfter(TimeSpan.FromSeconds(8));
            listed = await connected.CallAsync(new ListSubscriptionsRequest
            { ApiVersion = connected.Version, ControlAuthenticator = connected.Authenticator }, ListSubscriptionsResponse.Parser, timeout.Token);
            Check(listed.Error);
            var initial = await connected.CallAsync(new GetStatusRequest { ApiVersion = connected.Version }, GetStatusResponse.Parser, timeout.Token);
            Check(initial.Error);
            status = initial.Status;
        }
        catch { connected.Dispose(); throw; }
        if (closing) { connected.Dispose(); return; }
        core = connected;
        requests = new SessionRequests(connected);
        subscriptions.Clear();
        foreach (var subscription in listed.Subscriptions) subscriptions[subscription.Settings.Id] = subscription;
        subscriptionWatch = connected.WatchAsync(new WatchSubscriptionsRequest
        { ApiVersion = connected.Version, ControlAuthenticator = connected.Authenticator }, SubscriptionState.Parser,
            new Progress<SubscriptionState>(subscription =>
            {
                if (closing) return;
                if (subscription.Deleted) subscriptions.Remove(subscription.Settings.Id);
                else subscriptions[subscription.Settings.Id] = subscription;
                RenderSubscriptions();
            }), lifetime.Token);
        _ = ObserveSubscriptionWatch(subscriptionWatch, connected);
        desiredConnected = status?.Connection.Value is ConnectionStateValue.Connected or ConnectionStateValue.Connecting or ConnectionStateValue.Reconnecting;
        orb.Enabled = true;
        retry.Loading = false;
        retry.Visible = false;
        error.Text = "";
        poll.Start();
        RenderSubscriptions();
        RenderStatus();
    }

    private async Task ObserveSubscriptionWatch(Task watch, CoreConnection connected)
    {
        try { await watch; }
        catch (Exception) when (closing) { return; }
        catch (Exception) { if (!ReferenceEquals(core, connected)) return; }
        if (closing || !ReferenceEquals(core, connected)) return;
        var worker = requests;
        core = null;
        requests = null;
        poll.Stop();
        orb.Enabled = false;
        error.Text = text["errCore"];
        retry.Visible = true;
        if (worker != null) await worker.StopAsync();
        connected.Dispose();
    }

    private async Task ReadStatus()
    {
        var connected = core ?? throw new InvalidOperationException("core.error.unavailable");
        using var timeout = CancellationTokenSource.CreateLinkedTokenSource(lifetime.Token);
        timeout.CancelAfter(TimeSpan.FromSeconds(5));
        var answer = await connected.CallAsync(new GetStatusRequest { ApiVersion = connected.Version }, GetStatusResponse.Parser, timeout.Token);
        Check(answer.Error);
        status = answer.Status;
        RenderStatus();
    }

    private void RenderStatus()
    {
        var key = status?.Connection.Value switch
        {
            ConnectionStateValue.Connected => "stateConnected",
            ConnectionStateValue.Connecting => "stateConnecting",
            ConnectionStateValue.Reconnecting => "stateReconnecting",
            _ => "stateOff"
        };
        state.Text = text[connectionPending ? desiredConnected ? "stateConnecting" : "stateDisconnecting" : key];
    }

    private async Task ChooseConnection(bool connect)
    {
        var worker = requests ?? throw new InvalidOperationException("core.error.unavailable");
        var current = ++revision;
        var node = subscriptions.Values.SelectMany(subscription => subscription.Outbounds).FirstOrDefault(candidate => candidate.Id == settings.Server)
            ?? subscriptions.Values.SelectMany(subscription => subscription.Outbounds).FirstOrDefault();
        if (connect && node == null) { await AddSubscription(); return; }
        desiredConnected = connect;
        probing?.Cancel();
        connectionPending = true;
        RenderStatus();
        RenderSubscriptions();
        var plan = connect ? new SessionPlan
        {
            TunnelMode = settings.Tun ? TunnelMode.System : TunnelMode.Application,
            NetworkControlAllowed = true,
            TunStack = settings.Tun ? settings.Engine switch { "xray" => settings.XrayStack, "mihomo" => settings.MihomoStack, _ => "" } : ""
        } : null;
        if (plan != null)
        {
            plan.Outbounds.Add(node!.Clone());
            if (settings.Engine.Length > 0) plan.Engines.Add(settings.Engine);
            settings.Server = node.Id;
            settings.Save();
        }
        try
        {
            var result = await worker.SetAsync(plan);
            if (closing || current != revision) return;
            status = result;
            apply.Visible = false;
            error.Text = "";
        }
        catch (OperationCanceledException) when (closing || current != revision) { return; }
        catch
        {
            if (current == revision) desiredConnected = status?.Connection.Value is ConnectionStateValue.Connected or ConnectionStateValue.Reconnecting;
            throw;
        }
        finally
        {
            if (current == revision) connectionPending = false;
            if (!closing) { RenderStatus(); RenderSubscriptions(); }
        }
    }

    private void ChooseModes()
    {
        using var dialog = new Form { Text = text["modes"], Font = body, BackColor = Color.White, AutoSize = true,
            AutoSizeMode = AutoSizeMode.GrowAndShrink, FormBorderStyle = FormBorderStyle.FixedDialog,
            MaximizeBox = false, MinimizeBox = false, StartPosition = FormStartPosition.CenterParent };
        var layout = new FlowLayoutPanel { AutoSize = true, FlowDirection = FlowDirection.TopDown, WrapContents = false, Padding = new Padding(20) };
        var tun = new RadioButton { Text = text["tunMode"], Checked = settings.Tun, AutoSize = true, Margin = new Padding(0, 8, 0, 8) };
        var proxy = new RadioButton { Text = text["tunnelProxy"], Checked = !settings.Tun, AutoSize = true, Margin = tun.Margin };
        var engine = new AntdUI.Select { Width = 300, Height = 44, List = true, Font = strong, BackColor = Field, ForeColor = ForeColor, Radius = 8 };
        engine.Items.Add(new AntdUI.SelectItem(text["engineAuto"], ""));
        foreach (var kind in new[] { "sing-box", "xray", "mihomo" }) engine.Items.Add(new AntdUI.SelectItem(kind, kind));
        engine.SelectedValue = settings.Engine;
        var stack = new AntdUI.Select { Width = 300, Height = 44, List = true, Font = body, Radius = 8 };
        foreach (var name in new[] { "gvisor", "system", "mixed", "mips" }) stack.Items.Add(name);
        void RenderStack()
        {
            stack.Visible = tun.Checked && (string?)engine.SelectedValue is "xray" or "mihomo";
            stack.SelectedValue = (string?)engine.SelectedValue == "xray" ? settings.XrayStack : settings.MihomoStack;
        }
        engine.SelectedValueChanged += (_, _) => RenderStack();
        tun.CheckedChanged += (_, _) => RenderStack();
        var save = MakeButton("save", 300);
        save.Click += (_, _) =>
        {
            settings.Tun = tun.Checked;
            settings.Engine = (string?)engine.SelectedValue ?? "";
            if (settings.Engine == "xray") settings.XrayStack = (string?)stack.SelectedValue ?? "gvisor";
            if (settings.Engine == "mihomo") settings.MihomoStack = (string?)stack.SelectedValue ?? "mixed";
            settings.Save();
            apply.Visible = desiredConnected;
            dialog.DialogResult = DialogResult.OK;
        };
        layout.Controls.AddRange(new FormsControl[] { tun, proxy, engine, stack, save });
        dialog.Controls.Add(layout);
        dialog.AcceptButton = save;
        RenderStack();
        dialog.ShowDialog(this);
    }

    private async Task AddSubscription()
    {
        if (core == null) throw new InvalidOperationException("core.error.unavailable");
        using var dialog = new Form { Text = text["addSubscription"], Font = body, BackColor = Color.White, ClientSize = new Size(460, 156),
            FormBorderStyle = FormBorderStyle.FixedDialog, StartPosition = FormStartPosition.CenterParent, MaximizeBox = false, MinimizeBox = false };
        var input = new AntdUI.Input { Bounds = new Rectangle(20, 20, 420, 48), PlaceholderText = text["subscriptionLink"], Font = body, Radius = 8 };
        var confirm = MakeButton("add", 120);
        confirm.Location = new Point(320, 88);
        confirm.Click += (_, _) => dialog.DialogResult = DialogResult.OK;
        dialog.Controls.AddRange(new FormsControl[] { input, confirm });
        dialog.AcceptButton = confirm;
        if (dialog.ShowDialog(this) != DialogResult.OK) return;
        var answer = await core.CallAsync(new SaveSubscriptionRequest
        {
            ApiVersion = core.Version, ControlAuthenticator = core.Authenticator,
            Settings = new SubscriptionSettings { Url = input.Text.Trim(), AutoUpdate = true }
        }, SaveSubscriptionResponse.Parser, lifetime.Token);
        input.Text = "";
        Check(answer.Error);
        subscriptions[answer.State.Settings.Id] = answer.State;
        RenderSubscriptions();
    }

    private void RenderSubscriptions()
    {
        if (closing) return;
        var scroll = cards.AutoScrollPosition;
        cards.SuspendLayout();
        foreach (var card in cards.Controls.Cast<FormsControl>().ToArray()) card.Dispose();
        cards.Controls.Clear();
        var width = Math.Max(220, cards.ClientSize.Width - 20);
        foreach (var subscription in subscriptions.Values)
            cards.Controls.Add(new SubscriptionCard(subscription, width, text, body, strong, settings.Server, pings,
                collapsed, hiddenDescriptions, search.Text, RenderSubscriptions,
                node => Run(async () => { settings.Server = node.Id; settings.Save(); if (desiredConnected) await ChooseConnection(true); else RenderSubscriptions(); }),
                () => Run(() => RefreshSubscription(subscription.Settings.Id)),
                () => Run(() => Probe(subscription)),
                () => Run(() => DeleteSubscription(subscription)),
                connectionPending || status?.Connection.Value is ConnectionStateValue.Connecting or ConnectionStateValue.Reconnecting));
        cards.ResumeLayout();
        cards.AutoScrollPosition = new Point(-scroll.X, -scroll.Y);
        add.Visible = subscriptions.Count == 0;
        add.Enabled = core != null;
        addAbove.Visible = subscriptions.Count > 0;
        search.Visible = subscriptions.Count > 0;
    }

    private async Task RefreshSubscription(string id)
    {
        if (core == null) return;
        var answer = await core.CallAsync(new RefreshSubscriptionRequest
        { ApiVersion = core.Version, ControlAuthenticator = core.Authenticator, Id = id }, RefreshSubscriptionResponse.Parser, lifetime.Token);
        Check(answer.Error);
        subscriptions[id] = answer.State;
        RenderSubscriptions();
    }

    private async Task Probe(SubscriptionState subscription)
    {
        if (core == null || connectionPending || status?.Connection.Value is ConnectionStateValue.Connecting or ConnectionStateValue.Reconnecting) return;
        probing?.Cancel();
        using var attempt = CancellationTokenSource.CreateLinkedTokenSource(lifetime.Token);
        probing = attempt;
        var request = new ProbeServersRequest { ApiVersion = core.Version, RequestId = Guid.NewGuid().ToString("N"), Options = new ProbeOptions { Concurrency = 2, TimeoutMs = 3000 } };
        request.Outbounds.Add(subscription.Outbounds);
        try
        {
            await core.WatchAsync(request, ProbeResult.Parser, new Progress<ProbeResult>(result =>
            {
                if (closing || attempt.IsCancellationRequested) return;
                if (result.Reachable) pings[result.ServerId] = result.LatencyMs;
                else pings.Remove(result.ServerId);
                RenderSubscriptions();
            }), attempt.Token);
        }
        catch (OperationCanceledException) when (attempt.IsCancellationRequested) { }
        finally { if (ReferenceEquals(probing, attempt)) probing = null; }
    }

    private async Task DeleteSubscription(SubscriptionState subscription)
    {
        if (core == null || MessageBox.Show(this, text["deleteSubscription"].Replace("{name}", subscription.DisplayName),
            text["delete"], MessageBoxButtons.OKCancel, MessageBoxIcon.None) != DialogResult.OK) return;
        var answer = await core.CallAsync(new DeleteSubscriptionRequest
        { ApiVersion = core.Version, ControlAuthenticator = core.Authenticator, Id = subscription.Settings.Id }, DeleteSubscriptionResponse.Parser, lifetime.Token);
        Check(answer.Error);
        subscriptions.Remove(subscription.Settings.Id);
        RenderSubscriptions();
    }

    private static void Check(SoraError? error)
    {
        if (error != null) throw new InvalidOperationException(error.UserMessageKey);
    }

    private async Task Run(Func<Task> action)
    {
        try { await action(); }
        catch (OperationCanceledException) when (closing) { }
        catch (Exception exception)
        {
            if (closing) return;
            error.Text = exception is InvalidOperationException ? text.Error(exception.Message) : text["errGeneric"];
            retry.Visible = core == null;
            retry.Loading = false;
        }
    }

    protected override async void OnFormClosing(FormClosingEventArgs e)
    {
        if (closing) { base.OnFormClosing(e); return; }
        e.Cancel = true;
        closing = true;
        poll.Stop();
        lifetime.Cancel();
        try
        {
            if (requests != null) await requests.StopAsync();
            if (subscriptionWatch != null) await subscriptionWatch;
        }
        catch (OperationCanceledException) { System.Diagnostics.Trace.WriteLine("Legacy client watches cancelled during shutdown."); }
        catch (Exception exception) { System.Diagnostics.Trace.WriteLine("Legacy client shutdown: " + exception.GetType().Name); }
        finally
        {
            core?.Dispose();
            Close();
        }
    }

    protected override void Dispose(bool disposing)
    {
        base.Dispose(disposing);
        if (!disposing) return;
        poll.Dispose();
        lifetime.Dispose();
        text.Dispose();
        body.Dispose();
        strong.Dispose();
        heading.Dispose();
    }
}
