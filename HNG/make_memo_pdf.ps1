$OutputPath = Join-Path (Get-Location) 'Analyst_Memo.pdf'

$paragraphs = @(
    'Analyst Memo: TradeZone Performance Review, 2023-2024',
    'To: Head of Growth and Head of Seller Operations',
    'From: Data Analytics Team',
    'Subject: SQL-based review of customer growth, revenue, seller performance and data quality',
    '',
    '1. Executive Summary',
    'TradeZone grew strongly through 2024, with non-cancelled and non-returned quarterly revenue rising from N86.54 million in Q1 2024 to N262.62 million in Q4 2024. However, that growth is uneven: Lagos drives the largest customer acquisition volume, electronics dominate the highest-revenue products, and mid-rated products generate more revenue than high-rated products, which suggests the platform is scaling but not yet converting quality and seller experience into the strongest commercial advantage.',
    '',
    '2. Key Findings',
    'Growth is heavily led by Lagos, but conversion quality varies by state. Query 1 shows Lagos produced the highest number of 2024 sign-ups with 146 new customers and a 41.78% 30-day conversion rate. FCT followed with 92 sign-ups and a 34.78% conversion rate, while Kano had 58 sign-ups but only 25.86% converted within 30 days. This means acquisition volume alone is not enough; TradeZone should treat each state as a separate growth market and focus on improving activation where sign-ups are not quickly becoming buyers.',
    'Revenue accelerated sharply in 2024, with Q4 showing the strongest year-on-year quarterly growth. Query 4 shows Q4 2024 revenue reached N262.62 million across 754 orders, compared with N50.08 million in Q4 2023. This was the strongest revenue growth from 2023 to 2024 among all quarters. The result suggests that TradeZone entered 2025 with real commercial momentum, but leadership should check whether Q4 growth came from repeatable demand or from seasonal buying patterns and promotions.',
    'Product revenue is concentrated in electronics, while review performance does not perfectly match sales performance. Query 2 shows all top 10 products by 2024 revenue are electronics, led by HP Pavilion 15 Laptop Intel i5 - v2 at N21.23 million. Query 7 shows mid-rated products generated N358.24 million in revenue, more than high-rated products at N258.40 million. This is a warning sign for Seller Operations: customers are buying high-value products even when ratings are not the strongest, so poor product or seller experience could become a retention risk if demand continues growing.',
    '',
    '3. Recommendations',
    'Recommendation 1: Launch a 30-day activation campaign in Kano and Oyo focused on first-purchase incentives, onboarding messages and follow-up reminders for new customers. Owner: Head of Growth. Expected outcome within 60 to 90 days: raise Kano''s 30-day conversion rate from 25.86% and Oyo''s from 30.16% toward the current Lagos benchmark of 41.78%, improving the return on acquisition spend. This recommendation is based on Query 1.',
    'Recommendation 2: Create a seller quality review for high-revenue, mid-rated products, starting with the electronics category and sellers attached to the top 10 revenue products. Owner: Head of Seller Operations. Expected outcome within 60 to 90 days: reduce the risk that fast-growing electronics sales create customer dissatisfaction, while moving more revenue from the mid-rated group into the high-rated group. This recommendation is based on Queries 2 and 7.',
    '',
    '4. Data Quality Notes',
    'The first major issue was inconsistent formatting in city and product category fields. City values included variants such as Lagos, lagos, LAGOS, Lago s and Port-Harcourt, while product categories included misspellings such as Electronis and Fashon. I standardized these values before analysis so state-level acquisition, payment preference and product performance results would not be split across duplicate labels. If this decision was wrong, the biggest impact would be misallocated state or category totals.',
    'The second major issue was missing price information. Four products had missing unit prices, which caused 97 order items to have missing unit prices or line totals and left 92 orders with missing total amounts after recalculation. I did not invent prices; those rows remain flagged in the data_quality_issues view and were excluded from revenue calculations where the total could not be trusted. If the missing prices later turn out to be material, total revenue and product rankings would be understated.',
    '',
    '5. What the Data Cannot Tell Us',
    'The current dataset cannot explain why certain customers fail to purchase within 30 days after signing up. It shows the conversion outcome by state, but it does not include marketing channel, campaign exposure, app or website session behavior, discount usage, product views, cart activity, delivery fee estimates or customer support contacts. To answer that business question, I would request acquisition-channel data, campaign spend and impressions, behavioral funnel events, discount and promotion records, and customer support interaction data linked to customer_id and signup_date.'
)

