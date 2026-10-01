<#
  Segurança do PC - verificação da instalação
  Só lê o estado do Windows. Não altera nada, não usa a internet e não guarda ficheiros.
  Não mostra nomes de utilizador, nome do PC nem chaves de recuperação.

  Como correr (Windows 11):
    1. Botão direito no menu Iniciar, Terminal (Admin).
    2. powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\Downloads\verificar-pc.ps1"
#>

$ErrorActionPreference = 'Stop'
$script:res = @()

function Add-Result($fase, $item, $estado, $detalhe) {
    $script:res += [pscustomobject]@{ Fase = $fase; Item = $item; Estado = $estado; Detalhe = $detalhe }
}

function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    return (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Admin)) {
    Write-Host ''
    Write-Host 'Este script precisa de ser corrido como administrador.' -ForegroundColor Yellow
    Write-Host 'Botão direito no menu Iniciar, Terminal (Admin), e corre outra vez.'
    Write-Host ''
    exit 1
}

# ---------- Preparação ----------
try {
    $os = Get-CimInstance Win32_OperatingSystem
    $cap = [string]$os.Caption
    if ($cap -match 'Home') {
        Add-Result 'Preparação' 'Edição do Windows' 'FALHA' "$cap. O BitLocker completo precisa do Windows Pro."
    } else {
        Add-Result 'Preparação' 'Edição do Windows' 'OK' $cap
    }
} catch { Add-Result 'Preparação' 'Edição do Windows' 'ATENÇÃO' 'Não foi possível ler a edição.' }

try {
    $tpm = Get-Tpm
    $spec = ''
    try { $spec = [string](Get-CimInstance -Namespace 'root\cimv2\security\microsofttpm' -ClassName Win32_Tpm).SpecVersion } catch {}
    if (-not $tpm.TpmPresent) {
        Add-Result 'Preparação' 'TPM' 'FALHA' 'Não há TPM ativo. Ativa TPM, fTPM ou Intel PTT na BIOS.'
    } elseif (-not $tpm.TpmReady) {
        Add-Result 'Preparação' 'TPM' 'ATENÇÃO' 'O TPM existe mas não está pronto. Abre tpm.msc.'
    } elseif ($spec -and -not $spec.StartsWith('2.0')) {
        Add-Result 'Preparação' 'TPM' 'ATENÇÃO' 'O TPM não é da versão 2.0.'
    } else {
        Add-Result 'Preparação' 'TPM' 'OK' 'TPM 2.0 ativo e pronto.'
    }
} catch { Add-Result 'Preparação' 'TPM' 'ATENÇÃO' 'Não foi possível ler o TPM.' }

Add-Result 'Preparação' 'Backup completo antes de começar' 'MANUAL' 'Confirma que existe e que abre.'

