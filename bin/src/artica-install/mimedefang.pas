unit mimedefang;

{$MODE DELPHI}
{$LONGSTRINGS ON}

interface

uses
    Classes, SysUtils,variants,strutils,IniFiles, Process,logs,unix,RegExpr in 'RegExpr.pas',zsystem;

type LDAP=record
      admin:string;
      password:string;
      suffix:string;
      servername:string;
      Port:string;
  end;

  type
  tmimedefang=class


private
     LOGS:Tlogs;
     SYS:TSystem;
     artica_path:string;
     function Maillog_path():string;
     function BuildCommandline():string;
     procedure ETC_DEFAULT_PERFORMANCES();
     procedure SET_ETC_DEFAULT(key:string;value:string);
public
    procedure   Free;
    constructor Create(const zSYS:Tsystem);
    procedure   MIMEDEFANG_START();
    procedure   ETC_DEFAULT();
    function    INITD():string;
    function    SOCKET_PATH():string;
    procedure   MIMEDEFANG_STOP();
    function    mimedefang_PID():string;
    function    mimedefangmx_PID():string;
    function    MIMEDEFANG_STATUS():string;
    procedure   CHANGE_INIT_TO_POSTFIX();
    function    BIN_PATH():string;
    function    DAEMON_VERSION():string;
    procedure   GRAPHDEFANG_SETTINGS();
    function    Graphdefang_path():string;
    function    MULTIPLEXOR_PATH():string;
    function    CONF_PATH():string;
    procedure   GRAPHDEFANG_GEN();
    function    ETC_DEFAULT_PATH():string;
    function    READ_CONF(key:string):string;
END;

implementation

constructor tmimedefang.Create(const zSYS:Tsystem);
begin
       forcedirectories('/etc/artica-postfix');
       LOGS:=tlogs.Create();
       SYS:=Zsys;


       if not DirectoryExists('/usr/share/artica-postfix') then begin
              artica_path:=ParamStr(0);
              artica_path:=ExtractFilePath(artica_path);
              artica_path:=AnsiReplaceText(artica_path,'/bin/','');

      end else begin
          artica_path:='/usr/share/artica-postfix';
      end;
end;
//##############################################################################
procedure tmimedefang.free();
begin
    logs.Free;
end;
//##############################################################################
function tmimedefang.INITD():string;
begin
   if FileExists('/etc/init.d/mimedefang') then exit('/etc/init.d/mimedefang');
end;
//##############################################################################
function tmimedefang.SOCKET_PATH():string;
begin
    if FileExists('/var/spool/MIMEDefang/mimedefang.sock') then exit('/var/spool/MIMEDefang/mimedefang.sock');
    exit('/var/spool/MIMEDefang/mimedefang.sock');
end;
//##############################################################################
function tmimedefang.mimedefang_PID():string;
begin
if FileExists('/var/spool/MIMEDefang/mimedefang.pid') then exit(SYS.GET_PID_FROM_PATH('/var/spool/MIMEDefang/mimedefang.pid'));
end;
//##############################################################################
function tmimedefang.mimedefangmx_PID():string;
begin
if FileExists('/var/spool/MIMEDefang/mimedefang-multiplexor.pid') then exit(SYS.GET_PID_FROM_PATH('/var/spool/MIMEDefang/mimedefang-multiplexor.pid'));
end;
//##############################################################################
function tmimedefang.Graphdefang_path():string;
begin
if FileExists('/usr/bin/graphdefang.pl') then exit('/usr/bin/graphdefang.pl');
end;
//##############################################################################
function tmimedefang.MULTIPLEXOR_PATH():string;
begin
    if FileExists('/usr/bin/mimedefang-multiplexor') then exit('/usr/bin/mimedefang-multiplexor');
end;
//##############################################################################

function tmimedefang.Maillog_path():string;
var filedatas,logconfig,ExpressionGrep:string;
RegExpr:TRegExpr;
begin
if FileExists('/var/log/mail.log') then exit('/var/log/mail.log');
if FileExists('/etc/syslog.conf') then logconfig:='/etc/syslog.conf';
if FileExists('/etc/syslog-ng/syslog-ng.conf') then logconfig:='/etc/syslog-ng/syslog-ng.conf';
if FileExists('/etc/rsyslog.conf') then logconfig:='/etc/rsyslog.conf';

