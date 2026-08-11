#:package Microsoft.Playwright@1.62.0
#:property PublishAot=false

// Automating a local HTML file over file:// - no server needed.
// Run:  dotnet run StaticHtmlAutomation.cs path/to/page.html

using Microsoft.Playwright;

var htmlPath = Path.GetFullPath(args.Length > 0 ? args[0] : "index.html");
if (!File.Exists(htmlPath)) { Console.Error.WriteLine($"No such file: {htmlPath}"); return 1; }

// new Uri(path).AbsoluteUri handles drive letters, spaces, and separators on every OS.
var fileUrl = new Uri(htmlPath).AbsoluteUri;
var outDir = Path.GetTempPath();

Microsoft.Playwright.Program.Main(["install", "chromium"]);

using var playwright = await Playwright.CreateAsync();
await using var browser = await playwright.Chromium.LaunchAsync(new() { Headless = true });
var page = await browser.NewPageAsync(new() { ViewportSize = new() { Width = 1920, Height = 1080 } });

await page.GotoAsync(fileUrl);
await page.ScreenshotAsync(new() { Path = Path.Combine(outDir, "static_page.png"), FullPage = true });

// Interact - locators auto-wait for the element to be actionable.
await page.FillAsync("#name", "John Doe");
await page.FillAsync("#email", "john@example.com");
await page.GetByRole(AriaRole.Button, new() { Name = "Submit" }).ClickAsync();

// Assert on the result instead of sleeping: this retries until it passes or times out.
await Assertions.Expect(page.Locator("#result")).ToContainTextAsync("Thanks");

await page.ScreenshotAsync(new() { Path = Path.Combine(outDir, "after_submit.png"), FullPage = true });
Console.WriteLine($"Static HTML automation completed. Screenshots in {outDir}");
return 0;
