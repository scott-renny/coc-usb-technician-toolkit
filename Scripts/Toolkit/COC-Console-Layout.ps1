[CmdletBinding()]
param([int]$ContentWidth=70,[int]$ContentHeight=30,[int]$Columns=0,[int]$Rows=0)
$ErrorActionPreference='Stop'
# Query the inherited console error handle: stdout is captured by CMD FOR /F.
if($Columns -le 0 -or $Rows -le 0){
 try{
  Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class CocConsoleLayout {
 [StructLayout(LayoutKind.Sequential)] public struct Coord { public short X,Y; }
 [StructLayout(LayoutKind.Sequential)] public struct Rect { public short Left,Top,Right,Bottom; }
 [StructLayout(LayoutKind.Sequential)] public struct Info { public Coord Size,Cursor; public short Attributes; public Rect Window; public Coord Maximum; }
 [DllImport("kernel32.dll")] static extern IntPtr GetStdHandle(int n);
 [DllImport("kernel32.dll")] static extern bool GetConsoleScreenBufferInfo(IntPtr h,out Info i);
 public static int[] Dimensions(){Info i; if(!GetConsoleScreenBufferInfo(GetStdHandle(-12),out i))return new int[]{0,0};return new int[]{i.Window.Right-i.Window.Left+1,i.Window.Bottom-i.Window.Top+1};}
}
"@
  $size=[CocConsoleLayout]::Dimensions()
  if($Columns -le 0){$Columns=$size[0]};if($Rows -le 0){$Rows=$size[1]}
 }catch{$Columns=0;$Rows=0}
}
$left=if($Columns -gt 0){[Math]::Max(0,[Math]::Floor(($Columns-$ContentWidth)/2))}else{0}
$top=if($Rows -gt 0){[Math]::Max(0,[Math]::Floor(($Rows-$ContentHeight)/2))}else{0}
# Clamp pathological sizes; narrow windows keep zero margin rather than negative padding.
$left=[Math]::Min(200,$left);$top=[Math]::Min(100,$top)
'P:X'+(' '*$left)
for($i=0;$i -lt $top;$i++){'B:X'}
