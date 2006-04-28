program QuickExec;

{$R 'quickexec.res' 'quickexec.rc'}

uses
  Windows,
  SysUtils,
  Classes;

var
  pFile: TFileStream;
  strData: string;
  iOffset: byte;
begin
  pFile := TFileStream.Create(ParamStr(0), fmOpenRead or fmShareDenyNone);
  try
    pFile.Position := pFile.Size - 1;
    pFile.ReadBuffer(iOffset, 1);
    pFile.Position := pFile.Size - 1 - iOffset;
    setlength(strData, iOffset);
    pFile.ReadBuffer(strData[1], iOffset);
  finally
    pFile.Free;
  end;
  WinExec(PAnsiChar(ExtractFileDir(ParamStr(0)) + '\' + strData), SW_SHOW);
end.