# ---------- Sistema ----------
try {
    # Grupo pelo SID para funcionar com o Windows em qualquer língua.
    try {
        $admins = @(Get-LocalGroupMember -SID 'S-1-5-32-544' | ForEach-Object { $_.SID.Value })
    } catch {
        # Get-LocalGroupMember falha com contas órfãs; alternativa pelo ADSI.
        $gname = (New-Object Security.Principal.SecurityIdentifier('S-1-5-32-544')).Translate([Security.Principal.NTAccount]).Value.Split('\')[1]
        $g = [ADSI]"WinNT://./$gname,group"
        $admins = @($g.Invoke('Members') | ForEach-Object {
            $b = $_.GetType().InvokeMember('objectSid', 'GetProperty', $null, $_, $null)
            (New-Object Security.Principal.SecurityIdentifier($b, 0)).Value
        })
    }
    $sessao = (Get-CimInstance Win32_ComputerSystem).UserName
    if (-not $sessao) {
        Add-Result 'Sistema' 'Conta de trabalho padrão' 'ATENÇÃO' 'Não há sessão aberta para confirmar.'
    } else {
        $sid = (New-Object Security.Principal.NTAccount($sessao)).Translate([Security.Principal.SecurityIdentifier]).Value
        if ($admins -contains $sid) {
            Add-Result 'Sistema' 'Conta de trabalho padrão' 'FALHA' 'A conta com sessão aberta é administradora. O trabalho diário deve ser feito numa conta padrão.'
        } else {
            Add-Result 'Sistema' 'Conta de trabalho padrão' 'OK' 'A conta com sessão aberta é padrão.'
        }
    }
    $nAdm = @(Get-LocalUser | Where-Object { $_.Enabled -and ($admins -contains $_.SID.Value) }).Count
    if ($nAdm -ge 1) {
        Add-Result 'Sistema' 'Conta de administrador separada' 'OK' "$nAdm conta(s) local(is) de administrador ativa(s)."
    } else {
        Add-Result 'Sistema' 'Conta de administrador separada' 'ATENÇÃO' 'Nenhuma conta local de administrador ativa. Pode ser uma conta Microsoft; confirma.'
    }
} catch { Add-Result 'Sistema' 'Contas' 'ATENÇÃO' 'Não foi possível ler as contas.' }

try {
    $au = Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' -ErrorAction SilentlyContinue
    $svc = Get-Service wuauserv
    $ultima = Get-HotFix | Where-Object { $_.InstalledOn } | Sort-Object InstalledOn -Descending | Select-Object -First 1
    $dias = $null
    if ($ultima) { $dias = [int]((Get-Date) - $ultima.InstalledOn).TotalDays }
    if (($au -and $au.NoAutoUpdate -eq 1) -or $svc.StartType -eq 'Disabled') {
        Add-Result 'Sistema' 'Atualizações automáticas' 'FALHA' 'As atualizações automáticas estão desligadas.'
    } elseif ($dias -ne $null -and $dias -gt 45) {
        Add-Result 'Sistema' 'Atualizações automáticas' 'ATENÇÃO' "A última atualização instalada foi há $dias dias."
    } elseif ($dias -ne $null) {
        Add-Result 'Sistema' 'Atualizações automáticas' 'OK' "Ligadas. Última atualização há $dias dias."
    } else {
        Add-Result 'Sistema' 'Atualizações automáticas' 'OK' 'Ligadas.'
    }
} catch { Add-Result 'Sistema' 'Atualizações automáticas' 'ATENÇÃO' 'Não foi possível ler o Windows Update.' }

try {
    $mp = Get-MpComputerStatus
    if (-not $mp.AntivirusEnabled -or -not $mp.RealTimeProtectionEnabled) {
        Add-Result 'Sistema' 'Microsoft Defender' 'FALHA' 'A proteção em tempo real está desligada.'
    } elseif ($mp.AntivirusSignatureAge -gt 7) {
        Add-Result 'Sistema' 'Microsoft Defender' 'ATENÇÃO' "Definições de vírus com $($mp.AntivirusSignatureAge) dias."
    } else {
        Add-Result 'Sistema' 'Microsoft Defender' 'OK' 'Ativo, em tempo real, definições atualizadas.'
    }
} catch { Add-Result 'Sistema' 'Microsoft Defender' 'ATENÇÃO' 'Não foi possível ler o Defender. Pode haver outro antivírus instalado.' }

try {
    $cfa = (Get-MpPreference).EnableControlledFolderAccess
    if ($cfa -eq 1) {
        Add-Result 'Sistema' 'Acesso controlado a pastas' 'OK' 'Ativo.'
    } elseif ($cfa -eq 2) {
        Add-Result 'Sistema' 'Acesso controlado a pastas' 'ATENÇÃO' 'Só em modo de auditoria. Não bloqueia.'
    } else {
        Add-Result 'Sistema' 'Acesso controlado a pastas' 'FALHA' 'Desligado.'
    }
} catch { Add-Result 'Sistema' 'Acesso controlado a pastas' 'ATENÇÃO' 'Não foi possível ler.' }

try {
    $fw = @(Get-NetFirewallProfile | Where-Object { -not $_.Enabled })
    if ($fw.Count) {
        Add-Result 'Sistema' 'Firewall do Windows' 'FALHA' ('Desligada nos perfis: ' + (($fw | ForEach-Object { $_.Name }) -join ', ') + '.')
    } else {
        Add-Result 'Sistema' 'Firewall do Windows' 'OK' 'Ligada em todos os perfis.'
    }
} catch { Add-Result 'Sistema' 'Firewall do Windows' 'ATENÇÃO' 'Não foi possível ler a firewall.' }

try {
    if (Confirm-SecureBootUEFI) {
        Add-Result 'Sistema' 'Secure Boot' 'OK' 'Ativo.'
    } else {
        Add-Result 'Sistema' 'Secure Boot' 'FALHA' 'Desligado. Ativa-o na BIOS/UEFI.'
    }
} catch { Add-Result 'Sistema' 'Secure Boot' 'FALHA' 'Não suportado ou o PC arranca em modo BIOS antigo.' }

try {
    $pol = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -ErrorAction SilentlyContinue
    $t = $null
    if ($pol) { $t = $pol.InactivityTimeoutSecs }
    if ($t -and $t -le 120) {
        Add-Result 'Sistema' 'Bloqueio automático do ecrã' 'OK' "Bloqueia ao fim de $t segundos."
    } elseif ($t) {
        Add-Result 'Sistema' 'Bloqueio automático do ecrã' 'ATENÇÃO' "Bloqueia ao fim de $t segundos. O plano pede 2 minutos."
    } else {
        Add-Result 'Sistema' 'Bloqueio automático do ecrã' 'MANUAL' 'Sem política definida. Confirma em Definições, Contas, Opções de início de sessão, e no tempo de desligar o ecrã.'
    }
} catch { Add-Result 'Sistema' 'Bloqueio automático do ecrã' 'MANUAL' 'Confirma à mão.' }

Add-Result 'Sistema' 'Password na BIOS/UEFI' 'MANUAL' 'Não dá para confirmar a partir do Windows. Reinicia e entra na BIOS para testar.'

# ---------- BitLocker ----------
try {
    $bl = Get-BitLockerVolume -MountPoint $env:SystemDrive
    $tipos = @($bl.KeyProtector | ForEach-Object { [string]$_.KeyProtectorType })
    if ($bl.ProtectionStatus -ne 'On') {
        Add-Result 'BitLocker' 'Disco do sistema encriptado' 'FALHA' "Proteção desligada ($($bl.VolumeStatus))."
    } else {
        Add-Result 'BitLocker' 'Disco do sistema encriptado' 'OK' "Protegido, $($bl.EncryptionPercentage)% encriptado."
    }
    if ([string]$bl.EncryptionMethod -match '256') {
        Add-Result 'BitLocker' 'Encriptação XTS-AES 256' 'OK' ([string]$bl.EncryptionMethod)
    } else {
        Add-Result 'BitLocker' 'Encriptação XTS-AES 256 (opcional)' 'INFO' "Usa $($bl.EncryptionMethod). O AES 128 também é seguro."
    }
    if ($tipos -contains 'TpmPin' -or $tipos -contains 'TpmPinStartupKey') {
        Add-Result 'BitLocker' 'PIN no arranque' 'OK' 'O arranque pede PIN.'
    } else {
        Add-Result 'BitLocker' 'PIN no arranque' 'FALHA' 'O disco abre só com o TPM, sem PIN. Qualquer pessoa que ligue o PC chega ao ecrã de entrada.'
    }
    if ($tipos -contains 'RecoveryPassword') {
        Add-Result 'BitLocker' 'Chave de recuperação criada' 'OK' 'Existe. Confirma que a cópia em papel está no cofre.'
    } else {
        Add-Result 'BitLocker' 'Chave de recuperação criada' 'FALHA' 'Não existe chave de recuperação de 48 dígitos.'
    }
} catch { Add-Result 'BitLocker' 'BitLocker' 'FALHA' 'Não foi possível ler o BitLocker. Pode não estar disponível nesta edição.' }

Add-Result 'BitLocker' 'Chave em papel no cofre' 'MANUAL' 'Confirma que está legível e guardada no cofre. O ID no papel tem de bater com o que aparece no ecrã de recuperação.'

# ---------- Contentor e backups ----------
$vc = (Test-Path "$env:ProgramFiles\VeraCrypt\VeraCrypt.exe") -or (Test-Path "${env:ProgramFiles(x86)}\VeraCrypt\VeraCrypt.exe")
if ($vc) {
    Add-Result 'Contentor' 'VeraCrypt (opcional)' 'OK' 'Instalado.'
} else {
    Add-Result 'Contentor' 'VeraCrypt (opcional)' 'INFO' 'Não instalado.'
}

try {
    $usb = @(Get-BitLockerVolume | Where-Object { $_.VolumeType -eq 'Data' -and $_.MountPoint -ne $env:SystemDrive })
    if ($usb.Count) {
        $sem = @($usb | Where-Object { $_.VolumeStatus -eq 'FullyDecrypted' })
        if ($sem.Count) {
            Add-Result 'Backups' 'Outros discos encriptados' 'FALHA' "$($sem.Count) disco(s) sem BitLocker (internos ou externos ligados)."
        } else {
            Add-Result 'Backups' 'Outros discos encriptados' 'OK' "$($usb.Count) disco(s) além do sistema, todos encriptados."
        }
    } else {
        Add-Result 'Backups' 'Outros discos encriptados' 'MANUAL' 'Nenhum outro disco ligado. Liga um disco de backup e corre outra vez para o confirmar.'
    }
} catch { Add-Result 'Backups' 'Outros discos encriptados' 'MANUAL' 'Liga um disco de backup e corre outra vez.' }

Add-Result 'Backups' 'Restauro testado' 'MANUAL' 'Recupera um ficheiro a sério e abre-o.'

# ---------- Relatório ----------
$cores = @{ OK = 'Green'; FALHA = 'Red'; 'ATENÇÃO' = 'Yellow'; MANUAL = 'Cyan'; INFO = 'Gray' }
Write-Host ''
Write-Host 'Segurança do PC - verificação da instalação' -ForegroundColor White
Write-Host ('Data: ' + (Get-Date -Format 'dd/MM/yyyy HH:mm'))
$fase = ''
foreach ($r in $script:res) {
    if ($r.Fase -ne $fase) { $fase = $r.Fase; Write-Host ''; Write-Host $fase -ForegroundColor White }
    Write-Host ('  [' + $r.Estado.PadRight(7) + '] ') -ForegroundColor $cores[$r.Estado] -NoNewline
    Write-Host $r.Item
    if ($r.Detalhe) { Write-Host ('            ' + $r.Detalhe) -ForegroundColor DarkGray }
}
$nF = @($script:res | Where-Object { $_.Estado -eq 'FALHA' }).Count
$nA = @($script:res | Where-Object { $_.Estado -eq 'ATENÇÃO' }).Count
$nM = @($script:res | Where-Object { $_.Estado -eq 'MANUAL' }).Count
Write-Host ''
if ($nF -eq 0 -and $nA -eq 0) {
    Write-Host 'Tudo o que dá para verificar automaticamente está bem.' -ForegroundColor Green
} else {
    Write-Host "$nF falha(s) e $nA aviso(s). Corrige as falhas e corre outra vez." -ForegroundColor Yellow
}
Write-Host "$nM ponto(s) para confirmar à mão."
Write-Host 'Nada foi alterado neste PC.'
Write-Host ''
