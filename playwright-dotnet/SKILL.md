---
name: playwright-dotnet
description: Toolkit for interacting with and testing web applications from .NET using Microsoft.Playwright (C#). Use when verifying ASP.NET Core / Blazor / MVC / SPA frontends, debugging UI behavior, capturing browser screenshots, viewing browser console logs, or writing Playwright tests with TUnit, NUnit, MSTest, or xUnit on Microsoft.Testing.Platform (MTP) or VSTest.
license: Complete terms in LICENSE.txt
---

# Web Application Testing with .NET Playwright

Two ways to drive a browser from .NET. Pick based on whether the result should live in the repo:

| | Throwaway automation | Test suite |
|---|---|---|
| **Use when** | Verifying a change, reproducing a bug, capturing a screenshot, exploring the DOM | The check should run in CI and keep running |
| **Form** | Single-file C# app (`dotnet run script.cs`, .NET 10 SDK) | TUnit, NUnit, MSTest, or xUnit project with a Playwright integration package |
| **Start with** | `examples/*.cs` in this skill | `references/test-projects.md`, or `scripts/init-playwright.ps1` |

Default to the throwaway script unless the user asked for tests.

**Picking a runner** — match the repo first; if it has an existing test project, use that framework and stop reading here.

| Runner | Package | Platform | Pick it when |
|---|---|---|---|
| TUnit | `TUnit.Playwright` | MTP only | Greenfield suite; want source-generated tests, no reflection, async-first lifecycle, Native AOT support |
| NUnit | `Microsoft.Playwright.NUnit` | VSTest or MTP | Default for a mixed/unknown repo — the most documented Playwright .NET path |
| MSTest | `Microsoft.Playwright.MSTest` | VSTest or MTP | Repo already on MSTest |
| xUnit v3 | `Microsoft.Playwright.Xunit.v3` | VSTest or MTP | Repo already on xUnit (v2 uses `Microsoft.Playwright.Xunit`) |

`scripts/init-playwright.ps1 -Framework <name> [-Mtp]` scaffolds any of them.

**Helper scripts available**:
- `scripts/with-server.ps1` — starts one or more servers, waits for the ports, runs a command, tears everything down
- `scripts/init-playwright.ps1` — scaffolds a TUnit/NUnit/MSTest/xUnit + Playwright project, optionally on MTP, and installs browsers

**Always read their usage first** with `Get-Help ./scripts/<name>.ps1 -Full`. DO NOT read their source until running them proves a customized solution is absolutely necessary. They exist to be called as black boxes rather than ingested into the context window.

## Decision Tree: Choosing Your Approach

```
User task → Is it static HTML (no server)?
    ├─ Yes → Read the HTML file directly to identify selectors
    │         ├─ Success → Write a Playwright script using file:// (examples/StaticHtmlAutomation.cs)
    │         └─ Fails/Incomplete → Treat as dynamic (below)
    │
    └─ No (dynamic webapp) → Is the server already running?
        ├─ No → Run: Get-Help ./scripts/with-server.ps1 -Full
        │        Then use the helper + write a simplified Playwright script
        │
        └─ Yes → Reconnaissance-then-action:
            1. Navigate and wait for the page to settle
            2. Screenshot or dump the DOM (examples/ElementDiscovery.cs)
            3. Identify selectors from the rendered state
            4. Execute actions with the discovered selectors
```

## The .NET API in one screen

The .NET binding is **async-only** — there is no `sync_api` equivalent. Every call is awaited.

```csharp
#:package Microsoft.Playwright@1.62.0
#:property PublishAot=false

using Microsoft.Playwright;

// Downloads the browser build matched to this Playwright version. Cheap no-op once installed.
Microsoft.Playwright.Program.Main(["install", "chromium"]);

using var playwright = await Playwright.CreateAsync();
await using var browser = await playwright.Chromium.LaunchAsync(new() { Headless = true });
var page = await browser.NewPageAsync();

await page.GotoAsync("http://localhost:5000");
await page.WaitForLoadStateAsync(LoadState.NetworkIdle); // wait for JS to execute

await page.GetByRole(AriaRole.Button, new() { Name = "Save" }).ClickAsync();
await page.ScreenshotAsync(new() { Path = Path.Combine(Path.GetTempPath(), "after.png"), FullPage = true });
```

Run it: `dotnet run script.cs` (single-file apps need the .NET 10 SDK — check with `dotnet --list-sdks`; if only .NET 8/9 is available, see "No .NET 10 SDK" below).

`#:property PublishAot=false` is not optional. File-based apps are AOT-shaped by default, which
turns off reflection-based `System.Text.Json`, and Playwright's driver protocol needs it. Without
the line, `Playwright.CreateAsync()` throws:

```
System.InvalidOperationException: Reflection-based serialization has been disabled for this application.
```

Python → C# translation, when porting a snippet:

| Python | C# |
|---|---|
| `p.chromium.launch(headless=True)` | `await playwright.Chromium.LaunchAsync(new() { Headless = true })` |
| `page.goto(url)` | `await page.GotoAsync(url)` |
| `page.wait_for_load_state('networkidle')` | `await page.WaitForLoadStateAsync(LoadState.NetworkIdle)` |
| `page.click('text=Save')` | `await page.ClickAsync("text=Save")` |
| `page.fill('#email', v)` | `await page.FillAsync("#email", v)` |
| `page.locator('button').all()` | `await page.Locator("button").AllAsync()` |
| `elem.inner_text()` | `await elem.InnerTextAsync()` |
| `page.on("console", handler)` | `page.Console += (_, msg) => ...` (event, not callback) |
| `expect(loc).to_be_visible()` | `await Assertions.Expect(loc).ToBeVisibleAsync()` |

Options objects are records — use the target-typed `new() { ... }`, never positional args.

## Browser installation

`Program.Main(["install", "chromium"])` inside the script is the reliable path and works for both single-file apps and projects. The alternative, `pwsh bin/Debug/net8.0/playwright.ps1 install`, requires a built project and the right TFM path, so prefer it only inside test projects (`scripts/init-playwright.ps1` handles it).

Browsers land in `~/AppData/Local/ms-playwright` (Windows) or `~/.cache/ms-playwright` (Linux/macOS) and are shared across the machine. If a launch fails with "Executable doesn't exist", the cached build does not match the package version — rerun the install line.

## Example: Using with-server.ps1

Read `Get-Help ./scripts/with-server.ps1 -Full` first, then use the helper. Servers are started, port-polled, and killed (whole process
tree) for you, and the runner's exit code becomes the script's exit code.

**Single server:**
```bash
pwsh scripts/with-server.ps1 -Server "dotnet run --project src/Web --urls http://localhost:5000" -Port 5000 -Run "dotnet run smoke.cs"
```

**Multiple servers (API + SPA frontend):**
```bash
pwsh scripts/with-server.ps1 -Server "dotnet run --project src/Api --urls http://localhost:5000","npm run dev" -Port 5000,5173 -Run "dotnet test tests/UiTests"
```

`-Server`/`-Port` are parallel arrays, and `-Run` is one quoted string — quote it, or its own
flags get parsed as parameters of the helper. A port that is already listening is left alone, so
the same command works whether or not the dev server is already up.

Always pass `--urls` (or set `ASPNETCORE_URLS`) when launching an ASP.NET Core app. Otherwise the port comes from `Properties/launchSettings.json` and may not be what you assumed.

The automation script then contains only Playwright logic — the server is already up:

```csharp
#:package Microsoft.Playwright@1.62.0
#:property PublishAot=false
using Microsoft.Playwright;

Microsoft.Playwright.Program.Main(["install", "chromium"]);
using var playwright = await Playwright.CreateAsync();
await using var browser = await playwright.Chromium.LaunchAsync(new() { Headless = true });
var page = await browser.NewPageAsync();
await page.GotoAsync("http://localhost:5000");
await page.WaitForLoadStateAsync(LoadState.NetworkIdle);
// ... automation logic
```

## Reconnaissance-Then-Action Pattern

1. **Inspect the rendered DOM**:
   ```csharp
   await page.ScreenshotAsync(new() { Path = Path.Combine(Path.GetTempPath(), "inspect.png"), FullPage = true });
   var html = await page.ContentAsync();
   var buttons = await page.Locator("button").AllAsync();
   ```

2. **Identify selectors** from the inspection results

3. **Execute actions** using the discovered selectors

`examples/ElementDiscovery.cs` does step 1 and prints a selector inventory — run it before guessing at selectors.

## Common Pitfalls

❌ **Don't** inspect the DOM before the page has settled on a dynamic app
✅ **Do** `await page.WaitForLoadStateAsync(LoadState.NetworkIdle)` (or wait on a specific element) first

❌ **Don't** call `Program.Main(["install", ...])` after `Playwright.CreateAsync()` — install first, then create
✅ **Do** keep the install line as the first statement

❌ **Don't** use `NetworkIdle` on Blazor Server, SignalR hubs, or anything long-polling — the connection never goes idle and the wait burns its timeout
✅ **Do** wait for a real element instead: `await page.GetByRole(AriaRole.Heading, new() { Name = "Dashboard" }).WaitForAsync()`

❌ **Don't** hit an HTTPS dev URL and let cert errors kill the run
✅ **Do** either use the HTTP endpoint or launch with `new BrowserNewContextOptions { IgnoreHTTPSErrors = true }`

❌ **Don't** sprinkle `Task.Delay` / `WaitForTimeoutAsync` to paper over races
✅ **Do** rely on Playwright's auto-waiting and web-first assertions (`Assertions.Expect(...).ToBeVisibleAsync()`), which retry until the timeout

**Windows MAX_PATH**: building a test project under a deep directory fails with `MSB3021 ... exceeds
the OS max path limit` while copying the `.playwright` asset tree. Move the project to a shorter
path, or enable long paths machine-wide (`LongPathsEnabled` under
`HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem`, requires admin + reboot). Single-file scripts
avoid this — their build output lives in a short temp path.

## Best Practices

- **Use the bundled scripts as black boxes** — check whether `scripts/` already solves the task, read `Get-Help <script> -Full` for usage, then invoke directly rather than reading the source.
- Always `Headless = true` — CI and agent environments have no display. Headed runs are for a human debugging locally (`$env:HEADED=1`).
- `using var playwright` / `await using var browser` — dispose both, or the Node driver process leaks and the run hangs.
- Prefer user-facing locators: `GetByRole`, `GetByLabel`, `GetByText`, then `data-testid`, then CSS/XPath as a last resort.
- Set an explicit viewport for screenshots: `await browser.NewPageAsync(new() { ViewportSize = new() { Width = 1920, Height = 1080 } })`.
- Capture console and page errors while automating — a blank page is usually a JS exception (`examples/ConsoleLogging.cs`).
- Write screenshots and logs under `Path.GetTempPath()`, not the repo.
- Unhandled exceptions in a top-level-statement script exit non-zero, which `with-server.ps1` propagates — good enough as a pass/fail signal.

## No .NET 10 SDK

Single-file `dotnet run script.cs` needs the .NET 10 SDK. Without it, create a throwaway console project instead:

```bash
dotnet new console -o /tmp/pwauto && dotnet add /tmp/pwauto package Microsoft.Playwright && dotnet run --project /tmp/pwauto
```

The script body is identical minus the `#:` directive lines (top-level statements work on .NET 6+,
and a normal project does not disable reflection-based JSON).

## Reference Files

- **examples/** — runnable single-file scripts:
  - `ElementDiscovery.cs` — inventory buttons, links, and inputs on a rendered page
  - `StaticHtmlAutomation.cs` — `file://` automation of a local HTML file
  - `ConsoleLogging.cs` — capture console messages, page errors, and failed requests
  - `AspNetCoreFlow.cs` — login form, navigation, and web-first assertions against an ASP.NET Core app
- **references/test-projects.md** — TUnit/NUnit/MSTest/xUnit setup, MTP vs VSTest, fixtures, traces, video, CI wiring
- **scripts/init-playwright.ps1** — scaffold a test project on any of the four runners and install browsers
- **scripts/with-server.ps1** — server lifecycle management

---

Structure adapted from the `webapp-testing` skill in [anthropics/skills](https://github.com/anthropics/skills/blob/main/skills/webapp-testing/SKILL.md) (Apache-2.0, see LICENSE.txt).
