program MW2Patch;

{$R 'fixed.res' 'fixed.rc'}
{$R 'Icon.res' 'Icon.rc'}

uses
  Classes,
  Clipbrd,
  Windows,
  SysUtils,
  Lib,
  Text,
  Hunks,
  Registry,
  FileCtrl2,
  ShellAPI,
  ChecksumStream;

var
  strDirectory: string;

function Disclaimer(const AGameVersion: integer): boolean;
var
  strVersion: string;
begin
  if AGameVersion = 0 then
    strVersion := 'Unknown version detected, still might be able to patch'
  else
    strVersion := 'Detected ' + AllGames[AGameVersion].Name;

  Result := MessageBox(StringReplace(Text.Disclaimer, '%VERSION%', strVersion, [rfReplaceAll]), [mtYesNo, mtQuestion]) = mrYes;
end;

type
  TFile = record
    OurStream: TFileStream;
    OrigName: string;
    OurName: string;
    OriginalAlready: boolean;
  end;

  TFileList = array of TFile;

procedure CleanupFile(var AFile: TFile);
begin
  with AFile do
  begin
    if Assigned(OurStream) then
    begin
      OurStream.Free;
      OurStream := nil;
      if OurName <> '' then
        DeleteFile(OurName);
    end;
  end;
end;

procedure CleanupFiles(const AFileList: TFileList);
var
  iCount: integer;
begin
  for iCount := 0 to length(AFileList) - 1 do
    CleanupFile(AFileList[iCount]);
end;

procedure SetDirectory();
begin
  if Paramcount = 0 then
    strDirectory := ExtractFilePath(ParamStr(0)) + '\'
  else
    strDirectory := ParamStr(1) + '\';

  ChDir(strDirectory);
end;

function LocateHunk(const AFile: TFileStream; const AHunk: string): integer;
var
  Buffer: string;
begin
  AFile.Position := 0;
  setlength(Buffer, length(AHunk));
  while AFile.Size - AFile.Position >= 16 do
  begin
    AFile.ReadBuffer(Buffer[1], 16);
    if Copy(Buffer, 0, 16) = Copy(AHunk, 0, 16) then
    begin
      AFile.ReadBuffer(Buffer[17], length(Buffer) - 16);
      if Buffer = AHunk then
      begin
        Result := AFile.Position - length(Buffer);
        exit;
      end;
    end;
  end;
  Result := -1;
end;

type
  TPossibleFile = record
    Name: string;
    Checksum: string;
    Size: integer;
    OpenName: string;
  end;

  TPossibleFileList = array of TPossibleFile;

function GetAllChecksums: TPossibleFileList;
var
  iCount: integer;
  iFoundCount: integer;
  pFile: TFileStream;
  pTemp: TPossibleFileList;
  pChecksum: TChecksumStream;
begin
  setlength(pTemp, length(AllFiles));
  iFoundCount := 0;

  for iCount := 0 to length(pTemp) - 1 do
    with pTemp[iCount] do
    begin
      Name := AllFiles[iCount];
      if not FileExists(Name) then
      begin
        Name := '';
        continue;
      end;
      OpenName := Name;
      
      if FileExists(Name + '.orig') then
        OpenName := Name + '.orig';

      inc(iFoundCount);

      pFile := TFileStream.Create(OpenName, fmOpenRead or fmShareExclusive);
      try
        Size := pFile.Size;
        pChecksum := TChecksumStream.Create(pFile);
        try
          with TNullStream.Create do
            try
              CopyFrom(pChecksum, 0);
            finally
              Free;
            end;
          Checksum := pChecksum.Checksum;
        finally
          pChecksum.Free
        end;
      finally
        pFile.Free;
      end;
    end;

  setlength(Result, iFoundCount);
  iFoundCount := 0;
  for iCount := 0 to length(pTemp) - 1 do
  begin
    if pTemp[iCount].Name = '' then
      continue;

    Result[iFoundCount] := pTemp[iCount];
    inc(iFoundCount);
  end;
end;

function DetermineVersion(out AChecksumList: TPossibleFileList): integer;
var
  pChecksumList: TPossibleFileList;
  iCount: integer;
  iCount2: integer;
  iCount3: integer;
  fFound: boolean;
  fNotThisOne: boolean;
