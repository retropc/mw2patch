unit Hunks;

interface

uses
  Windows, Classes, SysUtils, Registry, IniFiles;

const
  GameTotal = 5;

type
  TGameFileMode = (gfmVerify, gfmResName, gfmHunks);

  TResName = record
    ResName: string;
  end;

  TGameFile = record
    Filename: string;
    Checksum: string;
    Size: integer;
    Mode: TGameFileMode;
    Extras: array of string;
  end;

  TGame = record
    Name: string;
    EXEName: string;
    RunOptions: string;
    DummyExecutable: boolean;
    WarningMessage: string;
    Files: array of TGameFile;
  end;

  THunk = record
    RealName: string;
    Name: string;
    Original: string;
    Modified: string;
  end;

var
  AllGames: array of TGame;
  AllHunks: array of THunk;
  AllFiles: array of string;

procedure LoadAllHunks;

implementation

procedure LoadAllHunks;
function ReadHexSection(const AIni: TMemIniFile; const ASection: string): string;
function HexToInt(const AInput: string): string;
function DigitToValue(const ADigit: char): integer;
begin
  case ADigit of
    '0': Result := 0;
    '1': Result := 1;
    '2': Result := 2;
    '3': Result := 3;
    '4': Result := 4;
    '5': Result := 5;
    '6': Result := 6;
    '7': Result := 7;
    '8': Result := 8;
    '9': Result := 9;
    'A': Result := 10;
    'B': Result := 11;
    'C': Result := 12;
    'D': Result := 13;
    'E': Result := 14;
    'F': Result := 15;
    else
      Result := -1;
  end;
end;
var
  iCount: integer;
begin
  Result := '';
  for iCount := 0 to length(AInput) div 2 - 1 do
    Result := Result + chr(DigitToValue(AInput[iCount * 2 + 1]) shl 4 + DigitToValue(AInput[iCount * 2 + 2]));
end;
var
  pSections: TStringList;
  iCount: integer;
begin
  Result := '';

  pSections := TStringList.Create;
  try
    AIni.ReadSectionValues(ASection, pSections);
    for iCount := 0 to pSections.Count - 1 do
      Result := Result + HexToInt(pSections.Values[pSections.Names[iCount]]);
  finally
    pSections.Free;
  end;
end;

var
  pFile: TResourceStream;
  pIni: TMemIniFile;
  iCount: integer;
  pHunkList: TStringList;
  pSections: TStringList;
  iCurrentFileCount: integer;
  iCount2: integer;
  pHunks: TStringList;
  iCount3: integer;
  pAllFiles: TStringList;
  iTotal: integer;
begin
  iTotal := 1;
  repeat
    if FindResource(hInstance, PAnsiChar('P' + inttostr(iTotal)), 'PATCHSET') = 0 then
      break;
    inc(iTotal);
  until false;

  dec(iTotal);

  setlength(AllGames, iTotal + 1);
  AllGames[0].Name := 'Unknown';

  pHunkList := TStringList.Create;
  try
    pHunkList.Sorted := true;
    pHunkList.Duplicates := dupIgnore;

    pAllFiles := TStringList.Create;
    try
      pAllFiles.Sorted := true;
      pAllFiles.Duplicates := dupIgnore;

      for iCount := 1 to iTotal do
      begin
        pFile := TResourceStream.Create(hInstance, 'P' + inttostr(iCount), 'PATCHSET');
        try
          if pFile.Size = 0 then
            raise Exception.Create('Couldn''t open file P' + inttostr(iCount) + '!');
          pIni := TMemIniFile.Create(pFile);
          try
            with AllGames[iCount] do
            begin
              Name := pIni.ReadString('Options', 'Name', '');
              EXEName := pIni.ReadString('Options', 'ExeName', '');
              RunOptions := pIni.ReadString('Options', 'RunOptions', '');
              DummyExecutable := pIni.ReadBool('Options', 'DummyExecutable', false);
              WarningMessage := pIni.ReadString('Options', 'Message', '');

              pSections := TStringList.Create;
              try
                pIni.ReadSections(pSections);
                setlength(Files, pSections.Count - 1);
                iCurrentFileCount := 0;
                if pSections.Count = 1 then
                  raise Exception.Create(Name);

                for iCount2 := 0 to pSections.Count - 1 do
                begin
                  if pSections[iCount2] = 'Options' then
                    continue;

                  pAllFiles.Add(pSections[iCount2]);

                  with Files[iCurrentFileCount] do
                  begin
                    Filename := pSections[iCount2];
                    Size := pIni.ReadInteger(Filename, 'Size', -1);
                    Checksum := pIni.ReadString(Filename, 'Checksum', '');

                    if pIni.ValueExists(Filename, 'ResName') then
                    begin
                      Mode := gfmResName;
                      setlength(Extras, 1);
                      Extras[0] := pIni.ReadString(Filename, 'ResName', '');
                    end
                    else if pIni.ValueExists(Filename, 'Hunks') then
                    begin
                      pHunks := TStringList.Create;
                      try
                        pHunks.CommaText := pIni.ReadString(Filename, 'Hunks', '');

                        pHunkList.AddStrings(pHunks);

                        setlength(Extras, pHunks.Count);
                        for iCount3 := 0 to pHunks.Count - 1 do
                          Extras[iCount3] := pHunks[iCount3];
                      finally
                        pHunks.Free;
                      end;
                      Mode := gfmHunks;
                    end
                    else
                      Mode := gfmVerify;
                    Checksum := pIni.ReadString(Filename, 'Checksum', '');
                  end;

                  inc(iCurrentFileCount);
                end;
              finally
                pSections.Free;
              end;
            end;
          finally
            pIni.Free;
          end;
        finally
          pFile.Free;
        end;
      end;

      setlength(AllFiles, pAllFiles.Count);
      for iCount := 0 to pAllFiles.Count - 1 do
        AllFiles[iCount] := pAllFiles[iCount];

    finally
      pAllFiles.Free;
    end;
    setlength(AllHunks, pHunkList.Count);

    for iCount := 0 to pHunkList.Count - 1 do
    begin
      pFile := TResourceStream.Create(hInstance, pHunkList[iCount], 'HUNK');
      try
        if pFile.Size = 0 then
          raise Exception.Create('Couldn''t open hunk ' + pHunkList[iCount] + '!');
        pIni := TMemIniFile.Create(pFile);
        try
          AllHunks[iCount].Name := pIni.ReadString('Options', 'Name', '');
          AllHunks[iCount].Original := ReadHexSection(pIni, 'Original');
          AllHunks[iCount].Modified := ReadHexSection(pIni, 'Modified');
          AllHunks[iCount].RealName := pHunkList[iCount];
        finally
          pIni.Free;
        end;
      finally
        pFile.Free
      end;
    end;
  finally
    pHunkList.Free;
  end;
end;

end.
