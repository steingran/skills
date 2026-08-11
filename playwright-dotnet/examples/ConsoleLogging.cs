#:package Microsoft.Playwright@1.62.0
#:property PublishAot=false

// Capture browser console output, uncaught page exceptions, and failed network requests.
// A blank or half-rendered page is almost always explained by one of these three.
// Run:  dotnet run ConsoleLogging.cs [url]

using System.Text;
using Microsoft.Playwright;

var url = args.Length > 0 ? args[0] : "http://localhost:5000";
var logPath = Path.Combine(Path.GetTempPath(), "browser.log");
var log = new StringBuilder();

void Record(string line)
{
    log.AppendLine(line);
    Console.WriteLine(line);
}

Microsoft.Playwright.Program.Main(["install", "chromium"]);

using var playwright = await Playwright.CreateAsync();
await using var browser = await playwright.Chromium.LaunchAsync(new() { Headless = true });
var page = await browser.NewPageAsync(new() { ViewportSize = new() { Width = 1920, Height = 1080 } });

// In .NET these are events (+=), not page.on("console", ...) callbacks.
// Subscribe BEFORE GotoAsync or the load-time messages are missed.
page.Console += (_, msg) => Record($"[console:{msg.Type}] {msg.Text}");
page.PageError += (_, err) => Record($"[pageerror] {err}");
page.RequestFailed += (_, req) => Record($"[requestfailed] {req.Method} {req.Url} - {req.Failure}");
page.Response += (_, res) =>
{
    if (res.Status >= 400) Record($"[http {res.Status}] {res.Url}");
};

await page.GotoAsync(url);
await page.WaitForLoadStateAsync(LoadState.NetworkIdle);

// Drive the app a little - most interesting logs appear on interaction, not load.
var dashboard = page.GetByRole(AriaRole.Link, new() { Name = "Dashboard" });
if (await dashboard.CountAsync() > 0)
{
    await dashboard.First.ClickAsync();
    await page.WaitForLoadStateAsync(LoadState.NetworkIdle);
}

await File.WriteAllTextAsync(logPath, log.ToString());

var errors = log.ToString().Split('\n').Count(l => l.Contains("[pageerror]") || l.Contains("[console:error]"));
Console.WriteLine($"\nLog written to {logPath}");
Console.WriteLine(errors > 0 ? $"{errors} error-level message(s) - investigate these first." : "No error-level messages.");
