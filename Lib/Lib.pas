unit Lib;

interface

uses
  Classes;
  
type
  TMessageType = set of (mtOK, mtCancel, mtInformation, mtQuestion, mtYesNo, mtCritical, mtExclamation);
  TMessageResult = (mrOK, mrCancel, mrYes, mrNo);

function MessageBox(const AText: string; const AMode: TMessageType): TMessageResult;
function GetTempFileName(const APath: string; const APrefix: string): string;

implementation

uses
  Windows, SysUtils;
  
function MessageBox(const AText: string; const AMode: TMessageType): TMessageResult;
var
  iBox: integer;
  iResult: integer;
begin
  iBox := 0;
  if mtYesNo in AMode then
  begin
    if mtCancel in AMode then
      iBox := iBox or MB_YESNOCANCEL
    else
      iBox := iBox or MB_YESNO
  end
  else
  begin
    if mtCancel in AMode then
      iBox := iBox or MB_OKCANCEL
    else
      iBox := iBox or MB_OK;
  end;
  if mtInformation in AMode then
    iBox := iBox or MB_ICONINFORMATION
  else if mtQuestion in AMode then
    iBox := iBox or MB_ICONQUESTION
  else if mtCritical in AMode then
    iBox := iBox or MB_ICONSTOP
  else if mtExclamation in AMode then
    iBox := iBox or MB_ICONEXCLAMATION;

  iResult := Windows.MessageBox(0, PAnsiChar(AText), 'MW2Patch', iBox);
  Result := mrOK;

  if iResult = IDOK then
  else if iResult = IDCANCEL then
    Result := mrCancel
  else if iResult = IDYES then
    Result := mrYes
  else if iResult = IDNO then
    Result := mrNo;
end;

function GetTempFileName(const APath: string; const APrefix: string): string;
var
  pBuf: array[0..MAX_PATH - 1] of char;
begin
  Windows.GetTempFileName(PAnsiChar(APath), PAnsiChar(APrefix), 0, pBuf);
  Result := pBuf;
end;
end.
