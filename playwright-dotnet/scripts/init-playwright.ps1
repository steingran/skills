<#
.SYNOPSIS
    Scaffold a Playwright test project (TUnit, NUnit, MSTest, or xUnit), build it, and install browsers.

.DESCRIPTION
    Creates the test project, adds the Playwright integration package for the chosen runner,
    optionally switches the project to Microsoft.Testing.Platform (MTP), builds, locates the
    generated playwright.ps1 driver and installs the browser binaries, then writes a sample
    test that navigates to -BaseUrl and asserts the page loaded.

    Safe to re-run against an existing project directory: the project is only created if
    missing, and the sample test is only written if it does not already exist.

.PARAMETER Path
    Directory for the test project. Default: ./tests/UiTests

.PARAMETER Framework
    TUnit    - MTP-native, source-generated, async-first. Uses TUnit.Playwright. Always MTP.
    NUnit    - default. Playwright's most established .NET integration (Microsoft.Playwright.NUnit).
    MSTest   - Microsoft.Playwright.MSTest.
    xUnit    - xUnit v3 + Microsoft.Playwright.Xunit.v3.

.PARAMETER Mtp
    Switch the project to Microsoft.Testing.Platform instead of VSTest, and write a global.json
    selecting the MTP runner for 'dotnet test'. Implied (and unavoidable) for TUnit.

.PARAMETER GlobalJsonDir
    Where to write/patch global.json when -Mtp is used. Default: current directory (repo root).
    global.json is resolved from the working directory upward, NOT from the project path.

.PARAMETER BaseUrl
    URL the sample test navigates to. Default: http://localhost:5000

.PARAMETER Browser
    Browser build to install: chromium (default), firefox, webkit, or all.

.EXAMPLE
    pwsh init-playwright.ps1 -Path tests/UiTests -BaseUrl http://localhost:5000

.EXAMPLE
    pwsh init-playwright.ps1 -Framework TUnit -Path tests/UiTests

.EXAMPLE
    pwsh init-playwright.ps1 -Framework NUnit -Mtp -GlobalJsonDir .
#>


[CmdletBinding()]
param(
    [string]$Path = 'tests/UiTests',
    [ValidateSet('TUnit', 'NUnit', 'MSTest', 'xUnit')][string]$Framework = 'NUnit',
    [switch]$Mtp,
    [string]$GlobalJsonDir = '.',
    [string]$BaseUrl = 'http://localhost:5000',
    [ValidateSet('chromium', 'firefox', 'webkit', 'all')][string]$Browser = 'chromium'
)

$ErrorActionPreference = 'Stop'

# TUnit only runs on MTP - there is no VSTest adapter for it.
$useMtp = $Mtp -or $Framework -eq 'TUnit'
if ($Framework -eq 'TUnit' -and -not $Mtp) { Write-Host "TUnit is MTP-only; enabling MTP." }

$projName = Split-Path $Path -Leaf
$ns = $projName -replace '[^A-Za-z0-9_.]', ''

function Add-CsprojProperty([string]$csproj, [hashtable]$props) {
    $xml = Get-Content $csproj -Raw
    foreach ($k in $props.Keys) {
        if ($xml -match "<$k>") {
            $xml = $xml -replace "<$k>.*?</$k>", "<$k>$($props[$k])</$k>"
        } else {
            $xml = $xml -replace '(<PropertyGroup>)', "`$1`n    <$k>$($props[$k])</$k>"
        }
    }
    Set-Content $csproj -Value $xml -Encoding utf8
}

# ---------------------------------------------------------------- create project

if (Test-Path (Join-Path $Path '*.csproj')) {
    Write-Host "Using existing project in $Path"
} elseif ($Framework -eq 'TUnit') {
    # No SDK template for TUnit; the csproj is small enough to write directly.
    Write-Host "Creating TUnit test project in $Path"
    New-Item -ItemType Directory -Force $Path | Out-Null
    @"
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <OutputType>Exe</OutputType>
    <LangVersion>latest</LangVersion>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    <IsPackable>false</IsPackable>
    <IsTestProject>true</IsTestProject>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="TUnit" Version="*" />
    <PackageReference Include="TUnit.Playwright" Version="*" />
  </ItemGroup>

</Project>
"@ | Set-Content (Join-Path $Path "$projName.csproj") -Encoding utf8
} else {
    $template = switch ($Framework) { 'NUnit' { 'nunit' } 'MSTest' { 'mstest' } 'xUnit' { 'xunit3' } }
    Write-Host "Creating $Framework test project in $Path"
    dotnet new $template -o $Path
    if ($LASTEXITCODE -ne 0) { throw "dotnet new $template failed" }
}

