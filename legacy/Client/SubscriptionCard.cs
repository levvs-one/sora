using System;
using System.Collections.Generic;
using System.Drawing;
using System.Globalization;
using System.Linq;
using System.Threading.Tasks;
using System.Windows.Forms;
using Sora.Core.V1;
using Button = AntdUI.Button;

namespace Sora.Legacy.Client;

internal sealed class SubscriptionCard : AntdUI.Panel
{
    private readonly ImageList rowSize = new() { ImageSize = new Size(1, 52) };

    public SubscriptionCard(SubscriptionState subscription, int width, Strings text, Font body, Font strong,
        string selected, IReadOnlyDictionary<string, uint> pings, HashSet<string> collapsed,
        HashSet<string> hiddenDescriptions, string search, Action render,
        Func<OutboundSpec, Task> select, Func<Task> refresh, Func<Task> probe, Func<Task> delete, bool connecting)
    {
        Width = width;
        Radius = 12;
        Back = Color.White;
        BorderWidth = 1;
        BorderColor = Color.FromArgb(215, 215, 222);
        Margin = new Padding(0, 8, 0, 4);
        Font = body;
        ForeColor = Color.FromArgb(31, 31, 33);
        var id = subscription.Settings.Id;
        var closed = collapsed.Contains(id);
        var header = new Button
        {
            Bounds = new Rectangle(8, 8, width - 112, 44), Text = subscription.DisplayName,
            Font = strong, TextAlign = ContentAlignment.MiddleLeft, Radius = 8, BorderWidth = 0,
            BackColor = Color.White, BackHover = Color.FromArgb(235, 235, 240), ForeColor = ForeColor,
            IconSvg = Strings.Read("Icons.caret-" + (closed ? "right" : "down") + "-bold.svg"), IconSize = new Size(16, 16), WaveSize = 0
        };
        header.Click += (_, _) => { if (!collapsed.Remove(id)) collapsed.Add(id); render(); };
        Controls.Add(header);
        Button ActionButton(string icon, int x, Func<Task> action)
        {
            var button = new Button
            {
                Bounds = new Rectangle(x, 12, 30, 36), Radius = 8, BorderWidth = 0,
                Font = body, BackColor = Color.White, BackHover = Color.FromArgb(235, 235, 240),
                ForeColor = ForeColor, IconSvg = Strings.Read("Icons." + icon + "-bold.svg"), IconSize = new Size(18, 18), WaveSize = 0
            };
            button.Click += async (_, _) => await action();
            Controls.Add(button);
            return button;
        }
        ActionButton("gauge", width - 102, probe).Enabled = !connecting;
        ActionButton("arrows-clockwise", width - 70, refresh).Loading = subscription.Updating;
        ActionButton("trash", width - 38, delete);
        var y = 56;
        if (subscription.Info?.HasUsage == true)
        {
            var info = subscription.Info;
            var used = (decimal)info.DownloadBytes + info.UploadBytes;
            string Bytes(decimal value) => text["bytesGB"].Replace("{n}", (value / 1073741824m).ToString("0.0", CultureInfo.CurrentCulture));
            var label = new Label { Bounds = new Rectangle(12, y, width - 24, 22), Font = body,
                Text = info.TotalBytes == 0 ? Bytes(used) : text["usage"].Replace("{used}", Bytes(used)).Replace("{total}", Bytes(info.TotalBytes)) };
            Controls.Add(label);
            y += 26;
            Controls.Add(new AntdUI.Progress
            {
                Bounds = new Rectangle(12, y, width - 24, 5), ValueRatio = 1, Radius = 2,
                Fill = ForeColor, Back = Color.FromArgb(235, 235, 240), Text = "",
                Value = info.TotalBytes == 0 ? 0 : (float)Math.Min(1, used / info.TotalBytes)
            });
            y += 12;
        }
        var announce = subscription.Info?.Announce ?? "";
        if (!string.IsNullOrWhiteSpace(announce))
        {
            var hide = hiddenDescriptions.Contains(id);
            var toggle = new Button
            {
                Bounds = new Rectangle((width - 32) / 2, y, 32, 28), BorderWidth = 0, Radius = 6,
                BackColor = Color.White, BackHover = Color.FromArgb(235, 235, 240), ForeColor = ForeColor,
                IconSvg = Strings.Read("Icons.caret-" + (hide ? "down" : "up") + "-bold.svg"), IconSize = new Size(14, 14), WaveSize = 0
            };
            toggle.Click += (_, _) => { if (!hiddenDescriptions.Remove(id)) hiddenDescriptions.Add(id); render(); };
            Controls.Add(toggle);
            y += 32;
            if (!hide)
            {
                var description = new Label { AutoSize = false, Font = body, Text = announce,
                    TextAlign = ContentAlignment.MiddleCenter, Location = new Point(16, y), Width = width - 32 };
                description.Height = TextRenderer.MeasureText(description.Text, body, new Size(description.Width, int.MaxValue),
                    TextFormatFlags.WordBreak | TextFormatFlags.NoPadding).Height + 12;
                Controls.Add(description);
                y += description.Height + 8;
            }
        }
        if (!closed)
        {
            var nodes = subscription.Outbounds.Where(node => node.DisplayName.IndexOf(search, StringComparison.OrdinalIgnoreCase) >= 0).ToArray();
            var list = new ListView
            {
                Bounds = new Rectangle(8, y, width - 16, Math.Min(520, nodes.Length * 52 + 4)),
                View = View.Details, HeaderStyle = ColumnHeaderStyle.None, BorderStyle = System.Windows.Forms.BorderStyle.None,
                VirtualMode = true, OwnerDraw = true, FullRowSelect = true, MultiSelect = false,
                HideSelection = false, Font = body, BackColor = Color.White, ForeColor = ForeColor,
                SmallImageList = rowSize, ShowItemToolTips = true
            };
            list.Columns.Add("", list.ClientSize.Width - 20);
            list.RetrieveVirtualItem += (_, e) => e.Item = new ListViewItem(nodes[e.ItemIndex].DisplayName) { ToolTipText = nodes[e.ItemIndex].DisplayName };
            list.VirtualListSize = nodes.Length;
            list.DrawItem += (_, e) =>
            {
                var node = nodes[e.ItemIndex];
                var rect = e.Bounds;
                using var background = new SolidBrush(node.Id == selected || e.Item.Selected ? Color.FromArgb(235, 235, 240) : Color.White);
                e.Graphics.FillRectangle(background, rect);
                using var separator = new Pen(Color.FromArgb(215, 215, 222));
                if (e.ItemIndex > 0) e.Graphics.DrawLine(separator, rect.Left + 4, rect.Top, rect.Right - 4, rect.Top);
                var name = node.DisplayName;
                var x = rect.Left + 8;
                if (name.Length >= 4 && char.IsSurrogatePair(name, 0) && char.IsSurrogatePair(name, 2))
                {
                    var first = char.ConvertToUtf32(name, 0) - 0x1F1E6;
                    var second = char.ConvertToUtf32(name, 2) - 0x1F1E6;
                    if (first is >= 0 and < 26 && second is >= 0 and < 26)
                    {
                        var country = "" + (char)('a' + first) + (char)('a' + second);
                        var resource = "flags." + country + ".png";
                        if (text.HasResource(resource))
                        {
                            var flag = new Rectangle(x, rect.Top + 8, 24, 16);
                            var saved = e.Graphics.Save();
                            using var clip = AntdUI.Helper.RoundPath(flag, 3);
                            e.Graphics.SetClip(clip);
                            e.Graphics.DrawImage(text.Image(resource), flag);
                            e.Graphics.Restore(saved);
                            x += 32;
                        }
                        name = name.Substring(4).TrimStart();
                    }
                }
                const TextFormatFlags flags = TextFormatFlags.SingleLine | TextFormatFlags.EndEllipsis | TextFormatFlags.VerticalCenter | TextFormatFlags.NoPadding;
                TextRenderer.DrawText(e.Graphics, name, body, new Rectangle(x, rect.Top + 4, rect.Width - (x - rect.Left) - 68, 24), ForeColor, flags);
                var protocol = node.DisplayProtocol.Length > 0 ? node.DisplayProtocol : node.Protocol;
                var detail = string.Join(" | ", new[] { protocol, node.Transport, node.Security }.Where(value => value.Length > 0).Select(value => value.ToUpperInvariant()));
                TextRenderer.DrawText(e.Graphics, detail, body, new Rectangle(rect.Left + 8, rect.Top + 28, rect.Width - 84, 20), ForeColor, flags);
                if (pings.TryGetValue(node.Id, out var latency))
                    TextRenderer.DrawText(e.Graphics, text["milliseconds"].Replace("{n}", latency.ToString(CultureInfo.CurrentCulture)), body,
                        new Rectangle(rect.Right - 68, rect.Top + 8, 64, 32), ForeColor, flags | TextFormatFlags.Right);
                if (e.Item.Focused) e.DrawFocusRectangle();
            };
            list.ItemSelectionChanged += async (_, e) => { if (e.IsSelected) await select(nodes[e.ItemIndex]); };
            Controls.Add(list);
            y += list.Height;
        }
        Height = y + 12;
    }

    protected override void Dispose(bool disposing)
    {
        base.Dispose(disposing);
        if (disposing) rowSize.Dispose();
    }
}