filedatas:=SYS.ReadFileIntoString(logconfig);
   ExpressionGrep:='mail\.=info.+?-([\/a-zA-Z_0-9\.]+)?';
   RegExpr:=TRegExpr.create;
   RegExpr.ModifierI:=True;
   RegExpr.expression:=ExpressionGrep;
   if RegExpr.Exec(filedatas) then  begin
     result:=RegExpr.Match[1];
     RegExpr.Free;
     exit;
   end;


   ExpressionGrep:='mail\.\*.+?-([\/a-zA-Z_0-9\.]+)?';
   RegExpr.expression:=ExpressionGrep;
   if RegExpr.Exec(filedatas) then   begin
     result:=RegExpr.Match[1];
     RegExpr.Free;
     exit;
   end;

   ExpressionGrep:='destination mailinfo[\s\{a-z]+\("(.+?)"';
   RegExpr.expression:=ExpressionGrep;
   if RegExpr.Exec(filedatas) then   begin
     result:=RegExpr.Match[1];
     RegExpr.Free;
     exit;
   end;

  RegExpr.Free;
end;
//##############################################################################
procedure tmimedefang.GRAPHDEFANG_GEN();
var
   update:boolean;
   l:TstringList;
   cmd:string;
begin
  update:=false;
  if not FileExists(Graphdefang_path()) then exit;
  
  if not FileExists('/etc/artica-postfix/graphdefang.touch') then begin
     update:=true;
  end else begin
      if SYS.FILE_TIME_BETWEEN_MIN('/etc/artica-postfix/graphdefang.touch')>120 then update:=True;
  end;
  
  if not update then exit;
  GRAPHDEFANG_SETTINGS();
  fpsystem('/bin/rm -f /etc/artica-postfix/graphdefang.touch >/dev/null');
  l:=TstringList.Create;
  l.Add('#');
  l.SaveToFile('/etc/artica-postfix/graphdefang.touch');
  cmd:=Graphdefang_path() + ' --file ' + Maillog_path() + ' --quiet';
  logs.Debuglogs('GRAPHDEFANG_GEN():: ' + cmd);
  fpsystem(cmd);

end;
//##############################################################################
function tmimedefang.ETC_DEFAULT_PATH():string;
begin
if FileExists('/etc/default/mimedefang') then exit('/etc/default/mimedefang');
if FileExists('/etc/sysconfig/mimedefang') then exit('/etc/sysconfig/mimedefang');
end;
//##############################################################################
function tmimedefang.READ_CONF(key:string):string;
var
   l:TstringList;
   RegExpr:TRegExpr;
   i:integer;
begin
if not FileExists(ETC_DEFAULT_PATH()) then exit;
RegExpr:=TRegExpr.Create;
RegExpr.Expression:='^'+key+'=(.+)';
l:=TstringList.Create;
l.LoadFromFile(ETC_DEFAULT_PATH());
for i:=0 to l.Count-1 do begin
    if RegExpr.Exec(l.Strings[i]) then begin
       result:=trim(RegExpr.Match[1]);
       break;
    end;
end;

l.free;
RegExpr.free;
end;
//##############################################################################
procedure tmimedefang.ETC_DEFAULT_PERFORMANCES();
var
ini:TiniFile;
sections:TstringList;
i:integer;
begin
   if not FileExists('/etc/artica-postfix/performances.conf') then exit;
   
   
   ini:=TiniFile.Create('/etc/artica-postfix/performances.conf');
   sections:=TstringList.Create;
   logs.Debuglogs('Starting......: Mimedefang settings performances values...');
   ini.ReadSection('MIMEDEFANG',sections);
   for i:=0 to sections.Count-1 do begin
        if length(sections.Strings[i])>0 then begin
           logs.Debuglogs('Starting......: MimeDefang change ' + sections.Strings[i] + ' daemon parameter..');
           SET_ETC_DEFAULT(sections.Strings[i],ini.ReadString('MIMEDEFANG',sections.Strings[i],''));
        end;
   end;
   

end;
//##############################################################################
procedure tmimedefang.SET_ETC_DEFAULT(key:string;value:string);
var
   l:TstringList;
   RegExpr:TRegExpr;
   i:integer;
   f:boolean;