$csproj = (Get-ChildItem -Path $Path -Filter *.csproj | Select-Object -First 1).FullName

# ---------------------------------------------------------------- packages

if ($Framework -ne 'TUnit') {
    $package = switch ($Framework) {
        'NUnit'  { 'Microsoft.Playwright.NUnit' }
        'MSTest' { 'Microsoft.Playwright.MSTest' }
        'xUnit'  { 'Microsoft.Playwright.Xunit.v3' }
    }
    Write-Host "Adding $package"
    dotnet add $csproj package $package
    if ($LASTEXITCODE -ne 0) { throw "dotnet add package $package failed" }
}

# ---------------------------------------------------------------- MTP wiring

if ($useMtp) {
    $props = @{ OutputType = 'Exe' }
    switch ($Framework) {
        'NUnit'  { $props['EnableNUnitRunner'] = 'true' }               # needs NUnit3TestAdapter >= 5
        'MSTest' { $props['EnableMSTestRunner'] = 'true' }
        'xUnit'  { $props['UseMicrosoftTestingPlatformRunner'] = 'true' }
        'TUnit'  { }                                                    # MTP is the only mode
    }
    $props['TestingPlatformShowTestsFailure'] = 'true'
    Add-CsprojProperty $csproj $props

    if ($Framework -eq 'NUnit') {
        # The MTP runner lives in NUnit3TestAdapter 5+; templates may pin an older one.
        dotnet add $csproj package NUnit3TestAdapter | Out-Null
    }

    $gj = Join-Path $GlobalJsonDir 'global.json'
    if (Test-Path $gj) {
        $json = Get-Content $gj -Raw | ConvertFrom-Json
        if (-not $json.test) { $json | Add-Member -NotePropertyName test -NotePropertyValue ([pscustomobject]@{}) }
        $json.test | Add-Member -NotePropertyName runner -NotePropertyValue 'Microsoft.Testing.Platform' -Force
        $json | ConvertTo-Json -Depth 10 | Set-Content $gj -Encoding utf8
        Write-Host "Patched $gj with the MTP runner"
    } else {
        '{
  "test": {
    "runner": "Microsoft.Testing.Platform"
  }
}' | Set-Content $gj -Encoding utf8
        Write-Host "Wrote $gj (MTP runner for 'dotnet test')"
    }
    Write-Host "  NOTE: every test project under $((Resolve-Path $GlobalJsonDir).Path) must now be MTP-based."
}

# ---------------------------------------------------------------- sample test

