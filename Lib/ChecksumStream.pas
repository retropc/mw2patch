unit ChecksumStream;

interface

uses
  Classes, MD5;
  
type
  TNullStream = class(TStream)
  public
    function Write(const ABuffer; Count: Longint): Longint; override;
    function Read(var ABuffer; Count: Longint): Longint; override;
    function Seek(Offset: Longint; Origin: word): Longint; override;
  end;

  TChecksumStream = class(TStream)
  private
    FSourceStream: TStream;
    FContext: MD5Context;
    function GetChecksum: string;
  public
    constructor Create(const ASourceStream: TStream);
    function Write(const ABuffer; Count: Longint): Longint; override;
    function Read(var ABuffer; Count: Longint): Longint; override;
    function Seek(Offset: Longint; Origin: word): Longint; override;
  published
    property Checksum: string read GetChecksum;
  end;

implementation

uses
  SysUtils;

{ TChecksumStream }

constructor TChecksumStream.Create(const ASourceStream: TStream);
begin
  FSourceStream := ASourceStream;
  MD5Init(FContext);
end;

function TChecksumStream.GetChecksum: string;
var
  ssDigest: MD5Digest;
begin
  MD5Final(FContext, ssDigest);
  Result := Md5Print(ssDigest);
end;

function TChecksumStream.Read(var ABuffer; Count: Integer): Longint;
var
  pBuffeR: Pointer;
begin
  Result := FSourceStream.Read(ABuffer, Count);
  pBuffer := Pointer(@ABuffer);
  MD5Update(FContext, pBuffer, Result);
end;

function TChecksumStream.Seek(Offset: Integer; Origin: word): Longint;
begin
  Result := FSourceStream.Seek(Offset, Origin);
end;

function TChecksumStream.Write(const ABuffer; Count: Integer): Longint;
begin
  raise Exception.Create('Cannot write.');
end;

{ TNullStream }

function TNullStream.Read(var ABuffer; Count: Integer): Longint;
begin
  Result := Count;
end;

function TNullStream.Seek(Offset: Integer; Origin: word): Longint;
begin
  Result := 0;
end;

function TNullStream.Write(const ABuffer; Count: Integer): Longint;
begin
  Result := Count;
end;

end.
