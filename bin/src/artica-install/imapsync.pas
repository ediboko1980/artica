unit imapsync;

{$MODE DELPHI}
{$LONGSTRINGS ON}

interface

uses
    Classes, SysUtils,variants,strutils, Process,logs,unix,
    RegExpr in '/home/dtouzeau/developpement/artica-postfix/bin/src/artica-install/RegExpr.pas',
    zsystem in '/home/dtouzeau/developpement/artica-postfix/bin/src/artica-install/zsystem.pas';


  type
  timapsync=class


private
     LOGS:Tlogs;
     artica_path:string;
     SYS:Tsystem;


public
    procedure   Free;
    constructor Create(const zSYS:Tsystem);
    function  BIN_PATH():string;
    function  VERSION():string;
    function  MAILSYNC_VERSION():string;
    function  MAILSYNC_BIN_PATH():string;


END;

implementation

constructor timapsync.Create(const zSYS:Tsystem);
begin
       forcedirectories('/etc/artica-postfix');
       LOGS:=tlogs.Create();
       SYS:=zSYS;



       if not DirectoryExists('/usr/share/artica-postfix') then begin
              artica_path:=ParamStr(0);
              artica_path:=ExtractFilePath(artica_path);
              artica_path:=AnsiReplaceText(artica_path,'/bin/','');

      end else begin
          artica_path:='/usr/share/artica-postfix';
      end;
end;
//##############################################################################
procedure timapsync.free();
begin
    logs.Free;
end;
//##############################################################################
function timapsync.BIN_PATH():string;
begin
    if FileExists('/usr/bin/imapsync') then exit('/usr/bin/imapsync');
end;
//#############################################################################
function timapsync.MAILSYNC_BIN_PATH():string;
begin
if FileExists('/usr/local/bin/mailsync') then exit('/usr/local/bin/mailsync');
if FileExists('/usr/bin/mailsync') then exit('/usr/bin/mailsync');
end;
//#############################################################################
function timapsync.MAILSYNC_VERSION():string;
var
   F:TstringList;
   t:string;
   i:integer;
   RegExpr:TRegExpr;
   D:boolean;
begin
 D:=false;
   if ParamStr(1)='--mailsync-status' then d:=true;
   t:=logs.FILE_TEMP();
   if not FileExists(MAILSYNC_BIN_PATH()) then begin
      logs.Debuglogs('MAILSYNC_VERSION:: unable to stat bin path (probably not installed)');
      exit();
   end;
   fpsystem(MAILSYNC_BIN_PATH() + ' --help >' + t + ' 2>&1');
   if not FileExists(t) then begin
      logs.Debuglogs('MAILSYNC_VERSION:: unable to stat '+t);
      exit;
   end;

   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='^mailsync\s+([0-9\.]+)';

   F:=TstringList.Create;
   F.LoadFromFile(t);

   for i:=0 to F.Count-1 do begin
       if RegExpr.Exec(F.Strings[i]) then begin
          result:=RegExpr.Match[1];
          break;
       end else begin
          if D then logs.Debuglogs(F.Strings[i]+' :NO MATCH :'+RegExpr.Expression);
       end;
   end;
   logs.DeleteFile(t);
   RegExpr.free;
   F.Free;
end;
//#############################################################################


function timapsync.VERSION():string;
var
   F:TstringList;
   t:string;
   i:integer;
   RegExpr:TRegExpr;
   D:boolean;
begin
   D:=false;
   if ParamStr(1)='--mailsync-status' then d:=true;
   t:=logs.FILE_TEMP();
   if not FileExists(BIN_PATH()) then exit();
   fpsystem(BIN_PATH() + ' --help >' + t + ' 2>&1');
   if not FileExists(t) then exit;

   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='imapsync,v\s+([0-9\.]+)';

   F:=TstringList.Create;
   F.LoadFromFile(t);
   for i:=0 to F.Count-1 do begin
       if RegExpr.Exec(F.Strings[i]) then begin
          result:=RegExpr.Match[1];
          break;
       end else begin
          if D then logs.Debuglogs(F.Strings[i]+' :NO MATCH :'+RegExpr.Expression);
       end;
   end;
   logs.DeleteFile(t);
   RegExpr.free;
   F.Free;
end;
//#############################################################################

end.

