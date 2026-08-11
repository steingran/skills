# Playwright test projects in .NET

Read this when the browser check belongs in the repo and should run in CI. For one-off
verification, use a single-file script instead (see SKILL.md).

`scripts/init-playwright.ps1` performs the setup below end to end; the details here are for
customizing what it produced or working inside an existing suite.

## Packages

| Runner | Package | Test platform | Base classes |
|---|---|---|---|
| TUnit | `TUnit.Playwright` | MTP only | `PageTest`, `ContextTest`, `BrowserTest`, `PlaywrightTest` |
| NUnit | `Microsoft.Playwright.NUnit` | VSTest or MTP | same four |
| MSTest | `Microsoft.Playwright.MSTest` | VSTest or MTP | same four |
| xUnit v3 | `Microsoft.Playwright.Xunit.v3` | VSTest or MTP | same four (namespace `Microsoft.Playwright.Xunit.v3`) |
| xUnit v2 | `Microsoft.Playwright.Xunit` | VSTest | same four |

`TUnit.Playwright` versions with TUnit, not with Playwright — TUnit.Playwright 1.64.x depends
on Microsoft.Playwright 1.62.0. The `Microsoft.Playwright.*` integration packages version with
Playwright itself.

The base classes ladder down in scope: `PageTest` gives a fresh `Page` per test,
`ContextTest` a fresh context, `BrowserTest` a shared browser, `PlaywrightTest` only the
`Playwright` object. Fresh-page-per-test is the default worth keeping — it is what makes
tests independent.

The SDK also ships `dotnet new nunit-playwright` and `mstest-playwright` templates. They work,
but pin an older Playwright — `dotnet add package Microsoft.Playwright.NUnit` afterwards, or use
`scripts/init-playwright.ps1`, which always takes the current version.

Browsers must be installed once after building:

```bash
pwsh tests/UiTests/bin/Debug/net10.0/playwright.ps1 install --with-deps chromium
```

`--with-deps` also installs OS-level libraries; needed on Linux/CI, harmless elsewhere.

## NUnit

```csharp
using Microsoft.Playwright;
using Microsoft.Playwright.NUnit;
using NUnit.Framework;

[Parallelizable(ParallelScope.Self)]  // NUnit runs fixtures in parallel; each test owns its page
[TestFixture]
public class CheckoutTests : PageTest
{
    public override BrowserNewContextOptions ContextOptions() => new()
    {
        BaseURL = "http://localhost:5000",
        IgnoreHTTPSErrors = true,
        ViewportSize = new() { Width = 1920, Height = 1080 },
        Locale = "en-US",
    };

    [Test]
    public async Task AddToCart_UpdatesBadge()
    {
        await Page.GotoAsync("/catalog");
        await Page.GetByRole(AriaRole.Button, new() { Name = "Add to cart" }).First.ClickAsync();

        // Expect() comes from the base class and retries until timeout.
        await Expect(Page.GetByTestId("cart-count")).ToHaveTextAsync("1");
    }
}
```

## TUnit

TUnit is MTP-native, source-generated (no reflection at run time), and async-first. Its
Playwright integration mirrors the Microsoft ones with two differences worth knowing:

- `ContextOptions` takes a `TestContext` parameter — `public override BrowserNewContextOptions
  ContextOptions(TestContext testContext)`. Copying an NUnit fixture verbatim fails to compile
  with CS0115 "no suitable method found to override".
- Launch options go through the constructor: `public MyTests() : base(new BrowserTypeLaunchOptions
  { Headless = true, SlowMo = 100 }) { }`.

`Expect(...)` is inherited from `PlaywrightTest`, so Playwright's retrying web-first assertions
work as usual; TUnit's own `Assert.That(value)` is awaited and used for plain values.

```csharp
using Microsoft.Playwright;
using TUnit.Core;
using TUnit.Playwright;

public class CheckoutTests : PageTest
{
    public override BrowserNewContextOptions ContextOptions(TestContext testContext) => new()
    {
        BaseURL = "http://localhost:5000",
        IgnoreHTTPSErrors = true,
        ViewportSize = new() { Width = 1920, Height = 1080 },
    };

    [Test]
    public async Task AddToCart_UpdatesBadge()
    {
        await Page.GotoAsync("/catalog");
        await Page.GetByRole(AriaRole.Button, new() { Name = "Add to cart" }).First.ClickAsync();

        await Expect(Page.GetByTestId("cart-count")).ToHaveTextAsync("1");
        await Assert.That(await Page.TitleAsync()).IsNotEmpty();
    }
}
```

Browser tests are heavy, so cap their concurrency rather than the whole suite:

