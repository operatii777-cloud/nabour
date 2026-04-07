$l = Get-Content 'E:/variante app friends/03.07.2025 MAP BOX/nabour_app/lib/screens/map_screen.dart'
$out = $l[0..12182] + $l[12195..($l.Count-1)]
Set-Content -Path 'E:/variante app friends/03.07.2025 MAP BOX/nabour_app/lib/screens/map_screen.dart' -Value $out