begin
  pChecksumList := GetAllChecksums();
  AChecksumList := pChecksumList;

  for iCount := 1 to length(AllGames) - 1 do
  begin
    fNotThisOne := false;
    for iCount2 := 0 to length(AllGames[iCount].Files) - 1 do
    begin
      fFound := false;
      for iCount3 := 0 to length(pChecksumList) - 1 do
      begin
        if (pChecksumList[iCount3].Size = AllGames[iCount].Files[iCount2].Size) and (pChecksumList[iCount3].Name = AllGames[iCount].Files[iCount2].Filename) and (pChecksumList[iCount3].Checksum = AllGames[iCount].Files[iCount2].Checksum) then
        begin
          fFound := true;
          break;
        end;
      end;
      if not fFound then
      begin
        fNotThisOne := true;
        break;
      end;
    end;
    if not fNotThisOne then
    begin
      Result := iCount;
      exit;
    end;
  end;

  Result := 0;
end;

function OpenFiles(const AGameVersion: integer): TFileList;
var
  iCount: integer;
  iAt: integer;
  pOldStream: TFileStream;
begin
  with AllGames[AGameVersion] do
  begin
    setlength(Result, length(Files));
    iAt := 0;
    for iCount := 0 to length(Files) - 1 do
      with Files[iCount], Result[iAt] do
      begin
        if Files[iCount].Mode = gfmVerify then
          continue;

        OurName := GetTempFileName(GetCurrentDir, 'MW2');
        OurStream := TFileStream.Create(OurName, fmCreate or fmShareExclusive);

        OrigName := Files[iCount].Filename;

        if FileExists(OrigName + '.orig') then
          OriginalAlready := true;

        if Mode = gfmResName then
        begin
//          OriginalAlready := true

        end
        else if Mode = gfmHunks then
        begin
          if FileExists(OrigName + '.orig') then
          begin
            pOldStream := TFileStream.Create(OrigName + '.orig', fmOpenRead or fmShareDenyWrite);
            OriginalAlready := true;
          end
          else
            pOldStream := TFileStream.Create(OrigName, fmOpenRead or fmShareDenyWrite);
          try
            OurStream.CopyFrom(pOldStream, 0);
          finally
            pOldStream.Free;
          end;

          OurStream.Position := 0;
        end;
       inc(iAt);

      end;
  end;

  setlength(Result, iAt);
end;

procedure CreateQuickExec(const AFilename, ARun: string);
var
  pRes: TResourceStream;
  bLength: byte;
begin
  with TFileStream.Create(AFilename, fmCreate or fmShareExclusive) do
    try
      pRes := TResourceStream.Create(hInstance, 'quickexec', 'EXECUTABLE');
      try
        CopyFrom(pRes, 0);
      finally
        pRes.Free;
      end;

      WriteBuffer(ARun[1], length(ARun));
      bLength := length(ARun);
      WriteBuffer(bLength, 1);
    finally
      Free;
    end;
end;

function GetHunk(const AName: string): THunk;
var
  iCount: integer;
begin
  for iCount := 0 to length(AllHunks) - 1 do
  begin
    if AllHunks[iCount].RealName = AName then
    begin
      Result := AllHunks[iCount];
      exit;
    end;
  end;
  raise Exception.Create('Unable to locate internal hunk: ' + AName);
end;

function IsWindows2000: boolean;
var
  ssOSVersionInfo: TOSVersionInfo;
begin
  Result := false;
  ssOSVersionInfo.dwOSVersionInfoSize := sizeof(ssOSVersionInfo);
  if GetVersionEx(ssOSVersionInfo) then
    with ssOSVersionInfo do
      if (dwMajorVersion = 5) and (dwMinorVersion = 0) then
        Result := true;
end;

var
  pFiles: TFileList;
  fCompleted: boolean;
  iGameVersion: integer;

  iAt: integer;

  pChecksumList: TPossibleFileList;
  iCount: integer;
  iCount2: integer;
  pRes: TResourceStream;
  strData: string;
  ssHunk: THunk;
  iPosition: integer;
  fRepeating: boolean;
