import {spawnSync} from 'node:child_process';
const script = String.raw`
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Runtime.WindowsRuntime
Add-Type -AssemblyName System.Drawing
$storageType = [Windows.Storage.StorageFile,Windows.Storage,ContentType=WindowsRuntime]
$pdfType = [Windows.Data.Pdf.PdfDocument,Windows.Data.Pdf,ContentType=WindowsRuntime]
$streamType = [Windows.Storage.Streams.InMemoryRandomAccessStream,Windows.Storage.Streams,ContentType=WindowsRuntime]
$readerType = [Windows.Storage.Streams.DataReader,Windows.Storage.Streams,ContentType=WindowsRuntime]
$optionsType = [Windows.Data.Pdf.PdfPageRenderOptions,Windows.Data.Pdf,ContentType=WindowsRuntime]
$asyncGeneric = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq 'AsTask' -and $_.IsGenericMethod -and $_.GetGenericArguments().Count -eq 1 -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name.StartsWith('IAsyncOperation') } | Select-Object -First 1
$asyncAction = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq 'AsTask' -and -not $_.IsGenericMethod -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.FullName -eq 'Windows.Foundation.IAsyncAction' } | Select-Object -First 1
function Await-Operation($operation, [Type]$resultType) { $task = $asyncGeneric.MakeGenericMethod($resultType).Invoke($null,@($operation)); $task.Wait(); return $task.Result }
$folder = Join-Path $env:REPORT_ROOT $env:REPORT_QA_DIR
$file = Await-Operation ([Windows.Storage.StorageFile]::GetFileFromPathAsync((Join-Path $folder 'QE190010.pdf'))) $storageType
$pdf = Await-Operation ([Windows.Data.Pdf.PdfDocument]::LoadFromFileAsync($file)) $pdfType
for($i=0; $i -lt $pdf.PageCount; $i++) {
  $page=$pdf.GetPage($i)
  $stream=New-Object Windows.Storage.Streams.InMemoryRandomAccessStream
  $options=New-Object Windows.Data.Pdf.PdfPageRenderOptions
  $options.DestinationWidth=1240
  $options.DestinationHeight=[uint32](1240*$page.Size.Height/$page.Size.Width)
  $task=$asyncAction.Invoke($null,@($page.RenderToStreamAsync($stream,$options))); $task.Wait()
  $reader=New-Object Windows.Storage.Streams.DataReader -ArgumentList $stream.GetInputStreamAt(0)
  $loaded=Await-Operation ($reader.LoadAsync([uint32]$stream.Size)) ([uint32])
  [byte[]]$bytes=New-Object byte[] ([int]$stream.Size)
  $reader.ReadBytes($bytes)
  [System.IO.File]::WriteAllBytes((Join-Path $folder ('page-'+($i+1)+'.png')),$bytes)
  $reader.Dispose(); $stream.Dispose(); $page.Dispose()
}
$pages=@(Get-ChildItem -LiteralPath $folder -Filter 'page-*.png' | Sort-Object { [int]($_.BaseName -replace 'page-','') })
$cols=5; $cellW=250; $cellH=380; $rows=[int][Math]::Ceiling($pages.Count/$cols)
$sheet=New-Object System.Drawing.Bitmap ($cols*$cellW),($rows*$cellH)
$graphics=[System.Drawing.Graphics]::FromImage($sheet); $graphics.Clear([System.Drawing.Color]::LightGray)
$font=New-Object System.Drawing.Font 'Arial',10
for($i=0;$i -lt $pages.Count;$i++) { $image=[System.Drawing.Image]::FromFile($pages[$i].FullName); $x=($i%$cols)*$cellW; $y=[int][Math]::Floor($i/$cols)*$cellH; $graphics.DrawImage($image,$x+5,$y+20,240,340); $graphics.DrawString(('Page '+($i+1)),$font,[System.Drawing.Brushes]::Black,$x+8,$y+3); $image.Dispose() }
$sheet.Save((Join-Path $folder 'contact-sheet.png'),[System.Drawing.Imaging.ImageFormat]::Png)
$graphics.Dispose();$font.Dispose();$sheet.Dispose()
Write-Output ('Rendered '+$pdf.PageCount+' pages for visual verification.')
`;
const result=spawnSync('powershell.exe',['-NoProfile','-Command',script],{encoding:'utf8',env:{...process.env,REPORT_ROOT:process.cwd(),REPORT_QA_DIR:process.argv[2] || 'artifacts/report-qa'},maxBuffer:4000000,windowsHide:true});
if(result.stdout)process.stdout.write(result.stdout);if(result.stderr)process.stderr.write(result.stderr);if(result.status!==0)process.exit(result.status||1);