```csharp
[ParallelLimiter<BrowserParallelLimit>]
public class HeavyBrowserTests : PageTest { }
```

There is no `dotnet new` template in the SDK. The project is a plain exe:

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <OutputType>Exe</OutputType>
    <ImplicitUsings>enable</ImplicitUsings>
    <IsTestProject>true</IsTestProject>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="TUnit" Version="*" />
    <PackageReference Include="TUnit.Playwright" Version="*" />
  </ItemGroup>
</Project>
```

## xUnit v3

`Microsoft.Playwright.Xunit.v3` gives the same base classes, but the namespace carries the
version: `using Microsoft.Playwright.Xunit.v3;`. Using `Microsoft.Playwright.Xunit` (the v2
package's namespace) is the usual cause of "The type or namespace name 'PageTest' could not be
found". Tests are marked `[Fact]`; `ContextOptions()` is parameterless as in NUnit.

## Microsoft.Testing.Platform (MTP) vs VSTest

MTP is the replacement for VSTest: the test project becomes an executable that hosts the runner
itself, so `vstest.console` and reflection-based discovery drop out of the picture. TUnit only
runs on MTP; NUnit, MSTest, and xUnit run on either.

Per-runner opt-in, in the csproj (`scripts/init-playwright.ps1 -Mtp` sets these):

| Runner | Property | Also needs |
|---|---|---|
| NUnit | `<EnableNUnitRunner>true</EnableNUnitRunner>` | `NUnit3TestAdapter` ≥ 5.0, `<OutputType>Exe</OutputType>` |
| MSTest | `<EnableMSTestRunner>true</EnableMSTestRunner>` | `<OutputType>Exe</OutputType>` |
| xUnit v3 | `<UseMicrosoftTestingPlatformRunner>true</UseMicrosoftTestingPlatformRunner>` | `<OutputType>Exe</OutputType>` |
| TUnit | — (always MTP) | `<OutputType>Exe</OutputType>` |

Running them:

```bash
dotnet run --project tests/UiTests                                  # always works, no global.json needed
dotnet run --project tests/UiTests -- --filter "HomePage*"          # MTP CLI options come after --
dotnet run --project tests/UiTests -- --settings config.runsettings
```

For `dotnet test` to drive MTP projects on the .NET 10 SDK, add a `global.json`:

```json
{
  "test": {
    "runner": "Microsoft.Testing.Platform"
  }
}
```

Two things bite here:

1. **`global.json` is resolved from the working directory upward, not from the project path.**
   `dotnet test --project tests/UiTests` run from a directory without it silently stays in VSTest
   mode and fails with `MSBUILD : error MSB1001: Unknown switch ... --project`. Put `global.json`
   at the repo root.
2. **It is all-or-nothing.** Every test project under that `global.json` must be MTP-based;
   mixed VSTest/MTP solutions are not supported. Migrate the whole repo or none of it.

`dotnet test <path>` (the bare positional path) is not supported in MTP mode — use `--project`,
`--solution`, or `--test-modules`.

## Configuration

Runsettings apply to the NUnit/MSTest/xUnit runners (they bridge to VSTest settings); TUnit does
not read them — configure it through base-class constructors, `[ParallelLimiter<T>]`, and env vars.

`.runsettings` next to the test project, applied with `dotnet test --settings .runsettings` (VSTest
mode) or `dotnet run --project ... -- --settings .runsettings` (MTP):

```xml
<?xml version="1.0" encoding="utf-8"?>
<RunSettings>
  <Playwright>
    <BrowserName>chromium</BrowserName>
    <ExpectTimeout>5000</ExpectTimeout>
    <LaunchOptions>
      <Headless>true</Headless>
      <SlowMo>0</SlowMo>
    </LaunchOptions>
  </Playwright>
</RunSettings>
```

Overrides without editing files (VSTest mode):

```bash
dotnet test -- Playwright.BrowserName=webkit
dotnet test -- Playwright.LaunchOptions.Headless=false
```

Environment variables work in every mode and framework, TUnit included: `HEADED=1` runs headed,
`PWDEBUG=1` opens the Playwright Inspector and disables timeouts, `DEBUG=pw:api` logs every
Playwright call.

## Traces, video, screenshots on failure

Traces are the highest-value debugging artifact — DOM snapshots, network, console, per action.
The NUnit form below; in TUnit use `[Before(Test)]` / `[After(Test)]` and the injected
`TestContext`, in xUnit `InitializeAsync` / `DisposeAsync`.

```csharp
[SetUp]
public async Task StartTrace() =>
    await Context.Tracing.StartAsync(new() { Screenshots = true, Snapshots = true, Sources = true });

