using System;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Reflection;
using Newtonsoft.Json.Linq;

namespace Sora.Legacy.Client;

internal sealed class Strings : IDisposable
{
    private readonly HashSet<string> resources = new(Assembly.GetExecutingAssembly().GetManifestResourceNames());
    private readonly Dictionary<string, Image> images = new();
    private readonly JObject english = JObject.Parse(Read("l10n.app_en.arb"));
    private JObject translated;
    public JArray Languages { get; } = JArray.Parse(Read("languages.json"));

    public Strings(string language) => translated = JObject.Parse(Read("l10n.app_" + language + ".arb"));
    public string this[string key] => (string?)translated[key] ?? (string?)english[key] ?? throw new InvalidDataException(key);
    public void SetLanguage(string language) => translated = JObject.Parse(Read("l10n.app_" + language + ".arb"));
    public bool HasResource(string name) => resources.Contains("Sora.Legacy.Client.Assets." + name);

    public static string Read(string name)
    {
        using var stream = Assembly.GetExecutingAssembly().GetManifestResourceStream("Sora.Legacy.Client.Assets." + name)
            ?? throw new FileNotFoundException(name);
        using var reader = new StreamReader(stream);
        return reader.ReadToEnd();
    }

    public Image Image(string name)
    {
        if (images.TryGetValue(name, out var image)) return image;
        using var stream = Assembly.GetExecutingAssembly().GetManifestResourceStream("Sora.Legacy.Client.Assets." + name)
            ?? throw new FileNotFoundException(name);
        using var original = System.Drawing.Image.FromStream(stream);
        images[name] = image = new Bitmap(original);
        return image;
    }

    public string Error(string key) => this[key switch
    {
        "core.engine.binary_missing" => "errEngineMissing",
        "core.plan.engine_unsupported" => "errEngineUnsupported",
        "core.guard.restore_failed" => "errRestore",
        "core.session.busy" => "errBusy",
        "core.subscription.duplicate" => "errSubDuplicate",
        "core.subscription.scheme_unsupported" => "errSubScheme",
        "core.subscription.no_servers" => "errSubEmpty",
        "core.subscription.fetch_failed" => "errSubFetch",
        "core.engine.start_failed" => "errEngineStart",
        _ when key.StartsWith("core.plan.", StringComparison.Ordinal) => "errServers",
        _ => "errCore"
    }];

    public void Dispose()
    {
        foreach (var image in images.Values) image.Dispose();
        images.Clear();
    }
}