begin
  pFiles := nil;
  fCompleted := false;

  LoadAllHunks();
  SetDirectory();

  try
    fRepeating := false;
    repeat
      iGameVersion := DetermineVersion(pChecksumList);
      if length(pChecksumList) = 0 then
      begin
        if not fRepeating then
        begin
          if not SelectDirectory(0, 'Please select your MechWarrior 2 directory:', '', strDirectory) then
            exit;
          strDirectory := strDirectory + '\';
          ChDir(strDirectory);
          fRepeating := true;
        end
        else
          raise Exception.Create('Unable to locate any MechWarrior 2 files.');
      end
      else
        break;
    until not fRepeating;
    if iGameVersion = 0 then
    begin
      MessageBox(
        'It seems like you have a version of MechWarrior 2 that isn''t currently supported by this patch.' + CRLF +
        '' + CRLF +
        'I''ve copied some diagnostic information to the clipboard, please email this to chris@warp13.co.uk.', [mtExclamation, mtOK]);

      strData := '';

      for iCount := 0 to length(pChecksumList) - 1 do
        with pChecksumList[iCount] do
          strData := strData + '[' + Name + ']' + CRLF + 'Size=' + inttostr(Size) + CRLF + 'Checksum=' + Checksum + CRLF + CRLF;

      Clipboard.SetTextBuf(PAnsiChar(strData));
      exit;
    end;

    with AllGames[iGameVersion] do
    begin
      if WarningMessage <> '' then
      begin
        MessageBox(
          'Detected ' + Name + '.' + CRLF +
          '' + CRLF + WarningMessage, [mtInformation, mtOK]);
        exit;
      end;

      if not Disclaimer(iGameVersion) then
        exit;

      pFiles := OpenFiles(iGameVersion);
      try
        iAt := 0;
        for iCount := 0 to length(Files) - 1 do
          with Files[iCount] do
          begin
            if Mode = gfmVerify then
              continue;

            if Mode = gfmHunks then
            begin
              for iCount2 := 0 to length(Extras) - 1 do
                with pFiles[iAt], OurStream, ssHunk do
                begin
                  ssHunk := GetHunk(Extras[iCount2]);

                  iPosition := LocateHunk(OurStream, Original);
                  if iPosition = -1 then
                    raise Exception.Create('Unable to apply patch: ' + Name);

                  Position := iPosition;
                  WriteBuffer(Modified[1], length(Modified));
                end;
            end
            else if Mode = gfmResName then
            begin
              pRes := TResourceStream.Create(hInstance, Extras[0], 'EXECUTABLE');
              try
                with pFiles[iAt], OurStream do
                begin
                  Size := pRes.Size;
                  Position := 0;
                  CopyFrom(pRes, 0);
                end;
              finally
                pRes.Free;
              end;
            end;
            inc(iAt);
          end;

        for iCount := 0 to length(pFiles) - 1 do //error checking required
          with pFiles[iCount] do
          begin
            if not Assigned(OurStream) then
              continue;
            if not OriginalAlready then
            begin
              if not RenameFile(OrigName, OrigName + '.orig') then
                raise Exception.Create('Unable to rename!')
            end
            else //dont delete
              DeleteFile(OrigName);

            OurStream.Free;
            OurStream := nil;
            if not RenameFile(OurName, OrigName) then
              raise Exception.Create('Unable to rename!');
          end;

        if EXEName <> '' then
        begin
          if DummyExecutable then
          begin
            if FileExists('real' + EXEName) then
              if not DeleteFile('real' + EXEName) then
                raise Exception.Create('Unable to delete old QuickExec''ed executable.');

            if not RenameFile(EXEName, 'real' + EXEName) then
              raise Exception.Create('Unable to rename QuickExec''ed executable.');
              
            CreateQuickExec(EXEName, 'real' + EXEName);
            EXEName := 'real' + EXEName;
          end;
          if RunOptions <> '' then
          begin
            with TRegistry.Create() do
              try
                if OpenKey('Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers', false) then
                  try
                    WriteString(strDirectory + EXEName, RunOptions);
                  finally
                    CloseKey;
                  end
              finally
                Free;
              end;
          end;
        end;

        fCompleted := true;
      finally
        CleanupFiles(pFiles);
      end;
    end;
  except
    on E: Exception do
      MessageBox(E.Message, [mtCritical]);
  end;

  if fCompleted then
  begin
    strData := '';
    if IsWindows2000 then
      strData := CRLF + CRLF + 'Note with Windows 2000 you must have at least Service Pack 2 installed, a web page with instructions will open when you click ok.';

    MessageBox('Patch complete!' + strData, [mtInformation, mtOK]);

    if IsWindows2000 then
      ShellExecute(0, 'open', 'http://support.microsoft.com/default.aspx?scid=kb;en-us;279792', '', '', SW_SHOW);
  end;
end.