[TearDown]
public async Task StopTrace()
{
    var failed = TestContext.CurrentContext.Result.Outcome.Status == NUnit.Framework.Interfaces.TestStatus.Failed;
    await Context.Tracing.StopAsync(new()
    {
        Path = failed
            ? Path.Combine(TestContext.CurrentContext.WorkDirectory, "traces", $"{TestContext.CurrentContext.Test.Name}.zip")
            : null,   // null path discards the trace for passing tests
    });
}
```

View one with `pwsh bin/Debug/net8.0/playwright.ps1 show-trace traces/MyTest.zip`.

Video needs context options: `RecordVideoDir = "videos/"` in `ContextOptions()`.

## Testing an ASP.NET Core app in-process

`WebApplicationFactory` normally hosts on `TestServer`, which has no TCP port, so a browser
cannot reach it. Start a real Kestrel host alongside it:

```csharp
public class KestrelFactory<TProgram> : WebApplicationFactory<TProgram> where TProgram : class
{
    private IHost? _kestrel;
    public string ServerAddress => ClientOptions.BaseAddress.ToString().TrimEnd('/');

    protected override IHost CreateHost(IHostBuilder builder)
    {
        var testHost = builder.Build();                       // the in-memory host the base class expects

        builder.ConfigureWebHost(b => b.UseKestrel(o => o.Listen(IPAddress.Loopback, 0)));
        _kestrel = builder.Build();                           // a second, real host on a free port
        _kestrel.Start();

        var addresses = _kestrel.Services.GetRequiredService<IServer>()
                                .Features.Get<IServerAddressesFeature>()!;
        ClientOptions.BaseAddress = addresses.Addresses.Select(a => new Uri(a)).Last();

        testHost.Start();
        return testHost;
    }

    protected override void Dispose(bool disposing)
    {
        _kestrel?.Dispose();
        base.Dispose(disposing);
    }
}
```

Point `ContextOptions().BaseURL` at `factory.ServerAddress`. Requires
`Microsoft.AspNetCore.Mvc.Testing` and `<Project Sdk="Microsoft.NET.Sdk.Web">`-style access to
the app's `Program` class (add `public partial class Program { }` if it is top-level statements).

The simpler alternative — and the right default when the app has external dependencies — is to
launch the app as a process with `scripts/with-server.ps1` and point tests at that URL.

## Authentication reuse

Logging in through the UI for every test is the main source of slow suites. Do it once, save
the storage state, and load it per context:

```csharp
// one-time setup
await context.StorageStateAsync(new() { Path = "auth/user.json" });

// per test
public override BrowserNewContextOptions ContextOptions() => new() { StorageStatePath = "auth/user.json" };
```

Keep `auth/*.json` out of git — it holds live session cookies.

## CI (GitHub Actions)

```yaml
- uses: actions/setup-dotnet@v4
  with: { dotnet-version: '10.0.x' }
- run: dotnet build --configuration Release
- run: pwsh tests/UiTests/bin/Release/net10.0/playwright.ps1 install --with-deps chromium

# VSTest projects:
- run: dotnet test --configuration Release --logger "trx;LogFileName=ui.trx"
# MTP projects (TUnit, or any runner with -Mtp) - no global.json needed for this form:
- run: dotnet run --project tests/UiTests --configuration Release --no-build -- --report-trx

- uses: actions/upload-artifact@v4
  if: failure()
  with:
    name: playwright-traces
    path: tests/UiTests/bin/Release/net10.0/traces/
```

The build must come before the browser install — `playwright.ps1` is generated into the output
directory, and the path must match the configuration and TFM actually built. `--report-trx` needs
the `Microsoft.Testing.Extensions.TrxReport` package; MTP extensions are auto-registered once
referenced.

## Windows: MSB3021 on build

`Unable to copy file ... exceeds the OS max path limit` means the project's path plus Playwright's
`.playwright` asset tree crosses 260 characters. Move the test project higher up the tree, or
enable `LongPathsEnabled` under `HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem` (admin +
reboot). Nothing about the test code is wrong.

## Flakiness checklist

1. Replace every `WaitForTimeoutAsync` with a web-first assertion or `Locator.WaitForAsync`.
2. Never assert on a locator that matches several elements — add `.First` deliberately or make
   the locator specific; a silent match count change is a false pass.
3. `NetworkIdle` is unreliable with SignalR/Blazor Server/polling — wait for elements instead.
4. Test data must be unique per test (timestamp/GUID suffixes) or parallel runs collide.
5. Raise `ExpectTimeout` on CI rather than per-call — slow CI hardware is not a code problem.