begin
   if length(value)=0 then exit;
   if not FileExists(ETC_DEFAULT_PATH()) then exit;
   l:=TstringList.create;
   l.LoadFromFile(ETC_DEFAULT_PATH());
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='^'+key;
   f:=false;
   for i:=0 to l.Count-1 do begin
      if  RegExpr.Exec(l.Strings[i]) then begin
          l.Strings[i]:=key+'='+value;
          break;
          f:=true;
      end;
  end;
  
  if not f then begin
     l.Add(key+'='+value);
  end;
  
  l.SaveToFile(ETC_DEFAULT_PATH());
   
   

end;
//##############################################################################

procedure tmimedefang.ETC_DEFAULT();
var
l:TstringList;
begin

if not FileExists(ETC_DEFAULT_PATH()) then exit;
l:=TstringList.Create;
l.Add('# Mimedefang configuration file');
l.Add('# This file is read by the init script');
l.Add('# See /etc/init.d/mimedefang');
l.Add('');
l.Add('# The socket used by mimedefang to communicate with sendmail');
l.Add('SOCKET=$SPOOLDIR/mimedefang.sock');
l.Add('');
l.Add('# Run the multiplexor and filters as this user, not root.  RECOMMENDED');
l.Add('MX_USER=postfix');
l.Add('');
l.Add('# Syslog facility');
l.Add('# SYSLOG_FACILITY=mail');
l.Add('');
l.Add('# If you want to keep spool directories around if the filter fails,');
l.Add('# set the next one to yes');
l.Add('# KEEP_FAILED_DIRECTORIES=no');
l.Add('');
l.Add('# "yes" turns on the multiplexor relay checking function');
l.Add('# MX_RELAY_CHECK=no');
l.Add('');
l.Add('# "yes" turns on the multiplexor HELO checking function');
l.Add('# MX_HELO_CHECK=no');
l.Add('');
l.Add('# "yes" turns on the multiplexor sender checking function');
l.Add('# MX_SENDER_CHECK=no');
l.Add('');
l.Add('# "yes" turns on the multiplexor recipient checking function');
l.Add('MX_RECIPIENT_CHECK=yes');
l.Add('');
l.Add('# Set to yes if you want the multiplexor to log events to syslog');
l.Add('MX_LOG=yes');
l.Add('');
l.Add('# Set to yes if you want to use an embedded Perl interpreter');
l.Add('MX_EMBED_PERL=yes');
l.Add('');
l.Add('# Set to full path of socket for Sendmail''s SOCKETMAP map, if you');
l.Add('# want to use it with MIMEDefang');
l.Add('# MX_MAP_SOCKET=$SPOOLDIR/map.sock');
l.Add('');
l.Add('# The multiplexor does not start all slaves at the same time.  Instead,');
l.Add('# it starts one slave every MX_SLAVE_DELAY seconds when the system is idle.');
l.Add('# (If the system is busy, the multiplexor starts slaves as incoming mail');
l.Add('# requires attention.)');
l.Add('# MX_SLAVE_DELAY=3');
l.Add('');
l.Add('# The next setting is an absolute limit on slave activation.  The multiplexor');
l.Add('# will NEVER activate a slave within MX_MIN_SLAVE_DELAY seconds of another.');
l.Add('# The default of zero means that the multiplexor will activate slaves as');
l.Add('# quickly as necessary to keep up with incoming mail.');
l.Add('# MX_MIN_SLAVE_DELAY=0');
l.Add('');
l.Add('# Set to yes if you want the multiplexor to log stats in');
l.Add('# /var/log/mimedefang/stats  The /var/log/mimedefang directory must');
l.Add('# exist and be writable by the user you''re running MIMEDefang as.');
l.Add('MX_STATS=yes');
l.Add('');
l.Add('# Number of slaves reserved for connections from loopback.  Use -1');
l.Add('# for default behaviour, 0 to allow loopback connections to queue,');
l.Add('# or >0 to reserve slaves for loopback connections');
l.Add('LOOPBACK_RESERVED_CONNECTIONS=-1');
l.Add('');
l.Add('# If you want new connections to be allowed to queue, set the');
l.Add('# next variable to yes.  Normally, only existing connections are');
l.Add('# allowed to queue requests for work.');
l.Add('ALLOW_NEW_CONNECTIONS_TO_QUEUE=no');
l.Add('');
l.Add('# Set to yes if you want the stats file flushed after each entry');
l.Add('# MX_FLUSH_STATS=no');
l.Add('');
l.Add('# Set to yes if you want the multiplexor to log stats to syslog');
l.Add('# MX_STATS_SYSLOG=yes');
l.Add('');
l.Add('# The socket used by the multiplexor');
l.Add('# MX_SOCKET=$SPOOLDIR/mimedefang-multiplexor.sock');
l.Add('');
l.Add('# Maximum # of requests a process handles');
l.Add('# MX_REQUESTS=200');
l.Add('');
l.Add('# Minimum number of processes to keep.  The default of 0 is probably');
l.Add('# too low; we suggest 2 instead.');
l.Add('# MX_MINIMUM=2');
l.Add('');
l.Add('# Maximum number of processes to run (mail received while this many');
l.Add('# processes are running is rejected with a temporary failure, so be');
l.Add('# wary of how many emails you receive at a time).  This applies only');
l.Add('# if you DO use the multiplexor.  The default value of 2 is probably');
l.Add('# too low; we suggest 10 instead');
l.Add('# MX_MAXIMUM=10');
l.Add('');
l.Add('# Uncomment to log slave status; it will be logged every');
l.Add('# MX_LOG_SLAVE_STATUS_INTERVAL seconds');
l.Add('# MX_LOG_SLAVE_STATUS_INTERVAL=30');
l.Add('');
l.Add('# Uncomment next line to have busy slaves send status updates to the');
l.Add('# multiplexor.  NOTE: Consumes one extra file descriptor per slave, plus');
l.Add('# a bit of CPU time.');
l.Add('# MX_STATUS_UPDATES=yes');
l.Add('');
l.Add('# Limit slave processes'' resident-set size to this many kilobytes.  Default');
l.Add('# is unlimited.');
l.Add('# MX_MAX_RSS=10000');
l.Add('');
l.Add('# Limit total size of slave processes'' memory space to this many kilobytes.');
l.Add('# Default is unlimited.');
l.Add('# MX_MAX_AS=30000');
l.Add('');
l.Add('# If you want to use the "notification" facility, set the appropriate port.');
l.Add('# See the mimedefang-notify man page for details.');
l.Add('# MX_NOTIFIER=inet:4567');
l.Add('');
l.Add('# Number of seconds a process should be idle before checking for');
l.Add('# minimum number and killed');
l.Add('# MX_IDLE=300');
l.Add('');
l.Add('# Number of seconds a process is allowed to scan an email before it is');
l.Add('# considered dead.  The default is 30 seconds; we suggest 300.');
l.Add('# MX_BUSY=300');
l.Add('');
l.Add('# Extra sendmail macros to pass.  Actually, you can add any extra');
l.Add('# mimedefang options here...');
l.Add('# MD_EXTRA="-a auth_author"');
l.Add('');
l.Add('# Multiplexor queue size -- default is 0 (no queueing)');
l.Add('# MX_QUEUE_SIZE=10');
l.Add('');
l.Add('# Multiplexor queue timeout -- default is 30 seconds');
l.Add('# MX_QUEUE_TIMEOUT=30');
l.Add('');
l.Add('# Set to yes if you don''t want MIMEDefang to see invalid recipients.');
l.Add('# Only works with Sendmail 8.14.0 and later.');
l.Add('# MD_SKIP_BAD_RCPTS=no');
l.Add('');
l.Add('# SUBFILTER specifies which filter rules file to use');
l.Add('# SUBFILTER=/etc/mimedefang-filter');
l.Add('');
l.Add('# The contents of the "X-Scanned-By" header added to each mail.  Do');
l.Add('# not use the quote mark ('') in this setting.  Setting it to "-"');
l.Add('# prevents the header from getting added at all.');
l.Add('X_SCANNED_BY="MIMEDefang N.NN (www . roaringpenguin . com / mimedefang)"');
logs.Debuglogs('Starting......: MimeDefang Saving daemon parameters..');
l.SaveToFile(ETC_DEFAULT_PATH());
l.free;
end;
//##############################################################################
function tmimedefang.BIN_PATH():string;
begin
if FileExists('/usr/bin/mimedefang') then exit('/usr/bin/mimedefang');
end;
//##############################################################################
function tmimedefang.CONF_PATH():string;
begin
if FileExists('/etc/mail/mimedefang-filter') then exit('/etc/mail/mimedefang-filter');
end;


