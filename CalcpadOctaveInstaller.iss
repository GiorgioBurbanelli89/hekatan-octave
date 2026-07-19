; Inno Setup Script para Calcpad Octave
; Genera un instalador setup.exe
; Variante Octave: motor MATLAB/Octave nativo en C# (JIT + Intel MKL), modo Octave SIEMPRE activo.

#define MyAppName "Calcpad Octave"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Jorge Burbano"
#define MyAppURL "https://github.com/GiorgioBurbanelli89/Calcpad-Octave"
#define MyAppExeName "CalcpadOctave.exe"
#define MyAppPublishDir "C:\Users\j-b-j\Desktop\CalcpadOctave-Installer\CalcpadOctave"

[Setup]
AppId={{B7C8D9E0-2F3A-4B5C-6D7E-8F9A0B1C2D3E}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\Calcpad Octave
DefaultGroupName=Calcpad Octave
AllowNoIcons=yes
LicenseFile=LICENSE
OutputDir=.\Installer
OutputBaseFilename=CalcpadOctave-Setup-{#MyAppVersion}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64
PrivilegesRequired=admin
UninstallDisplayIcon={app}\{#MyAppExeName}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"
Name: "fileassoc_m"; Description: "Asociar archivos .m (Octave) con Calcpad Octave"; GroupDescription: "Asociaciones de archivo:"

[InstallDelete]
; Limpiar Examples viejos antes de copiar — evita .m huérfanos de versiones anteriores.
Type: filesandordirs; Name: "{app}\Examples"

[Files]
; Application files — self-contained .NET 10 publish
Source: "{#MyAppPublishDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs

; Examples — scripts .m (Octave) bundleados en {app}\Examples.
Source: "Examples-Lab\*"; DestDir: "{app}\Examples"; Flags: ignoreversion recursesubdirs skipifsourcedoesntexist

; Documentation
Source: "README.md"; DestDir: "{app}"; Flags: ignoreversion isreadme skipifsourcedoesntexist
Source: "LICENSE"; DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\Examples (bundleados)"; Filename: "{app}\Examples"
Name: "{group}\{cm:ProgramOnTheWeb,{#MyAppName}}"; Filename: "{#MyAppURL}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Registry]
; .m file association (Octave)
Root: HKA; Subkey: "Software\Classes\.m\OpenWithProgids"; ValueType: string; ValueName: "CalcpadOctave.MFile"; ValueData: ""; Flags: uninsdeletevalue; Tasks: fileassoc_m
Root: HKA; Subkey: "Software\Classes\CalcpadOctave.MFile"; ValueType: string; ValueName: ""; ValueData: "Calcpad Octave Document"; Flags: uninsdeletekey; Tasks: fileassoc_m
Root: HKA; Subkey: "Software\Classes\CalcpadOctave.MFile\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\{#MyAppExeName},0"; Tasks: fileassoc_m
Root: HKA; Subkey: "Software\Classes\CalcpadOctave.MFile\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#MyAppExeName}"" ""%1"""; Tasks: fileassoc_m

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Iniciar Calcpad Octave"; Flags: nowait postinstall skipifsilent