function Escape-PdfText([string]$Text) {
    return ($Text -replace '\\', '\\' -replace '\(', '\(' -replace '\)', '\)')
}

function Wrap-Line([string]$Text, [int]$Width) {
    if ([string]::IsNullOrWhiteSpace($Text)) { return @('') }
    $words = $Text -split '\s+'
    $lines = New-Object System.Collections.Generic.List[string]
    $line = ''
    foreach ($word in $words) {
        if ($line.Length -eq 0) {
            $line = $word
        } elseif (($line.Length + 1 + $word.Length) -le $Width) {
            $line = "$line $word"
        } else {
            $lines.Add($line)
            $line = $word
        }
    }
    if ($line.Length -gt 0) { $lines.Add($line) }
    return $lines.ToArray()
}

$allLines = New-Object System.Collections.Generic.List[string]
foreach ($p in $paragraphs) {
    foreach ($line in (Wrap-Line $p 92)) { $allLines.Add($line) }
    $allLines.Add('')
}

$pages = New-Object System.Collections.Generic.List[object]
$current = New-Object System.Collections.Generic.List[string]
foreach ($line in $allLines) {
    if ($current.Count -ge 48) {
        $pages.Add($current.ToArray())
        $current = New-Object System.Collections.Generic.List[string]
    }
    $current.Add($line)
}
if ($current.Count -gt 0) { $pages.Add($current.ToArray()) }

$objects = New-Object System.Collections.Generic.List[string]
$pageRefs = New-Object System.Collections.Generic.List[string]

$objects.Add('<< /Type /Catalog /Pages 2 0 R >>')
$objects.Add('__PAGES__')
$objects.Add('<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>')

for ($i = 0; $i -lt $pages.Count; $i++) {
    $pageObj = 4 + ($i * 2)
    $contentObj = $pageObj + 1
    $pageRefs.Add("$pageObj 0 R")
    $objects.Add("<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 3 0 R >> >> /Contents $contentObj 0 R >>")
    $content = New-Object System.Text.StringBuilder
    [void]$content.AppendLine('BT')
    [void]$content.AppendLine('/F1 10 Tf')
    [void]$content.AppendLine('54 738 Td')
    [void]$content.AppendLine('14 TL')
    foreach ($line in $pages[$i]) {
        [void]$content.AppendLine("($(Escape-PdfText $line)) Tj")
        [void]$content.AppendLine('T*')
    }
    [void]$content.AppendLine('ET')
    $contentText = $content.ToString()
    $length = [System.Text.Encoding]::ASCII.GetByteCount($contentText)
    $objects.Add("<< /Length $length >>`nstream`n$contentText`nendstream")
}

$objects[1] = "<< /Type /Pages /Kids [ $($pageRefs -join ' ') ] /Count $($pages.Count) >>"

$pdf = New-Object System.Text.StringBuilder
$offsets = New-Object System.Collections.Generic.List[int]
[void]$pdf.Append("%PDF-1.4`n")
for ($i = 0; $i -lt $objects.Count; $i++) {
    $offsets.Add([System.Text.Encoding]::ASCII.GetByteCount($pdf.ToString()))
    [void]$pdf.Append("$($i + 1) 0 obj`n$($objects[$i])`nendobj`n")
}
$xrefOffset = [System.Text.Encoding]::ASCII.GetByteCount($pdf.ToString())
[void]$pdf.Append("xref`n0 $($objects.Count + 1)`n")
[void]$pdf.Append("0000000000 65535 f `n")
foreach ($off in $offsets) {
    [void]$pdf.Append(('{0:D10} 00000 n ' -f $off) + "`n")
}
[void]$pdf.Append("trailer`n<< /Size $($objects.Count + 1) /Root 1 0 R >>`nstartxref`n$xrefOffset`n%%EOF`n")

[System.IO.File]::WriteAllBytes($OutputPath, [System.Text.Encoding]::ASCII.GetBytes($pdf.ToString()))
Get-Item $OutputPath | Select-Object Name, Length, LastWriteTime