function tmimedefang.MIMEDEFANG_STATUS():string;
var
ini:TstringList;
MimeDefangEnabled:integer;
begin
   MimeDefangEnabled:=0;
   if FileExists(BIN_PATH()) then  exit;
   if not TryStrToInt(SYS.GET_INFO('MimeDefangEnabled'),MimeDefangEnabled) then MimeDefangEnabled:=0;
   ini:=TstringList.Create;
   ini.Add('[MIMEDEFANG]');
   if FileExists(BIN_PATH()) then  begin
      if SYS.PROCESS_EXIST(mimedefang_PID()) then ini.Add('running=1') else  ini.Add('running=0');
      ini.Add('application_installed=1');
      ini.Add('master_pid='+ mimedefang_PID());
      ini.Add('master_memory=' + IntToStr(SYS.PROCESS_MEMORY(mimedefang_PID())));
      ini.Add('master_version='+DAEMON_VERSION());
      ini.Add('status='+SYS.PROCESS_STATUS(mimedefang_PID()));
      ini.Add('service_name=APP_MIMEDEFANG');
      ini.Add('service_cmd=mimedefang');
      ini.Add('service_disabled='+IntToStr(MimeDefangEnabled));
      ini.Add('pid_path=/var/spool/MIMEDefang/mimedefang.pid');
      
    ini.Add('[MIMEDEFANGX]');
      if SYS.PROCESS_EXIST(mimedefangmx_PID()) then ini.Add('running=1') else  ini.Add('running=0');
      ini.Add('application_installed=1');
      ini.Add('master_pid='+ mimedefangmx_PID());
      ini.Add('master_memory=' + IntToStr(SYS.PROCESS_MEMORY(mimedefangmx_PID())));
      ini.Add('master_version='+DAEMON_VERSION());
      ini.Add('status='+SYS.PROCESS_STATUS(mimedefangmx_PID()));
      ini.Add('service_name=APP_MIMEDEFANGX');
      ini.Add('service_cmd=mimedefang');
      ini.Add('service_disabled='+IntToStr(MimeDefangEnabled));


      
   end;

   result:=ini.Text;
   ini.free;

