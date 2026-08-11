#:package Microsoft.Playwright@1.62.0
#:property PublishAot=false

// A realistic ASP.NET Core flow: log in, navigate, assert, screenshot on failure.
// Exits non-zero when the flow breaks, so with-server.ps1 propagates a usable pass/fail.
// Run:  pwsh ../scripts/with-server.ps1 -Server "dotnet run --project src/Web --urls http://localhost:5000" -Port 5000 -Run "dotnet run AspNetCoreFlow.cs"

using Microsoft.Playwright;

var baseUrl = args.Length > 0 ? args[0] : "http://localhost:5000";
var shotDir = Path.GetTempPath();

Microsoft.Playwright.Program.Main(["install", "chromium"]);

using var playwright = await Playwright.CreateAsync();
await using var browser = await playwright.Chromium.LaunchAsync(new() { Headless = true });

// BaseURL lets the script use relative paths. IgnoreHTTPSErrors covers the ASP.NET dev cert.
await using var context = await browser.NewContextAsync(new()
{
    BaseURL = baseUrl,
    IgnoreHTTPSErrors = true,
    ViewportSize = new() { Width = 1920, Height = 1080 },
});

var page = await context.NewPageAsync();
page.PageError += (_, err) => Console.Error.WriteLine($"[pageerror] {err}");

try
{
    await page.GotoAsync("/Identity/Account/Login");

    // Label-based locators survive markup churn better than CSS and match what a user sees.
    await page.GetByLabel("Email").FillAsync("test@example.com");
    await page.GetByLabel("Password").FillAsync("Passw0rd!");

    // Clicking a form submit triggers navigation; the click auto-waits for it.
    await page.GetByRole(AriaRole.Button, new() { Name = "Log in" }).ClickAsync();

    // Web-first assertions retry for up to 5s - no Task.Delay needed.
    await Assertions.Expect(page.GetByRole(AriaRole.Heading, new() { Name = "Dashboard" })).ToBeVisibleAsync();
    await Assertions.Expect(page).ToHaveURLAsync(new System.Text.RegularExpressions.Regex(".*/Dashboard"));

    // Anti-forgery failures and server errors surface as a 400/500 page, not an exception:
    // asserting on visible content is what actually catches them.
    await page.GetByRole(AriaRole.Link, new() { Name = "Reports" }).ClickAsync();
    await Assertions.Expect(page.Locator("table tbody tr")).Not.ToHaveCountAsync(0);

    await page.ScreenshotAsync(new() { Path = Path.Combine(shotDir, "flow_ok.png"), FullPage = true });
    Console.WriteLine($"Flow passed. Screenshot: {Path.Combine(shotDir, "flow_ok.png")}");
    return 0;
}
catch (Exception ex)
{
    // Capture the failure state - the screenshot usually explains it faster than the stack trace.
    var shot = Path.Combine(shotDir, "flow_failure.png");
    await page.ScreenshotAsync(new() { Path = shot, FullPage = true });
    Console.Error.WriteLine($"Flow FAILED at {page.Url}: {ex.Message}");
    Console.Error.WriteLine($"Failure screenshot: {shot}");
    return 1;
}