$sample = Join-Path $Path 'HomePageTests.cs'
if (Test-Path $sample) {
    Write-Host "Sample test already exists, leaving it alone: $sample"
} else {
    $body = switch ($Framework) {
        'TUnit' {
@"
using Microsoft.Playwright;
using TUnit.Core;
using TUnit.Playwright;

namespace $ns;

// PageTest gives each test its own Playwright, Browser, Context, and Page.
public class HomePageTests : PageTest
{
    private const string BaseUrl = "$BaseUrl";

    // NOTE: TUnit's ContextOptions takes the TestContext - unlike the NUnit/MSTest
    // integrations, where the override is parameterless.
    public override BrowserNewContextOptions ContextOptions(TestContext testContext) => new()
    {
        BaseURL = BaseUrl,
        IgnoreHTTPSErrors = true,
        ViewportSize = new() { Width = 1920, Height = 1080 },
    };

    [Test]
    public async Task HomePage_Loads()
    {
        await Page.GotoAsync("/");

        // Playwright's retrying web-first assertions are inherited from PlaywrightTest;
        // TUnit's own Assert.That(...) is awaited and used for plain values.
        await Expect(Page.Locator("body")).ToBeVisibleAsync();
        await Assert.That(await Page.TitleAsync()).IsNotEmpty();
    }
}
"@
        }
        'NUnit' {
@"
using System.Text.RegularExpressions;
using Microsoft.Playwright;
using Microsoft.Playwright.NUnit;
using NUnit.Framework;

namespace $ns;

// PageTest gives each test a fresh browser, context, and Page, plus Expect().
[Parallelizable(ParallelScope.Self)]
[TestFixture]
public class HomePageTests : PageTest
{
    private const string BaseUrl = "$BaseUrl";

    // Per-test browser context options: HTTPS dev certs, viewport, base URL, locale.
    public override BrowserNewContextOptions ContextOptions() => new()
    {
        BaseURL = BaseUrl,
        IgnoreHTTPSErrors = true,
        ViewportSize = new() { Width = 1920, Height = 1080 },
    };

    [Test]
    public async Task HomePage_Loads()
    {
        await Page.GotoAsync("/");

        // Web-first assertion: retries until it passes or the timeout expires.
        await Expect(Page).ToHaveTitleAsync(new Regex(".+"));
        await Expect(Page.Locator("body")).ToBeVisibleAsync();
    }
}
"@
        }
        'MSTest' {
@"
using System.Text.RegularExpressions;
using Microsoft.Playwright;
using Microsoft.Playwright.MSTest;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace $ns;

[TestClass]
public class HomePageTests : PageTest
{
    private const string BaseUrl = "$BaseUrl";

    public override BrowserNewContextOptions ContextOptions() => new()
    {
        BaseURL = BaseUrl,
        IgnoreHTTPSErrors = true,
        ViewportSize = new() { Width = 1920, Height = 1080 },
    };

    [TestMethod]
    public async Task HomePage_Loads()
    {
        await Page.GotoAsync("/");
        await Expect(Page).ToHaveTitleAsync(new Regex(".+"));
        await Expect(Page.Locator("body")).ToBeVisibleAsync();
    }
}
"@
        }
        'xUnit' {
@"
using System.Text.RegularExpressions;
using Microsoft.Playwright;
using Microsoft.Playwright.Xunit.v3;   // note the .v3 in the namespace
using Xunit;

namespace $ns;

public class HomePageTests : PageTest
{
    private const string BaseUrl = "$BaseUrl";

    public override BrowserNewContextOptions ContextOptions() => new()
    {
        BaseURL = BaseUrl,
        IgnoreHTTPSErrors = true,
        ViewportSize = new() { Width = 1920, Height = 1080 },
    };

    [Fact]
    public async Task HomePage_Loads()
    {
        await Page.GotoAsync("/");
        await Expect(Page).ToHaveTitleAsync(new Regex(".+"));
        await Expect(Page.Locator("body")).ToBeVisibleAsync();
    }
}
"@
        }
    }
    Set-Content -Path $sample -Value $body -Encoding utf8
    Write-Host "Wrote sample test: $sample"
}

# ---------------------------------------------------------------- build + browsers

Write-Host "Building..."
dotnet build $csproj
if ($LASTEXITCODE -ne 0) { throw "dotnet build failed - fix the build before installing browsers" }

$driver = Get-ChildItem -Path (Join-Path $Path 'bin') -Filter 'playwright.ps1' -Recurse -ErrorAction SilentlyContinue |
          Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $driver) { throw "playwright.ps1 not found under $Path/bin - is the Playwright package referenced?" }

$installArgs = @('install')
if ($Browser -ne 'all') { $installArgs += $Browser }
Write-Host "Installing browsers: $($installArgs -join ' ')"
& $driver.FullName @installArgs
if ($LASTEXITCODE -ne 0) { throw "browser install failed" }

# ---------------------------------------------------------------- how to run

$runLines = if ($useMtp) {
@"
  dotnet run --project $csproj                 # runs the tests directly (no dotnet test needed)
  dotnet test --project $csproj                # needs global.json in the working directory
  dotnet run --project $csproj -- --filter "HomePage*"
"@
} else {
@"
  dotnet test $csproj
  dotnet test $csproj --filter "HomePage_Loads"
"@
}

Write-Host @"

Done ($Framework$(if ($useMtp) { ' on Microsoft.Testing.Platform' } else { ' on VSTest' })). Run the tests with:
$runLines

Headed/debug run:
  `$env:HEADED=1; <run command>
  `$env:PWDEBUG=1; <run command>   # opens Playwright Inspector

The app under test must be running at $BaseUrl - see scripts/with-server.ps1.
"@