end;
//##############################################################################
procedure tmimedefang.CHANGE_INIT_TO_POSTFIX();
var
    RegExpr:TRegExpr;
    FileDatas:TStringList;
    i:integer;
begin
 if not FileExists(INITD()) then exit;
 FileDatas:=TstringList.Create;
 FileDatas.LoadFromFile(INITD());
 RegExpr:=TRegExpr.Create;
 RegExpr.Expression:='^MX_USER=.+';
 for i:=0 to FileDatas.Count-1 do begin
     if RegExpr.Exec(FileDatas.Strings[i]) then begin
         FileDatas.Strings[i]:='MX_USER=postfix';
         FileDatas.SaveToFile(INITD());
         break;
     end;

 end;
         FileDatas.Free;
         RegExpr.Free;

end;
//##############################################################################
procedure tmimedefang.GRAPHDEFANG_SETTINGS();
var
    RegExpr:TRegExpr;
    FileDatas:TStringList;
    maillog:string;
    i:integer;
begin
 if not FileExists('/etc/graphdefang/graphdefang-config') then exit;
 
 forcedirectories('/opt/artica/share/www/graphdefang');
 
 maillog:=Maillog_path();
 
 FileDatas:=TstringList.Create;
 FileDatas.LoadFromFile('/etc/graphdefang/graphdefang-config');
 RegExpr:=TRegExpr.Create;

 for i:=0 to FileDatas.Count-1 do begin
     RegExpr.Expression:='^\$DATAFILE';
     if RegExpr.Exec(FileDatas.Strings[i]) then begin
         FileDatas.Strings[i]:='$DATAFILE="' + maillog + '";';
         logs.Debuglogs('GRAPHDEFANG_SETTINGS::$DATAFILE="var/log/mail.log" in  /etc/graphdefang/graphdefang-config');
     end;
     
     RegExpr.Expression:='^\$OUTPUT_DIR';
     if RegExpr.Exec(FileDatas.Strings[i]) then begin
         FileDatas.Strings[i]:='$OUTPUT_DIR="/opt/artica/share/www/graphdefang";';
         logs.Debuglogs('GRAPHDEFANG_SETTINGS::$OUTPUT_DIR="/opt/artica/share/www/graphdefang" in  /etc/graphdefang/graphdefang-config');
     end;

 end;
 
FileDatas.SaveToFile('/etc/graphdefang/graphdefang-config');

