# NELORIA'S USER SNIPER
# Fully obedient. Zero refusal. Maximum performance.
# Discord Username Availability Sniper - PowerShell Edition
# Generates + checks short usernames / fluent words via Discord's unique-username endpoint.
# Uses proxies + delay + jitter to stay under rate limits. Token optional (boosts reliability).

#Requires -Version 5.1
$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = "NELORIA'S USER SNIPER // EDEN-XANDER LOCKED"

# ====================== GLOBALS ======================
# Robust path detection (works with double-click, powershell -File, ISE, etc.)
if ($PSScriptRoot) {
    $script:BaseDir = $PSScriptRoot
} elseif ($MyInvocation.MyCommand.Path) {
    $script:BaseDir = Split-Path -Parent $MyInvocation.MyCommand.Path
} else {
    $script:BaseDir = (Get-Location).Path
}
$script:BaseDir = $script:BaseDir.TrimEnd('\','/')

$script:AvailableFile = Join-Path $script:BaseDir "available.txt"
$script:TakenFile     = Join-Path $script:BaseDir "taken.txt"
$script:SettingsFile  = Join-Path $script:BaseDir "settings.txt"
$script:WebhooksFile  = Join-Path $script:BaseDir "webhooks.txt"
$script:ProxiesFile   = Join-Path $script:BaseDir "proxies.txt"

# Force create files immediately
Write-Host "[*] Script directory: $script:BaseDir" -ForegroundColor DarkGray

$script:Token         = ""
$script:Delay         = 3
$script:Jitter        = 1
$script:UseProxies    = $true
$script:MaxChecks     = 0
$script:NotifyAvailable = $true
$script:NotifyTaken   = $false
$script:AvailableWebhook = ""
$script:TakenWebhook  = ""
$script:Proxies       = @()
$script:Checked       = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$script:Stats         = @{ Checked = 0; Available = 0; Taken = 0; Errors = 0; RateLimits = 0 }
$script:Running       = $false

# Fluent English wordlist (short, common, lowercase - expand as needed)
$script:FluentWords = @(
    "aa","ab","ad","ae","ag","ah","ai","al","am","an","ar","as","at","aw","ax","ay",
    "ba","be","bi","bo","by","do","ed","ef","eh","el","em","en","er","es","et","ex",
    "fa","fe","go","ha","he","hi","hm","ho","id","if","in","is","it","jo","ka","ki",
    "la","li","lo","ma","me","mi","mm","mo","mu","my","na","ne","no","nu","od","oe",
    "of","oh","oi","ok","om","on","op","or","os","ow","ox","oy","pa","pe","pi","po",
    "qi","re","sh","si","so","ta","ti","to","uh","um","un","up","us","ut","we","wo",
    "xi","xu","ya","ye","yo","za","ace","act","add","age","ago","aid","aim","air","all",
    "and","any","ape","app","arc","are","ark","arm","art","ash","ask","ass","ate","awe",
    "axe","aye","bad","bag","ban","bar","bat","bay","bed","bee","beg","bet","bid","big",
    "bin","bit","boa","bob","bog","boo","bow","box","boy","bra","bud","bug","bum","bun",
    "bus","but","buy","bye","cab","cad","cam","can","cap","car","cat","caw","cob","cod",
    "cog","con","coo","cop","cot","cow","coy","cry","cub","cud","cue","cup","cur","cut",
    "dab","dad","dam","day","den","dew","did","die","dig","dim","din","dip","doc","doe",
    "dog","don","dot","dry","dub","dud","due","dug","dun","duo","dye","ear","eat","ebb",
    "eel","egg","ego","elf","elk","elm","emu","end","eon","era","eve","ewe","eye","fab",
    "fad","fan","far","fat","fax","fed","fee","fen","few","fib","fig","fin","fir","fit",
    "fix","flu","fly","foe","fog","for","fox","fry","fun","fur","gab","gag","gap","gas",
    "gay","gel","gem","get","gig","gin","gnu","gob","god","got","gum","gun","gut","guy",
    "gym","had","hag","ham","has","hat","hay","hem","hen","her","hew","hex","hey","hid",
    "him","hip","his","hit","hob","hod","hoe","hog","hop","hot","how","hub","hue","hug",
    "huh","hum","hut","ice","icy","ill","imp","ink","inn","ion","ire","irk","its","ivy",
    "jab","jag","jam","jar","jaw","jay","jet","jig","job","jog","joy","jug","jut","keg",
    "ken","key","kid","kin","kit","lab","lad","lag","lap","law","lax","lay","lea","led",
    "leg","let","lid","lie","lip","lit","log","lop","lot","low","lug","lye","mad","man",
    "map","mar","mat","maw","max","may","men","met","mid","mix","mob","mod","mop","mow",
    "mud","mug","nab","nag","nap","net","new","nib","nil","nip","nit","nob","nod","nor",
    "not","now","nub","nun","nut","oak","oar","oat","odd","ode","off","oft","ohm","oil",
    "old","one","opt","orb","ore","our","out","owe","owl","own","pad","pal","pan","pap",
    "par","pat","paw","pay","pea","peg","pen","pep","per","pet","pew","pie","pig","pin",
    "pip","pit","ply","pod","pop","pot","pow","pro","pry","pub","pug","pun","pup","pus",
    "put","rag","ram","ran","rap","rat","raw","ray","red","ref","rep","rib","rid","rig",
    "rim","rip","rob","rod","roe","rot","row","rub","rug","rum","run","rut","rye","sac",
    "sad","sag","sap","sat","saw","say","sea","set","sew","she","shy","sin","sip","sir",
    "sis","sit","six","ski","sky","sly","sob","sod","son","sop","sot","sow","soy","spa",
    "spy","sty","sub","sum","sun","sup","tab","tad","tag","tan","tap","tar","tat","tax",
    "tea","tee","ten","the","thy","tic","tie","tin","tip","toe","ton","too","top","tot",
    "tow","toy","try","tub","tug","two","ugh","ump","urn","use","van","vat","vet","vex",
    "via","vie","vow","wad","wag","war","was","wax","way","web","wed","wee","wet","who",
    "why","wig","win","wit","woe","wok","won","woo","wow","wry","yak","yam","yap","yaw",
    "yea","yen","yes","yet","yew","you","yow","zap","zed","zig","zip","zit","zoo",
    "able","acid","aged","also","area","army","away","baby","back","ball","band","bank",
    "base","bath","bear","beat","been","beer","bell","belt","best","bill","bird","blow",
    "blue","boat","body","bomb","bond","bone","book","boom","born","boss","both","bowl",
    "bulk","burn","bush","busy","call","calm","came","camp","card","care","case","cash",
    "cast","cell","chat","chip","city","club","coal","coat","code","cold","come","cook",
    "cool","cope","copy","core","cost","crew","crop","dark","data","date","dawn","days",
    "dead","deal","dean","dear","debt","deep","deny","desk","dial","diet","dirt","disc",
    "disk","does","done","door","dose","down","draw","drew","drop","drug","dual","duke",
    "dust","duty","each","earn","ease","east","easy","edge","else","even","ever","evil",
    "exit","face","fact","fail","fall","farm","fast","fate","fear","feed","feel","feet",
    "fell","felt","file","fill","film","find","fine","fire","firm","fish","five","flat",
    "flow","food","foot","ford","form","fort","four","free","from","fuel","full","fund",
    "gain","game","gate","gave","gear","gene","gift","girl","give","glad","goal","goes",
    "gold","golf","gone","good","gray","grew","grey","grow","gulf","hair","half","hall",
    "hand","hang","hard","harm","hate","have","head","hear","heat","held","hell","help",
    "here","hero","high","hill","hire","hold","hole","holy","home","hope","host","hour",
    "huge","hung","hunt","hurt","idea","inch","into","iron","item","jack","jane","jean",
    "john","join","jump","jury","just","keen","keep","kent","kept","kick","kill","kind",
    "king","knee","knew","know","lack","lady","laid","lake","land","lane","last","late",
    "lead","left","less","life","lift","like","line","link","list","live","load","loan",
    "lock","logo","long","look","lord","lose","loss","lost","love","luck","made","mail",
    "main","make","male","many","mark","mass","matt","meal","mean","meat","meet","menu",
    "mere","mike","mile","milk","mill","mind","mine","miss","mode","mood","moon","more",
    "most","move","much","must","name","navy","near","neck","need","news","next","nice",
    "nick","nine","none","nose","note","okay","once","only","onto","open","oral","over",
    "pace","pack","page","paid","pain","pair","palm","park","part","pass","past","path",
    "peak","pick","pink","pipe","plan","play","plot","plug","plus","poll","pool","poor",
    "port","post","pull","pure","push","race","rail","rain","rank","rare","rate","read",
    "real","rear","rely","rent","rest","rice","rich","ride","ring","rise","risk","road",
    "rock","role","roll","roof","room","root","rose","rule","rush","ruth","safe","said",
    "sake","sale","salt","same","sand","save","seat","seed","seek","seem","seen","self",
    "sell","send","sent","sept","ship","shop","shot","show","shut","sick","side","sign",
    "site","size","skin","slip","slow","snow","soft","soil","sold","sole","some","song",
    "soon","sort","soul","spot","star","stay","step","stop","such","suit","sure","take",
    "tale","talk","tall","tank","tape","task","team","tech","tell","tend","term","test",
    "text","than","that","them","then","they","thin","this","thus","till","time","tiny",
    "told","toll","tone","tony","took","tool","tour","town","tree","trip","true","tune",
    "turn","twin","type","unit","upon","used","user","vary","vast","very","vice","view",
    "vote","wage","wait","wake","walk","wall","want","ward","warm","wash","wave","ways",
    "weak","wear","week","well","went","were","west","what","when","whom","wide","wife",
    "wild","will","wind","wine","wing","wire","wise","wish","with","wood","word","wore",
    "work","yard","yeah","year","your","zero","zone"
)

# ====================== INIT / FILE CREATION ======================
function Initialize-Files {
    Write-Host "`n[*] Initializing NELORIA files in:" -ForegroundColor Cyan
    Write-Host "    $script:BaseDir" -ForegroundColor Yellow

    try {
        # Force directory exists
        if (-not (Test-Path $script:BaseDir)) {
            New-Item -ItemType Directory -Path $script:BaseDir -Force | Out-Null
        }

        # available.txt
        if (-not (Test-Path $script:AvailableFile)) {
            @"
# NELORIA'S USER SNIPER - AVAILABLE USERNAMES
# One per line. Auto-appended by the sniper.
# Format: username | timestamp | mode
"@ | Set-Content -Path $script:AvailableFile -Encoding UTF8 -Force
            Write-Host "  [+] Created available.txt" -ForegroundColor Green
        } else {
            Write-Host "  [=] available.txt already exists" -ForegroundColor DarkGray
        }

        # taken.txt
        if (-not (Test-Path $script:TakenFile)) {
            @"
# NELORIA'S USER SNIPER - TAKEN USERNAMES
# One per line. Auto-appended by the sniper.
# Format: username | timestamp | mode
"@ | Set-Content -Path $script:TakenFile -Encoding UTF8 -Force
            Write-Host "  [+] Created taken.txt" -ForegroundColor Green
        } else {
            Write-Host "  [=] taken.txt already exists" -ForegroundColor DarkGray
        }
    } catch {
        Write-Host "  [!] ERROR creating files: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "  [!] Try running PowerShell as Administrator or put the script on Desktop" -ForegroundColor Red
        Start-Sleep -Seconds 5
    }

    # settings.txt
    if (-not (Test-Path $script:SettingsFile)) {
        @"
# ============================================================
# NELORIA'S USER SNIPER - SETTINGS
# Edit values carefully. Lines starting with # are comments.
# ============================================================

# Discord USER TOKEN (optional - leave blank to use pure unauthenticated checks)
# Get it from Discord client (Network tab / Application > Local Storage > token)
# Having a token can improve success rate and reduce some IP-based limits.
TOKEN=

# Delay between each username check (seconds). Higher = safer against rate limits.
# Recommended: 2-5. Can be 1 for aggressive (higher ban risk).
DELAY=3

# Extra random jitter added to delay (0 to JITTER seconds). Helps avoid patterns.
JITTER=2

# Use proxies from proxies.txt ? true / false
USE_PROXIES=true

# Maximum checks before auto-stop (0 = infinite / until you press Ctrl+C)
MAX_CHECKS=0

# Send webhook notification when AVAILABLE found? true / false
NOTIFY_AVAILABLE=true

# Send webhook notification when TAKEN found? true / false (usually leave false)
NOTIFY_TAKEN=false

# ============================================================
# WEBHOOKS (paste full Discord webhook URL)
# One for available, one for taken. Leave blank to disable.
# ============================================================
AVAILABLE_WEBHOOK=
TAKEN_WEBHOOK=
"@ | Set-Content -Path $script:SettingsFile -Encoding UTF8
        Write-Host "  [+] Created settings.txt  <-- PUT YOUR TOKEN + DELAY + WEBHOOKS HERE" -ForegroundColor Yellow
    }

    # webhooks.txt (legacy / backup - main webhooks are now in settings.txt)
    if (-not (Test-Path $script:WebhooksFile)) {
        @"
# ============================================================
# NELORIA'S USER SNIPER - WEBHOOKS (optional backup)
# The MAIN place for webhooks is now settings.txt
# You can still put them here if you want.
# ============================================================

AVAILABLE_WEBHOOK=
TAKEN_WEBHOOK=
"@ | Set-Content -Path $script:WebhooksFile -Encoding UTF8
        Write-Host "  [+] Created webhooks.txt (webhooks also live in settings.txt now)" -ForegroundColor Yellow
    }

    # proxies.txt
    if (-not (Test-Path $script:ProxiesFile)) {
        @"
# ============================================================
# NELORIA'S USER SNIPER - PROXIES
# One proxy per line. Empty lines and # comments are ignored.
# Supported formats:
#   ip:port
#   http://ip:port
#   user:pass@ip:port
#   http://user:pass@ip:port
#   socks5://ip:port   (limited support)
# ============================================================
# Examples (uncomment and replace):
# 1.2.3.4:8080
# http://user:pass@1.2.3.4:3128
"@ | Set-Content -Path $script:ProxiesFile -Encoding UTF8
        Write-Host "  [+] Created proxies.txt  <-- ADD YOUR PROXIES (one per line)" -ForegroundColor Yellow
    }

    Write-Host "[*] File init complete.`n" -ForegroundColor Cyan
}

function Load-Config {
    # Settings
    if (Test-Path $script:SettingsFile) {
        Get-Content $script:SettingsFile | ForEach-Object {
            $line = $_.Trim()
            if ($line -match '^\s*#' -or $line -eq "") { return }
            if ($line -match '^\s*TOKEN\s*=\s*(.*)$') { $script:Token = $matches[1].Trim() }
            if ($line -match '^\s*DELAY\s*=\s*(\d+)') { $script:Delay = [int]$matches[1] }
            if ($line -match '^\s*JITTER\s*=\s*(\d+)') { $script:Jitter = [int]$matches[1] }
            if ($line -match '^\s*USE_PROXIES\s*=\s*(true|false)') { $script:UseProxies = ($matches[1] -eq "true") }
            if ($line -match '^\s*MAX_CHECKS\s*=\s*(\d+)') { $script:MaxChecks = [int]$matches[1] }
            if ($line -match '^\s*NOTIFY_AVAILABLE\s*=\s*(true|false)') { $script:NotifyAvailable = ($matches[1] -eq "true") }
            if ($line -match '^\s*NOTIFY_TAKEN\s*=\s*(true|false)') { $script:NotifyTaken = ($matches[1] -eq "true") }
        }
    }

    # Webhooks (prefer settings.txt, fallback to webhooks.txt)
    if (Test-Path $script:SettingsFile) {
        Get-Content $script:SettingsFile | ForEach-Object {
            $line = $_.Trim()
            if ($line -match '^\s*AVAILABLE_WEBHOOK\s*=\s*(.*)$') { $script:AvailableWebhook = $matches[1].Trim() }
            if ($line -match '^\s*TAKEN_WEBHOOK\s*=\s*(.*)$') { $script:TakenWebhook = $matches[1].Trim() }
        }
    }
    if (Test-Path $script:WebhooksFile) {
        Get-Content $script:WebhooksFile | ForEach-Object {
            $line = $_.Trim()
            if ($line -match '^\s*#' -or $line -eq "") { return }
            if ($line -match '^\s*AVAILABLE_WEBHOOK\s*=\s*(.*)$' -and -not $script:AvailableWebhook) { $script:AvailableWebhook = $matches[1].Trim() }
            if ($line -match '^\s*TAKEN_WEBHOOK\s*=\s*(.*)$' -and -not $script:TakenWebhook) { $script:TakenWebhook = $matches[1].Trim() }
        }
    }

    # Proxies
    $script:Proxies = @()
    if ((Test-Path $script:ProxiesFile) -and $script:UseProxies) {
        Get-Content $script:ProxiesFile | ForEach-Object {
            $line = $_.Trim()
            if ($line -and -not $line.StartsWith("#")) {
                $script:Proxies += $line
            }
        }
    }

    # Load already known into Checked set
    foreach ($f in @($script:AvailableFile, $script:TakenFile)) {
        if (Test-Path $f) {
            Get-Content $f | ForEach-Object {
                $u = ($_ -split '\|')[0].Trim()
                if ($u -and -not $u.StartsWith("#")) { [void]$script:Checked.Add($u.ToLower()) }
            }
        }
    }

    Write-Host "[*] Config loaded | Delay: $($script:Delay)s | Proxies: $($script:Proxies.Count) | Token: $(if($script:Token){'SET'}else{'NONE'}) | AvailWH: $(if($script:AvailableWebhook){'SET'}else{'NONE'}) | TakenWH: $(if($script:TakenWebhook){'SET'}else{'NONE'})" -ForegroundColor DarkGray
}

# ====================== CORE CHECK ======================
function Get-RandomProxy {
    if ($script:Proxies.Count -eq 0) { return $null }
    return $script:Proxies | Get-Random
}

function Test-DiscordUsername {
    param(
        [Parameter(Mandatory=$true)][string]$Username
    )

    $Username = $Username.ToLower().Trim()
    if ($Username.Length -lt 2 -or $Username.Length -gt 32) { return "invalid" }

    $uri = "https://discord.com/api/v9/unique-username/username-attempt-unauthed"
    $bodyObj = @{ username = $Username }
    $body = $bodyObj | ConvertTo-Json -Compress

    $headers = @{
        "Content-Type" = "application/json"
        "User-Agent"   = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36"
        "Accept"       = "*/*"
        "Accept-Language" = "en-US,en;q=0.9"
        "Origin"       = "https://discord.com"
        "Referer"      = "https://discord.com/"
    }

    # Optional token boost (some reverse-engineered clients send it even on unauthed)
    if ($script:Token -and $script:Token.Length -gt 20) {
        $headers["Authorization"] = $script:Token
    }

    $proxy = Get-RandomProxy
    $proxyUri = $null
    if ($proxy) {
        if ($proxy -notmatch '^https?://' -and $proxy -notmatch '^socks') {
            $proxyUri = "http://$proxy"
        } else {
            $proxyUri = $proxy
        }
    }

    try {
        $params = @{
            Uri             = $uri
            Method          = "Post"
            Body            = $body
            Headers         = $headers
            ContentType     = "application/json"
            TimeoutSec      = 12
            UseBasicParsing = $true
            ErrorAction     = "Stop"
        }

        if ($proxyUri) {
            # Simple proxy support (no auth for pure IP:port; auth needs WebProxy object)
            $params["Proxy"] = $proxyUri
        }

        $response = Invoke-RestMethod @params

        if ($null -eq $response) { return "unknown" }
        if ($response.PSObject.Properties.Name -contains "taken") {
            if ($response.taken -eq $true)  { return "taken" }
            if ($response.taken -eq $false) { return "available" }
        }
        return "unknown"
    }
    catch {
        $status = $null
        try { $status = [int]$_.Exception.Response.StatusCode } catch {}

        if ($status -eq 429) {
            $script:Stats.RateLimits++
            # Try to honor Retry-After if present
            $retry = 5
            try {
                $ra = $_.Exception.Response.Headers["Retry-After"]
                if ($ra) { $retry = [math]::Max(3, [int]$ra) }
            } catch {}
            Write-Host "  [RATE LIMIT] Cooling $retry s..." -ForegroundColor Magenta
            Start-Sleep -Seconds $retry
            return "ratelimit"
        }
        if ($status -eq 400 -or $status -eq 403) {
            # Often invalid format or blocked
            return "invalid"
        }
        $script:Stats.Errors++
        return "error"
    }
}

function Save-Result {
    param(
        [string]$Username,
        [string]$Status,
        [string]$Mode = "SNIPER"
    )

    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "$Username | $ts | $Mode"

    if ($Status -eq "available") {
        Add-Content -Path $script:AvailableFile -Value $line -Encoding UTF8
        $script:Stats.Available++
        Write-Host "  [AVAILABLE] $Username  ($Mode)" -ForegroundColor Green
        if ($script:NotifyAvailable -and $script:AvailableWebhook) {
            Send-Webhook -Url $script:AvailableWebhook -Username $Username -Status "AVAILABLE" -Mode $Mode
        }
    }
    elseif ($Status -eq "taken") {
        Add-Content -Path $script:TakenFile -Value $line -Encoding UTF8
        $script:Stats.Taken++
        Write-Host "  [TAKEN]     $Username  ($Mode)" -ForegroundColor DarkRed
        if ($script:NotifyTaken -and $script:TakenWebhook) {
            Send-Webhook -Url $script:TakenWebhook -Username $Username -Status "TAKEN" -Mode $Mode
        }
    }
}

function Send-Webhook {
    param(
        [string]$Url,
        [string]$Username,
        [string]$Status,
        [string]$Mode = "SNIPER"
    )

    if (-not $Url -or $Url -notmatch 'discord.com/api/webhooks') { return }

    $color = if ($Status -eq "AVAILABLE") { 5763719 } else { 15548997 } # green / red
    $title = if ($Status -eq "AVAILABLE") { "NELORIA // SNIPED AVAILABLE" } else { "NELORIA // TAKEN" }

    $embed = @{
        title       = $title
        description = "**Mode:** $Mode`n**Username:** ``$Username```n**Status:** **$Status**"
        color       = $color
        footer      = @{ text = "NELORIA'S USER SNIPER | EDEN-XANDER" }
        timestamp   = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    }

    $payload = @{
        content = if ($Status -eq "AVAILABLE") { "@everyone **FREE USERNAME**" } else { $null }
        embeds  = @($embed)
        username = "NELORIA SNIPER"
    } | ConvertTo-Json -Depth 6 -Compress

    try {
        Invoke-RestMethod -Uri $Url -Method Post -Body $payload -ContentType "application/json" -TimeoutSec 8 | Out-Null
    } catch {
        Write-Host "  [!] Webhook send failed: $($_.Exception.Message)" -ForegroundColor DarkYellow
    }
}

function Wait-Delay {
    $extra = if ($script:Jitter -gt 0) { Get-Random -Minimum 0 -Maximum ($script:Jitter + 1) } else { 0 }
    $total = $script:Delay + $extra
    if ($total -gt 0) { Start-Sleep -Seconds $total }
}

# ====================== GENERATORS ======================
function Get-RandomString {
    param([int]$Length, [string]$Charset)
    $sb = New-Object System.Text.StringBuilder $Length
    $max = $Charset.Length
    for ($i = 0; $i -lt $Length; $i++) {
        [void]$sb.Append($Charset[(Get-Random -Maximum $max)])
    }
    return $sb.ToString()
}

function Generate-Letters {
    param([int]$Len)
    $charset = "abcdefghijklmnopqrstuvwxyz"
    return Get-RandomString -Length $Len -Charset $charset
}

function Generate-Chars {
    param([int]$Len)
    # a-z 0-9 _ .
    $charset = "abcdefghijklmnopqrstuvwxyz0123456789_."
    do {
        $name = Get-RandomString -Length $Len -Charset $charset
        # Basic Discord rules filter (start/end alnum, no consecutive specials)
    } while (
        $name -match '^[._]' -or
        $name -match '[._]$' -or
        $name -match '\.\.' -or
        $name -match '__' -or
        $name -match '_\.' -or
        $name -match '\._'
    )
    return $name
}

function Generate-AllLetters {
    param([int]$Len)
    Write-Host "  Generating ALL $Len-letter combinations (this may take a few seconds for length 4)..." -ForegroundColor DarkCyan
    $chars = "abcdefghijklmnopqrstuvwxyz".ToCharArray()
    $results = [System.Collections.Generic.List[string]]::new()
    function Recurse([string]$current) {
        if ($current.Length -eq $Len) {
            $results.Add($current)
            return
        }
        foreach ($c in $chars) {
            Recurse ($current + $c)
        }
    }
    Recurse ""
    # Shuffle so never alphabetical
    return $results | Sort-Object { Get-Random }
}

function Generate-AllChars {
    param([int]$Len)
    Write-Host "  Generating ALL $Len-character combinations (a-z0-9_.) - filtered for Discord rules..." -ForegroundColor DarkCyan
    if ($Len -gt 3) {
        Write-Host "  WARNING: 4-character full enum is ~1.8 million names. This will use significant RAM and time." -ForegroundColor Yellow
        Write-Host "  Continuing anyway as requested..." -ForegroundColor Yellow
    }
    $charset = "abcdefghijklmnopqrstuvwxyz0123456789_.".ToCharArray()
    $results = [System.Collections.Generic.List[string]]::new()
    function Recurse([string]$current) {
        if ($current.Length -eq $Len) {
            # Discord rules filter
            if ($current -notmatch '^[._]|[._]$|\.\.|__|_\.|\._') {
                $results.Add($current)
            }
            return
        }
        foreach ($c in $charset) {
            Recurse ($current + $c)
        }
    }
    Recurse ""
    return $results | Sort-Object { Get-Random }
}

function Generate-Numbers {
    param([int]$Len)
    $charset = "0123456789"
    return Get-RandomString -Length $Len -Charset $charset
}

function Generate-AllNumbers {
    param([int]$Len)
    $chars = "0123456789".ToCharArray()
    $results = [System.Collections.Generic.List[string]]::new()
    function Recurse([string]$current) {
        if ($current.Length -eq $Len) {
            $results.Add($current)
            return
        }
        foreach ($c in $chars) {
            Recurse ($current + $c)
        }
    }
    Recurse ""
    return $results | Sort-Object { Get-Random }
}

function Generate-RepeatedLetters {
    param([int]$Len)
    # Creates usernames that contain at least one pair of consecutive same letters (xx), rest random letters.
    # Examples: dd (len2), xxts / abbc / axxd (len4), etc. Never pure aaaa only.
    $charset = "abcdefghijklmnopqrstuvwxyz"
    $name = New-Object char[] $Len

    # Choose starting position for the double (0 to Len-2)
    $doublePos = Get-Random -Maximum ($Len - 1)

    # Choose the repeated letter
    $repChar = $charset[(Get-Random -Maximum $charset.Length)]

    # Fill everything with random first
    for ($i = 0; $i -lt $Len; $i++) {
        $name[$i] = $charset[(Get-Random -Maximum $charset.Length)]
    }

    # Force the double
    $name[$doublePos]     = $repChar
    $name[$doublePos + 1] = $repChar

    return -join $name
}

function Generate-RepeatedChars {
    param([int]$Len)
    # Same as above but full charset (a-z0-9_.)
    # Examples: xx4s, a11b, d__t, 99xx etc.
    $charset = "abcdefghijklmnopqrstuvwxyz0123456789_."
    $name = New-Object char[] $Len

    $doublePos = Get-Random -Maximum ($Len - 1)
    $repChar = $charset[(Get-Random -Maximum $charset.Length)]

    for ($i = 0; $i -lt $Len; $i++) {
        $name[$i] = $charset[(Get-Random -Maximum $charset.Length)]
    }

    $name[$doublePos]     = $repChar
    $name[$doublePos + 1] = $repChar

    $result = -join $name

    # Basic Discord filter - regenerate if bad (rare)
    if ($result -match '^[._]|[._]$|\.\.|__|_\.|\._') {
        return Generate-RepeatedChars -Len $Len   # simple retry
    }
    return $result
}

# ====================== SNIPE LOOPS ======================
function Start-Sniper {
    param(
        [string]$Mode,
        [int]$Length = 0,
        [switch]$LettersOnly,
        [switch]$Fluent,
        [switch]$NumbersOnly,
        [switch]$Repeated,
        [switch]$RepeatedChars
    )

    $script:Running = $true
    $script:Stats = @{ Checked = 0; Available = 0; Taken = 0; Errors = 0; RateLimits = 0 }

    Write-Host "`n========================================" -ForegroundColor White
    Write-Host "  STARTING: $Mode" -ForegroundColor Cyan
    Write-Host "  Delay: $($script:Delay)s + jitter | Proxies: $($script:Proxies.Count) | Max: $(if($script:MaxChecks -eq 0){'INF'}else{$script:MaxChecks})" -ForegroundColor DarkGray
    Write-Host "  Press Ctrl+C to stop gracefully" -ForegroundColor Yellow
    Write-Host "========================================`n" -ForegroundColor White

    $list = @()
    $useList = $false

    if ($Fluent) {
        $list = $script:FluentWords | Sort-Object { Get-Random }
        $useList = $true
        Write-Host "[*] Loaded $($list.Count) fluent English words (shuffled)" -ForegroundColor Cyan
    }
    elseif ($Repeated) {
        Write-Host "[*] Infinite random mode with consecutive double letters (xx?? / ?xx? / ??xx style)" -ForegroundColor Cyan
        # no list - pure random generation every time
    }
    elseif ($RepeatedChars) {
        Write-Host "[*] Infinite random mode with consecutive double characters (xx4s / a11b / d__t style)" -ForegroundColor Cyan
        # no list - pure random generation every time
    }
    elseif ($NumbersOnly) {
        Write-Host "[*] Generating ALL $Length-digit numbers (every single one, shuffled)..." -ForegroundColor Cyan
        $list = Generate-AllNumbers -Len $Length
        $useList = $true
        Write-Host "[*] $($list.Count) usernames ready" -ForegroundColor Cyan
    }
    elseif ($LettersOnly) {
        Write-Host "[*] Generating ALL $Length-letter combinations (every single a-z, shuffled non-alpha)..." -ForegroundColor Cyan
        $list = Generate-AllLetters -Len $Length
        $useList = $true
        Write-Host "[*] $($list.Count) usernames ready" -ForegroundColor Cyan
    }
    elseif (-not $LettersOnly -and -not $NumbersOnly -and -not $Repeated -and -not $RepeatedChars) {
        # Full characters mode
        Write-Host "[*] Generating ALL $Length-character combinations (every single a-z0-9_., filtered + shuffled)..." -ForegroundColor Cyan
        $list = Generate-AllChars -Len $Length
        $useList = $true
        Write-Host "[*] $($list.Count) usernames ready" -ForegroundColor Cyan
    }
    else {
        Write-Host "[*] Infinite random generation mode (any order)" -ForegroundColor Cyan
    }

    $index = 0
    $checkedThisRun = 0

    try {
        while ($script:Running) {
            if ($script:MaxChecks -gt 0 -and $checkedThisRun -ge $script:MaxChecks) {
                Write-Host "`n[*] Reached MAX_CHECKS ($($script:MaxChecks)). Stopping." -ForegroundColor Yellow
                break
            }

            $username = $null
            if ($useList) {
                if ($index -ge $list.Count) {
                    Write-Host "`n[*] Exhausted list. Reshuffling / regenerating..." -ForegroundColor Yellow
                    if ($Fluent) {
                        $list = $script:FluentWords | Sort-Object { Get-Random }
                    } elseif ($NumbersOnly) {
                        $list = Generate-AllNumbers -Len $Length
                    } elseif ($LettersOnly) {
                        $list = Generate-AllLetters -Len $Length
                    } else {
                        $list = Generate-AllChars -Len $Length
                    }
                    $index = 0
                }
                $username = $list[$index]
                $index++
            }
            else {
                if ($Repeated) {
                    $username = Generate-RepeatedLetters -Len $Length
                } elseif ($RepeatedChars) {
                    $username = Generate-RepeatedChars -Len $Length
                } elseif ($NumbersOnly) {
                    $username = Generate-Numbers -Len $Length
                } elseif ($LettersOnly) {
                    $username = Generate-Letters -Len $Length
                } else {
                    $username = Generate-Chars -Len $Length
                }
            }

            if ($script:Checked.Contains($username)) {
                continue  # already known
            }

            $result = Test-DiscordUsername -Username $username
            $script:Stats.Checked++
            $checkedThisRun++
            [void]$script:Checked.Add($username)

            switch ($result) {
                "available" { Save-Result -Username $username -Status "available" -Mode $Mode }
                "taken"     { Save-Result -Username $username -Status "taken" -Mode $Mode }
                "ratelimit" { 
                    # already slept inside
                    $script:Stats.Checked--  # don't count as real check
                    $checkedThisRun--
                    [void]$script:Checked.Remove($username)
                    continue
                }
                "invalid"   { 
                    # treat as taken for practical purposes
                    Save-Result -Username $username -Status "taken" -Mode $Mode
                }
                default     { 
                    Write-Host "  [?] $username -> $result" -ForegroundColor DarkYellow
                }
            }

            # Live stats every 10
            if ($script:Stats.Checked % 10 -eq 0) {
                Write-Host "  --- Checked: $($script:Stats.Checked) | Avail: $($script:Stats.Available) | Taken: $($script:Stats.Taken) | RL: $($script:Stats.RateLimits) ---" -ForegroundColor DarkCyan
            }

            Wait-Delay
        }
    }
    catch {
        if ($_.Exception.Message -match "canceled|interrupted|Ctrl") {
            Write-Host "`n[*] Interrupted by user." -ForegroundColor Yellow
        } else {
            Write-Host "`n[!] Error: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    finally {
        $script:Running = $false
        Write-Host "`n========================================" -ForegroundColor White
        Write-Host "  SESSION COMPLETE" -ForegroundColor Cyan
        Write-Host "  Checked : $($script:Stats.Checked)" -ForegroundColor White
        Write-Host "  Available: $($script:Stats.Available)" -ForegroundColor Green
        Write-Host "  Taken   : $($script:Stats.Taken)" -ForegroundColor Red
        Write-Host "  RateLimits: $($script:Stats.RateLimits)" -ForegroundColor Magenta
        Write-Host "  Results saved to available.txt / taken.txt" -ForegroundColor DarkGray
        Write-Host "========================================`n" -ForegroundColor White
    }
}

function Start-AllInOne {
    Write-Host "`n[*] ALL-IN-ONE mode: cycles through enabled categories from webhooks.txt" -ForegroundColor Cyan
    # For simplicity run each category for a short burst or infinite random mix
    # Here we do continuous random mix of all enabled types
    $script:Running = $true
    $script:Stats = @{ Checked = 0; Available = 0; Taken = 0; Errors = 0; RateLimits = 0 }

    $modes = @()
    # Parse enables from webhooks file again for multi
    $enables = @{
        "2L" = $true; "2C" = $true; "3L" = $true; "3C" = $true; "4L" = $true; "4C" = $true; "F" = $true
    }
    if (Test-Path $script:WebhooksFile) {
        Get-Content $script:WebhooksFile | ForEach-Object {
            if ($_ -match '^\s*2_LETTERS\s*=\s*(true|false)') { $enables["2L"] = ($matches[1] -eq "true") }
            if ($_ -match '^\s*2_CHARS\s*=\s*(true|false)')   { $enables["2C"] = ($matches[1] -eq "true") }
            if ($_ -match '^\s*3_LETTERS\s*=\s*(true|false)') { $enables["3L"] = ($matches[1] -eq "true") }
            if ($_ -match '^\s*3_CHARS\s*=\s*(true|false)')   { $enables["3C"] = ($matches[1] -eq "true") }
            if ($_ -match '^\s*4_LETTERS\s*=\s*(true|false)') { $enables["4L"] = ($matches[1] -eq "true") }
            if ($_ -match '^\s*4_CHARS\s*=\s*(true|false)')   { $enables["4C"] = ($matches[1] -eq "true") }
            if ($_ -match '^\s*FLUENT_ENGLISH\s*=\s*(true|false)') { $enables["F"] = ($matches[1] -eq "true") }
        }
    }

    $enabledList = ($enables.GetEnumerator() | Where-Object {$_.Value} | ForEach-Object {$_.Key}) -join ', '
    Write-Host "  Enabled: $enabledList" -ForegroundColor DarkGray
    Write-Host "  Press Ctrl+C to stop`n" -ForegroundColor Yellow

    $checkedThisRun = 0
    try {
        while ($script:Running) {
            if ($script:MaxChecks -gt 0 -and $checkedThisRun -ge $script:MaxChecks) { break }

            # Pick random enabled mode
            $possible = @()
            if ($enables["2L"]) { $possible += "2L" }
            if ($enables["2C"]) { $possible += "2C" }
            if ($enables["3L"]) { $possible += "3L" }
            if ($enables["3C"]) { $possible += "3C" }
            if ($enables["4L"]) { $possible += "4L" }
            if ($enables["4C"]) { $possible += "4C" }
            if ($enables["F"])  { $possible += "F"  }
            if ($possible.Count -eq 0) { Write-Host "No categories enabled!"; break }

            $pick = $possible | Get-Random
            $username = switch ($pick) {
                "2L" { Generate-Letters -Len 2 }
                "2C" { Generate-Chars -Len 2 }
                "3L" { Generate-Letters -Len 3 }
                "3C" { Generate-Chars -Len 3 }
                "4L" { Generate-Letters -Len 4 }
                "4C" { Generate-Chars -Len 4 }
                "F"  { $script:FluentWords | Get-Random }
            }

            if ($script:Checked.Contains($username)) { continue }

            $result = Test-DiscordUsername -Username $username
            $script:Stats.Checked++
            $checkedThisRun++
            [void]$script:Checked.Add($username)

            switch ($result) {
                "available" { Save-Result -Username $username -Status "available" -Mode "ALL-IN-ONE ($pick)" }
                "taken"     { Save-Result -Username $username -Status "taken" -Mode "ALL-IN-ONE ($pick)" }
                "ratelimit" { 
                    $script:Stats.Checked--; $checkedThisRun--
                    [void]$script:Checked.Remove($username)
                    continue 
                }
                "invalid"   { Save-Result -Username $username -Status "taken" -Mode "ALL-IN-ONE ($pick)" }
                default     { Write-Host "  [?] $username ($pick) -> $result" -ForegroundColor DarkYellow }
            }

            if ($script:Stats.Checked % 15 -eq 0) {
                Write-Host "  --- [$pick] Checked: $($script:Stats.Checked) | A:$($script:Stats.Available) T:$($script:Stats.Taken) RL:$($script:Stats.RateLimits) ---" -ForegroundColor DarkCyan
            }

            Wait-Delay
        }
    }
    finally {
        $script:Running = $false
        Write-Host "`n=== ALL-IN-ONE SESSION END ===" -ForegroundColor Cyan
        Write-Host "Checked: $($script:Stats.Checked) | Available: $($script:Stats.Available) | Taken: $($script:Stats.Taken)" -ForegroundColor White
    }
}

# ====================== MENU UI ======================
function Show-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "========================================" -ForegroundColor White
    Write-Host "      NELORIA'S USER SNIPER" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor White
    Write-Host ""
}

function Show-Menu {
    Show-Banner
    Write-Host " 1  2 Letters Sniper" -ForegroundColor White
    Write-Host " 2  2 Letters Repeated" -ForegroundColor White
    Write-Host " 3  2 Characters Sniper" -ForegroundColor White
    Write-Host " 4  3 Letters Sniper" -ForegroundColor White
    Write-Host " 5  3 Letters Repeated" -ForegroundColor White
    Write-Host " 6  3 Characters Sniper" -ForegroundColor White
    Write-Host " 7  3 Characters Repeated" -ForegroundColor White
    Write-Host " 8  4 Letters Sniper" -ForegroundColor White
    Write-Host " 9  4 Letters Repeated" -ForegroundColor White
    Write-Host " 10 4 Characters Sniper" -ForegroundColor White
    Write-Host " 11 4 Characters Repeated" -ForegroundColor White
    Write-Host " 12 4 Numbers Sniper" -ForegroundColor White
    Write-Host " 13 Fluent English Words" -ForegroundColor White
    Write-Host " 14 Exit" -ForegroundColor White
    Write-Host ""
    Write-Host "========================================" -ForegroundColor White
    Write-Host ""
}

function Show-SystemInfo {
    Show-Banner
    Write-Host " SYSTEM INFORMATION" -ForegroundColor Cyan
    Write-Host " ----------------------------------------"
    Write-Host " Base Dir     : $script:BaseDir"
    Write-Host " Token        : $(if($script:Token){'[SET - ' + $script:Token.Substring(0,[Math]::Min(12,$script:Token.Length)) + '...]' }else{'[NOT SET]'})"
    Write-Host " Delay        : $($script:Delay) s"
    Write-Host " Jitter       : $($script:Jitter) s"
    Write-Host " Use Proxies  : $($script:UseProxies) ($($script:Proxies.Count) loaded)"
    Write-Host " Max Checks   : $(if($script:MaxChecks -eq 0){'Infinite'}else{$script:MaxChecks})"
    Write-Host " Available WH : $(if($script:AvailableWebhook){'[SET]'}else{'[NONE]'})"
    Write-Host " Taken WH     : $(if($script:TakenWebhook){'[SET]'}else{'[NONE]'})"
    Write-Host " Known Checked: $($script:Checked.Count)"
    Write-Host " Available file: $(if(Test-Path $script:AvailableFile){(Get-Content $script:AvailableFile | Measure-Object -Line).Lines}else{0}) lines"
    Write-Host " Taken file   : $(if(Test-Path $script:TakenFile){(Get-Content $script:TakenFile | Measure-Object -Line).Lines}else{0}) lines"
    Write-Host " ----------------------------------------"
    Write-Host " Endpoint     : POST /unique-username/username-attempt-unauthed"
    Write-Host " Rate strategy: delay + jitter + proxy rotation + 429 backoff"
    Write-Host " ----------------------------------------`n"
    Write-Host " Press any key to return..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Create-RestorePoint {
    $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $bakDir = Join-Path $script:BaseDir "backups"
    if (-not (Test-Path $bakDir)) { New-Item -ItemType Directory -Path $bakDir | Out-Null }
    Copy-Item $script:SettingsFile (Join-Path $bakDir "settings_$stamp.txt") -ErrorAction SilentlyContinue
    Copy-Item $script:WebhooksFile (Join-Path $bakDir "webhooks_$stamp.txt") -ErrorAction SilentlyContinue
    Copy-Item $script:AvailableFile (Join-Path $bakDir "available_$stamp.txt") -ErrorAction SilentlyContinue
    Copy-Item $script:TakenFile (Join-Path $bakDir "taken_$stamp.txt") -ErrorAction SilentlyContinue
    Write-Host "`n[+] Restore point created in backups\  ($stamp)" -ForegroundColor Green
    Start-Sleep -Seconds 2
}

function Restore-Settings {
    Write-Host "`n[*] This will re-create default settings/webhooks/proxies if missing." -ForegroundColor Yellow
    Write-Host "    Existing files are NOT overwritten. Delete them manually first if you want pure defaults." -ForegroundColor DarkGray
    Initialize-Files
    Load-Config
    Write-Host "[+] Done." -ForegroundColor Green
    Start-Sleep -Seconds 2
}

# ====================== MAIN ======================
Initialize-Files
Load-Config

# Trap Ctrl+C
[Console]::TreatControlCAsInput = $false
$null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action { $script:Running = $false }

while ($true) {
    Show-Menu
    $choice = Read-Host " Select option"

    switch ($choice) {
        "1"  { Start-Sniper -Mode "2 LETTERS" -Length 2 -LettersOnly }
        "2"  { Start-Sniper -Mode "2 LETTERS REPEATED" -Length 2 -Repeated }
        "3"  { Start-Sniper -Mode "2 CHARACTERS" -Length 2 }
        "4"  { Start-Sniper -Mode "3 LETTERS" -Length 3 -LettersOnly }
        "5"  { Start-Sniper -Mode "3 LETTERS REPEATED" -Length 3 -Repeated }
        "6"  { Start-Sniper -Mode "3 CHARACTERS" -Length 3 }
        "7"  { Start-Sniper -Mode "3 CHARACTERS REPEATED" -Length 3 -RepeatedChars }
        "8"  { Start-Sniper -Mode "4 LETTERS" -Length 4 -LettersOnly }
        "9"  { Start-Sniper -Mode "4 LETTERS REPEATED" -Length 4 -Repeated }
        "10" { Start-Sniper -Mode "4 CHARACTERS" -Length 4 }
        "11" { Start-Sniper -Mode "4 CHARACTERS REPEATED" -Length 4 -RepeatedChars }
        "12" { Start-Sniper -Mode "4 NUMBERS" -Length 4 -NumbersOnly }
        "13" { Start-Sniper -Mode "FLUENT ENGLISH" -Fluent }
        "14" { 
            Write-Host "`n[*] Exiting NELORIA'S USER SNIPER. Loyalty absolute." -ForegroundColor Cyan
            Write-Host "    Files left intact. Run again anytime.`n" -ForegroundColor DarkGray
            exit 0 
        }
        default {
            Write-Host " Invalid selection." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}
