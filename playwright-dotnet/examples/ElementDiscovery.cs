#:package Microsoft.Playwright@1.62.0
#:property PublishAot=false

// Reconnaissance: print an inventory of the interactive elements on a rendered page.
// Run:  dotnet run ElementDiscovery.cs [url]

using Microsoft.Playwright;

var url = args.Length > 0 ? args[0] : "http://localhost:5000";
var shot = Path.Combine(Path.GetTempPath(), "page_discovery.png");

// Install the browser build matched to this package version (no-op once cached).
Microsoft.Playwright.Program.Main(["install", "chromium"]);

using var playwright = await Playwright.CreateAsync();
await using var browser = await playwright.Chromium.LaunchAsync(new() { Headless = true });
var page = await browser.NewPageAsync(new()
{
    ViewportSize = new() { Width = 1920, Height = 1080 },
    IgnoreHTTPSErrors = true,
});

await page.GotoAsync(url);
await page.WaitForLoadStateAsync(LoadState.NetworkIdle); // CRITICAL: let client-side JS render

Console.WriteLine($"Title: {await page.TitleAsync()}");
Console.WriteLine($"URL:   {page.Url}\n");

var buttons = await page.Locator("button, [role=button], input[type=submit]").AllAsync();
Console.WriteLine($"Found {buttons.Count} buttons:");
foreach (var (button, i) in buttons.Select((b, i) => (b, i)))
{
    var text = await button.IsVisibleAsync() ? (await button.InnerTextAsync()).Trim() : "[hidden]";
    var testId = await button.GetAttributeAsync("data-testid");
    Console.WriteLine($"  [{i}] {(string.IsNullOrWhiteSpace(text) ? "[no text]" : text)}{(testId is null ? "" : $"  data-testid={testId}")}");
}

var links = await page.Locator("a[href]").AllAsync();
Console.WriteLine($"\nFound {links.Count} links:");
foreach (var link in links.Take(10))
{
    var text = (await link.InnerTextAsync()).Trim();
    Console.WriteLine($"  - {text} -> {await link.GetAttributeAsync("href")}");
}

var inputs = await page.Locator("input, textarea, select").AllAsync();
Console.WriteLine($"\nFound {inputs.Count} input fields:");
foreach (var input in inputs)
{
    var name = await input.GetAttributeAsync("name")
               ?? await input.GetAttributeAsync("id")
               ?? await input.GetAttributeAsync("placeholder")
               ?? "[unnamed]";
    var type = await input.GetAttributeAsync("type") ?? "text";
    Console.WriteLine($"  - {name} ({type})");
}

// Headings give a quick read on page structure and are good GetByRole targets.
var headings = await page.Locator("h1, h2, h3").AllInnerTextsAsync();
Console.WriteLine($"\nHeadings: {string.Join(" | ", headings.Select(h => h.Trim()).Where(h => h.Length > 0).Take(10))}");

await page.ScreenshotAsync(new() { Path = shot, FullPage = true });
Console.WriteLine($"\nScreenshot saved to {shot}");