if not FileExists('/usr/share/graphdefang/graphdefanglib.pl') then exit;
FileDatas.LoadFromFile('/usr/share/graphdefang/graphdefanglib.pl');
for i:=0 to FileDatas.Count-1 do begin
     RegExpr.Expression:='^my \$X_GRAPH_SIZE';
     if RegExpr.Exec(FileDatas.Strings[i]) then begin
         FileDatas.Strings[i]:='my $X_GRAPH_SIZE = 640;';
         logs.Debuglogs('GRAPHDEFANG_SETTINGS::$X_GRAPH_SIZE=640 in /usr/share/graphdefang/graphdefanglib.pl');
         FileDatas.SaveToFile('/usr/share/graphdefang/graphdefanglib.pl');
         break;
     end;
end;

FileDatas.Free;
RegExpr.Free;

end;
//##############################################################################




procedure tmimedefang.MIMEDEFANG_STOP();
var
   pid:string;

begin

    if not FileExists(INITD()) then exit;
    
    pid:=mimedefang_PID();
    
    if not SYS.PROCESS_EXIST(pid) then begin
       writeln('Stopping Mimedefang daemon....: Already stopped');
       pid:=trim(SYS.PROCESS_LIST_PID(MULTIPLEXOR_PATH()));
       if length(pid)>0 then begin
           writeln('Stopping multiplexor..........: ' + pid+ ' PID');
           fpsystem('/bin/kill ' + pid);

       end;
       
       
       pid:=trim(SYS.PROCESS_LIST_PID(BIN_PATH()));
       if length(pid)>0 then begin
           writeln('Stopping Mimedefang..........: ' + pid + ' PID');
           fpsystem('/bin/kill ' + pid);
       end;
       
       exit;
    end;
    writeln('Stopping Mimedefang..........: ' + mimedefang_PID() + ' PID');
    fpsystem(INITD() + ' stop >/dev/null 2>&1');


    if SYS.PROCESS_EXIST(mimedefang_PID()) then begin
        writeln('Stopping mimedefang daemon ' + mimedefang_PID() + ' PID (failed to stop)');
        exit;
    end;
end;
//##############################################################################
procedure tmimedefang.MIMEDEFANG_START();
var
cmd:string;
MimeDefangEnabled:integer;
begin
    if not FileExists(INITD()) then exit;
    
    
if not TryStrToInt(SYS.GET_INFO('MimeDefangEnabled'),MimeDefangEnabled) then begin
   logs.Syslogs('MIMEDEFANG_START:: unable to understand "MimeDefangEnabled+" parameter');
   exit;
end;
    
    if SYS.PROCESS_EXIST(mimedefang_PID()) then begin
       logs.Debuglogs('MIMEDEFANG_START:: Mimedefang already running with pid '+mimedefang_PID());
        if MimeDefangEnabled=0 then begin
           logs.Debuglogs('MIMEDEFANG_START:: Mimedefang is disabled, stop it');
           MIMEDEFANG_STOP();
        end;
       exit;
    end;
    
    
    if MimeDefangEnabled=0 then begin
        logs.Debuglogs('MIMEDEFANG_START:: Mimedefang is disabled');
        exit;
    end;
    
    logs.Debuglogs('MIMEDEFANG_START:: default configuration path '+ETC_DEFAULT_PATH());



    
    if FileExists('/var/spool/MIMEDefang/mimedefang.pid') then logs.DeleteFile('/var/spool/MIMEDefang/mimedefang.pid');

    logs.Debuglogs('Starting......: Mimedefang');
    ETC_DEFAULT();
    ETC_DEFAULT_PERFORMANCES();
    CHANGE_INIT_TO_POSTFIX();
    GRAPHDEFANG_SETTINGS();
    forcedirectories('/var/spool/MIMEDefang');
    forceDirectories('/var/spool/MIMEDefang/.spamassassin');
    if directoryExists('/var/spool/MIMEDefang') then SYS.FILE_CHOWN('postfix','postfix','/var/spool/MIMEDefang');
    
    forceDirectories('/var/log/mimedefang');
    SYS.FILE_CHOWN('postfix','postfix','/var/log/mimedefang');
    
    fpsystem(INITD() + ' start >/dev/null 2>&1');


    if not SYS.PROCESS_EXIST(mimedefang_PID()) then begin
        logs.Debuglogs('MIMEDEFANG_START:: Failed to start Mimedefang run in artica mode...');
        cmd:=BIN_PATH+ BuildCommandline();
        logs.OutputCmd(cmd);
    end;
    
    if not SYS.PROCESS_EXIST(mimedefang_PID()) then begin
       logs.Debuglogs('MIMEDEFANG_START:: Failed to start MimeDefang, please investigate');
    end;
    
