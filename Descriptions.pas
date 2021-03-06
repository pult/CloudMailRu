unit Descriptions;

{Simple && read-only descript.ion files support}
interface

uses
	System.Types, System.Classes, System.StrUtils, Generics.Collections, System.SysUtils, System.WideStrUtils;

type

	TDescription = class

	private
	var
		items: TDictionary<WideString, WideString>;
		ion_filename: WideString;
		function GetionFilename: WideString;

	public
		constructor Create(ion_filename: WideString);
		destructor Destroy; override;
		function Read(): integer;
		function GetValue(item: WideString): WideString;
		procedure Clear;
		function DetermineEncoding(): TEncoding;
		property ionFilename: WideString read GetionFilename;
	end;

implementation

{TDescription}

procedure TDescription.Clear;
begin
	self.items.Clear;
end;

constructor TDescription.Create(ion_filename: WideString);
begin
	self.items := TDictionary<WideString, WideString>.Create;
	self.ion_filename := ion_filename;
end;

destructor TDescription.Destroy;
begin
	self.items.Free;
end;

function TDescription.DetermineEncoding(): TEncoding;
var
	F: File;
	Buffer: array [0 .. 2] of byte;
begin
	AssignFile(F, ion_filename);
	Reset(F, 1);
	BlockRead(F, Buffer, SizeOf(Buffer));
	CloseFile(F);
	if (Buffer[0] = $EF) and (Buffer[1] = $BB) and (Buffer[2] = $BF) then exit(TEncoding.UTF8);
	if (Buffer[0] = $FE) and (Buffer[1] = $FF) then exit(TEncoding.BigEndianUnicode);
	if (Buffer[0] = $FF) and (Buffer[1] = $FE) then exit(TEncoding.Unicode);
	exit(TEncoding.Default);
end;

function TDescription.GetionFilename: WideString;
begin
	result := self.ion_filename;
end;

function TDescription.GetValue(item: WideString): WideString;
begin
	if not(items.TryGetValue(item, result)) then exit('');

	result := WideStringReplace(WideStringReplace(result, '\n', '  ', [rfReplaceAll]), chr($04) + '�', '', [rfReplaceAll]);
end;

function TDescription.Read(): integer;
var
	fStream: TStreamReader;
	line, key, value: WideString;
	t: integer;
begin
	result := 0; //not used
	self.Clear;
	fStream := nil;
	try
		fStream := TStreamReader.Create(self.ion_filename, DetermineEncoding(), False);
		while not fStream.EndOfStream do
		begin
			line := fStream.ReadLine;
			if StartsStr('"', line) then
			begin
				t := PosEx('" ', line);
				value := copy(line, t + 2, length(line));
				key := copy(line, 2, t - 2);
			end else begin
				t := PosEx(' ', line);
				value := copy(line, t + 1, length(line));
				key := copy(line, 0, t - 1);
			end;

			items.Add(key, value);
		end;
	except
		fStream.Free;
		exit(-1);
	end;
	fStream.Free;
end;


end.
