New-Item .\globalintechDnsEntries.txt -type file -force
New-Item .\reversedDnsentries.txt -type file -force
New-Item .\sameHostDiffIp.txt -type file -force
New-Item .\sameiPdiffHosts.txt -type file -force

Write-Host "Getting entries from globalintech.pl"
$entries = & '.\dig.exe' -t axfr +noall +answer globalintech.pl | where-object { $_ -match "\s+A\s+" }
foreach($entry in $entries) { $split = $entry -split '\s+'; Add-Content 'globalintechDnsEntries.txt' "$($split[0]) $($split[4])"}

Write-Host "Getting rev DNS entries"

foreach($ip in 96..101){
    foreach($ip2 in 0..255){
        $requestIp = "10.164.$($ip).$($ip2)"
        $answer = & '.\dig.exe' -x $requestIp +short
        if($answer) {
            Add-Content "reversedDnsentries.txt" "$($answer) $($requestIp)"
        }
    }
}

Write-Host "Comparing dns with rev dns"
$reversedDnsentries = Get-Content "reversedDnsentries.txt"
$globalintechDnsEntries = Get-Content "globalintechDnsEntries.txt"
foreach($reversed in $reversedDnsentries) {
    $hostReversed = $reversed.Split(' ')[0];
    $ipReversed = $reversed.Split(' ')[1];
    foreach($simpleDns in $globalintechDnsEntries){
        $hostSimple = $simpleDns.Split(' ')[0];
        $ipSimple = $simpleDns.Split(' ')[1];

        if($ipSimple -eq $ipReversed){
            if($hostReversed -ne $hostSimple){
                $revHostOnDns = & '.\dig.exe' $hostReversed +short
               Add-Content "sameiPdiffHosts.txt" "$($ipSimple) - $($hostSimple) | $($ipReversed) - $($hostReversed) -- $revHostOnDns"
            }
        }

        if($hostReversed -eq $hostSimple){
            if($ipReversed -ne $ipSimple) { 
                $hostInReversed = $reversedDnsentries | Select-String $ipSimple
                $hostInSimple = $globalintech | Select-String $ipReversed
                Add-Content "sameHostDiffIp.txt" "$($hostSimple) - $($ipSimple) -- $hostInSimple | $($hostReversed) - $($ipReversed) -- $hostInReversed"
            }
        }
    }
}

if(Test-Path .\globalintechDnsEntries.txt) {
    Remove-Item .\globalintechDnsEntries.txt
}

if(Test-Path .\reversedDnsentries.txt) {
    Remove-Item .\reversedDnsentries.txt
}