end;
//#########################################################################################
function tmimedefang.BuildCommandline():string;
var
   LOOPBACK_RESERVED_CONNECTIONS:string;
//   MX_USER:string;
   SYSLOG_FACILITY:string;
   LOG_FILTER_TIME:string;
   MX_RELAY_CHECK:string;
   MX_HELO_CHECK:string;
   MD_EXTRA:string;
   ALLOW_NEW_CONNECTIONS_TO_QUEUE:string;
   MX_SENDER_CHECK:string;
   MX_RECIPIENT_CHECK:string;
  // KEEP_FAILED_DIRECTORIES:string;
   cmd:string;
begin
 LOOPBACK_RESERVED_CONNECTIONS:=READ_CONF('LOOPBACK_RESERVED_CONNECTIONS');
 //MX_USER:=READ_CONF('MX_USER');
 SYSLOG_FACILITY:=READ_CONF('SYSLOG_FACILITY');
 LOG_FILTER_TIME:=READ_CONF('LOG_FILTER_TIME');
 MX_RELAY_CHECK:=READ_CONF('MX_RELAY_CHECK');
 MX_HELO_CHECK:=READ_CONF('MX_HELO_CHECK');
 LOG_FILTER_TIME:=READ_CONF('LOG_FILTER_TIME');
 MX_SENDER_CHECK:=READ_CONF('MX_SENDER_CHECK');
 MX_RECIPIENT_CHECK:=READ_CONF('MX_RECIPIENT_CHECK');
 //KEEP_FAILED_DIRECTORIES:=READ_CONF('KEEP_FAILED_DIRECTORIES');
 MD_EXTRA:=READ_CONF('MD_EXTRA');
 ALLOW_NEW_CONNECTIONS_TO_QUEUE:=READ_CONF('ALLOW_NEW_CONNECTIONS_TO_QUEUE');
cmd:='';

 cmd:=cmd + ' -P /var/spool/MIMEDefang/mimedefang.pid -U postfix';
 if length(LOOPBACK_RESERVED_CONNECTIONS)>0 then cmd:=cmd+' -R '+LOOPBACK_RESERVED_CONNECTIONS;
 if length(SYSLOG_FACILITY)>0 then cmd:=cmd+' -S '+SYSLOG_FACILITY;
 if LOG_FILTER_TIME='yes' then     cmd:=cmd+' -T';
 if MX_RELAY_CHECK='yes' then      cmd:=cmd+' -r';
 if MX_HELO_CHECK='yes' then       cmd:=cmd+' -H';
 if MX_SENDER_CHECK='yes' then     cmd:=cmd+' -s';
 if MX_RECIPIENT_CHECK='yes' then  cmd:=cmd+' -t';
 if length(MD_EXTRA)>0 then cmd:=cmd+' '+MD_EXTRA;
 if ALLOW_NEW_CONNECTIONS_TO_QUEUE='yes' then  cmd:=cmd+' -q';
 cmd:=cmd + ' -p /var/spool/MIMEDefang/mimedefang.sock';
 cmd:=cmd + ' -m /var/spool/MIMEDefang/mimedefang-multiplexor.sock';
 result:=cmd;
end;
//#########################################################################################

function tmimedefang.DAEMON_VERSION():string;
var
    RegExpr:TRegExpr;
    FileDatas:TStringList;
    i:integer;
begin
if not FileExists(BIN_PATH()) then exit;
fpsystem(BIN_PATH()+' -v >/opt/artica/logs/clamav.tmp');
    RegExpr:=TRegExpr.Create;
    RegExpr.Expression:='mimedefang version\s+([0-9\.a-z]+)';
    FileDatas:=TStringList.Create;
    FileDatas.LoadFromFile('/opt/artica/logs/clamav.tmp');
    for i:=0 to FileDatas.Count-1 do begin
        if RegExpr.Exec(FileDatas.Strings[i]) then begin
             result:=RegExpr.Match[1];
             break;
        end;
    end;
             RegExpr.free;
             FileDatas.Free;

end;
//#########################################################################################
end.
