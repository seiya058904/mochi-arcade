param(
    [switch]$InitializeKey,
    [switch]$Build,
    [string]$SigningDirectory = (Join-Path $env:USERPROFILE '.mochi-arcade\signing'),
    [string]$Keytool = 'keytool'
)
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$signingRoot = [IO.Path]::GetFullPath($SigningDirectory)
if ($signingRoot.StartsWith($projectRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -or $signingRoot -eq $projectRoot) {
    throw 'The private signing directory must be outside the repository.'
}
$keyPath = Join-Path $signingRoot 'mochi-arcade-release.p12'
$passwordPath = Join-Path $signingRoot 'password.dpapi.xml'
$certificatePath = Join-Path $signingRoot 'certificate.pem'
if ($InitializeKey) {
    if ((Test-Path -LiteralPath $keyPath) -or (Test-Path -LiteralPath $passwordPath)) {
        throw 'Signing material already exists. Reuse it; never replace an update identity.'
    }
    New-Item -ItemType Directory -Path $signingRoot -Force | Out-Null
    if ((Get-Item -LiteralPath $signingRoot).Attributes -band [IO.FileAttributes]::ReparsePoint) {
        throw 'Refusing a signing directory that redirects to another path.'
    }
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent().User
    $acl = [Security.AccessControl.DirectorySecurity]::new()
    $acl.SetOwner($identity)
    $acl.SetAccessRuleProtection($true, $false)
    foreach ($sid in @($identity, [Security.Principal.SecurityIdentifier]::new('S-1-5-18'))) {
        $rule = [Security.AccessControl.FileSystemAccessRule]::new($sid, 'FullControl', 'ContainerInherit,ObjectInherit', 'None', 'Allow')
        $acl.AddAccessRule($rule)
    }
    Set-Acl -LiteralPath $signingRoot -AclObject $acl
    $randomBytes = [byte[]]::new(32)
    [Security.Cryptography.RandomNumberGenerator]::Fill($randomBytes)
    $generated = [Convert]::ToBase64String($randomBytes)
    $secure = ConvertTo-SecureString -String $generated -AsPlainText -Force
    $secure | Export-Clixml -LiteralPath $passwordPath
    [Array]::Clear($randomBytes, 0, $randomBytes.Length)
    $generated = $null
}
if (-not (Test-Path -LiteralPath $passwordPath)) { throw 'No protected password exists; initialize once explicitly.' }
if (-not (Get-Acl -LiteralPath $signingRoot).AreAccessRulesProtected) { throw 'Signing ACL inheritance must be disabled.' }
$secure = Import-Clixml -LiteralPath $passwordPath
$environmentNames = @('MOCHI_SIGN_PASSWORD', 'GODOT_ANDROID_KEYSTORE_RELEASE_PATH', 'GODOT_ANDROID_KEYSTORE_RELEASE_USER', 'GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD')
$previousEnvironment = @{}
foreach ($name in $environmentNames) { $previousEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, 'Process') }
try {
    $env:MOCHI_SIGN_PASSWORD = [PSCredential]::new('signing', $secure).GetNetworkCredential().Password
    if ($InitializeKey) {
        & $Keytool '-J-Duser.language=en' '-J-Duser.country=US' -genkeypair -keystore $keyPath -storetype PKCS12 -alias mochi-arcade -keyalg RSA -keysize 3072 -validity 10000 -storepass:env MOCHI_SIGN_PASSWORD -keypass:env MOCHI_SIGN_PASSWORD -dname 'CN=Mochi Arcade,OU=Release,O=Mochi Arcade'
        if ($LASTEXITCODE -ne 0) { throw 'Release key generation failed.' }
        & $Keytool '-J-Duser.language=en' '-J-Duser.country=US' -exportcert -rfc -keystore $keyPath -alias mochi-arcade -storepass:env MOCHI_SIGN_PASSWORD -file $certificatePath
        if ($LASTEXITCODE -ne 0) { throw 'Certificate export failed.' }
    }
    if (-not (Test-Path -LiteralPath $keyPath)) { throw 'The protected release key is missing.' }
    & $Keytool '-J-Duser.language=en' '-J-Duser.country=US' -list -v -keystore $keyPath -alias mochi-arcade -storepass:env MOCHI_SIGN_PASSWORD
    if ($LASTEXITCODE -ne 0) { throw 'Release key could not be reopened with its DPAPI-protected password.' }
    if ($Build) {
        $env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH = $keyPath
        $env:GODOT_ANDROID_KEYSTORE_RELEASE_USER = 'mochi-arcade'
        $env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD = $env:MOCHI_SIGN_PASSWORD
        New-Item -ItemType Directory -Path (Join-Path $projectRoot 'dist') -Force | Out-Null
        Push-Location $projectRoot
        try { & (Join-Path $PSScriptRoot 'godot.ps1') --headless --export-release Android dist/MochiArcade.apk }
        finally { Pop-Location }
        if ($LASTEXITCODE -ne 0) { throw 'Signed release export failed.' }
        Get-FileHash -LiteralPath (Join-Path $projectRoot 'dist\MochiArcade.apk') -Algorithm SHA256
    }
} finally {
    foreach ($name in $environmentNames) { [Environment]::SetEnvironmentVariable($name, $previousEnvironment[$name], 'Process') }
    $secure = $null
}
