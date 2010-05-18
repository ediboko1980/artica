program artica_install;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils,class_install,zsystem,artica_menus,
  global_conf in '/home/dtouzeau/developpement/artica-postfix/bin/src/artica-install/global_conf.pas',
  postfix_addons,debian,
  process_infos in '/home/dtouzeau/developpement/artica-postfix/bin/src/artica-install/process_infos.pas',
  BaseUnix,unix,postfix_standard,RegExpr in 'RegExpr.pas',dos;

var
   install:Tclass_install;
   GLOBAL_INI:myconf;
   deb:TDebian;
   PRC:Tprocessinfos;
   POSTFIX:Tpostfix_standard;
   POSTFIX_ADDON:Tpostfix_addon;
   zMENUS:Tmenus;
   REGEX:TRegExpr;
   s:string;
   list:TstringList;
   i:integer;
   status:boolean;
   SYS:Tsystem;
   
function IsRoot():boolean;
begin
if FpGetEUid=0 then exit(true);
exit(false);
end;


 begin

 REGEX:=TRegExpr.Create;
 s:='';

 if IsRoot=false then begin
 writeln('You need to be root to execute this program...');
 halt(0);
 end;

 if ParamCount>1 then begin
     for i:=2 to ParamCount do begin
        s:=s  + ' ' +ParamStr(i);

     end;
 end;

     install:=Tclass_install.Create();
     if install.IsRoot()=false then begin
         writeln('This program must run as root');
         halt(0);
     end;
     
//##############################################################################
    if paramStr(1)='slapd' then begin
          GLOBAL_INI:=MyConf.Create();
         if paramStr(2)='start' then begin
              GLOBAL_INI.LDAP_START();
              halt(0);
          end;

         if paramStr(2)='stop' then begin
              GLOBAL_INI.LDAP_STOP();
              halt(0);
          end;
          
         if paramStr(2)='restart' then begin
              writeln('restart slapd');
              GLOBAL_INI.LDAP_STOP();
              GLOBAL_INI.LDAP_START();
              halt(0);
          end;
          
          writeln('Usage: ' + ExtractFilePath(ParamStr(0)) + 'artica-install slapd {start|stop|restart}');
          halt(0);
    end;
//##############################################################################

  if ParamStr(1)='-postfix-service' then begin
        GLOBAL_INI.POSFTIX_VERIFY_MAINCF();
     if ParamStr(2)='restart' then begin
         writeln('Restarting....: Postfix daemon...');
        fpsystem('/usr/sbin/postfix stop >/dev/null 2>&1');
        fpsystem('/usr/sbin/postfix start >/dev/null 2>&1');
        halt(0);
     end;
     if ParamStr(2)='stop' then  writeln('stopping....: Postfix daemon...');
     fpsystem('/usr/sbin/postfix ' + ParamStr(2) + ' >/dev/null 2>&1');
     halt(0);
  end;
//##############################################################################

    if ParamStr(1)='-distri' then begin
        GLOBAL_INI:=MyConf.Create();
        writeln(GLOBAL_INI.LINUX_DISTRIBUTION());
        halt(0);
    end;
    
    if ParamStr(1)='-exim-remove' then begin
        GLOBAL_INI:=MyConf.Create();
        install.EXIM4_REMOVE();
        halt(0);
    end;
    

     
     
     install.DetectDistribution();

      if ParamStr(1)='setup' then begin
           zMENUS:=Tmenus.Create;
           zMenus.setup(false);
           halt(0);
      end;
      
      if  ParamStr(1)='-install-web-artica' then begin
          zMENUS:=Tmenus.Create;
           zMenus.ARTICA_WEB_INSTALL();
           halt(0);
      end;
      

      if ParamStr(1)='addons' then begin
           zMENUS:=Tmenus.Create;
           zMenus.addons_setup();
           halt(0);
      end;



      if ParamStr(1)='-install' then begin
         zMENUS:=Tmenus.Create();
         zMenus.setup(false);
         halt(0);
      end;



     if ParamStr(1)='-strip' then begin
            GLOBAL_INI:=MyConf.Create();
            GLOBAL_INI.set_FileStripDiezes(ParamStr(2));
            GLOBAL_INI.Free;
            halt(0);
     end;

     if ParamStr(1)='-upgrade' then begin
        fpsystem('/etc/init.d/artica-postfix stop');
        install.InstallArtica;
        fpsystem('/etc/init.d/artica-postfix start');
        halt(0);
     end;


     if ParamStr(1)='-userq' then begin
        list:=TStringList.Create;
        GLOBAL_INI:=MyConf.Create();
        list.LoadFromStream(GLOBAL_INI.ExecStream(GLOBAL_INI.get_ARTICA_PHP_PATH()+ '/bin/artica-filter lastten queue ' + trim(ParamStr(2)),false));
        for i:=0 to list.Count -1 do begin
        writeln(list.Strings[i]);
        end;
     halt(0)
     end;

     if ParamStr(1)='-enable-services' then begin
        writeln('Enable services...');
        install.EnableDaemonsAutoStart();
        writeln('Enable services done...');
        halt(0)
     end;

     if ParamStr(1)='-libc' then begin
        GLOBAL_INI:=myconf.Create;
        writeln('LIBC version:'+ GLOBAL_INI.SYSTEM_LIBC_VERSION());
        halt(0)
     end;



     if ParamStr(1)='-ip' then begin
        GLOBAL_INI:=MyConf.Create();
        writeln('IP:',GLOBAL_INI.GetIPInterface(ParamStr(2)));
        halt(0);
      end;

     if ParamStr(1)='-UTC' then begin
        GLOBAL_INI:=MyConf.Create();
        GLOBAL_INI.debug:=True;
        writeln('New:',GLOBAL_INI.RRDTOOL_SecondsBetween(s));
        halt(0);
     end;

   if ParamStr(1)='-check-befor' then begin
        deb:=TDebian.Create;
        deb.UpdateReposConfig();
        halt(0);
     end;

   if ParamStr(1)='-check-pack' then begin
        deb:=TDebian.Create;
        deb.CheckPackages();
        halt(0);
     end;


   if ParamStr(1)='-check-repos' then begin
        deb:=TDebian.Create;
        writeln(deb.ShowRepositories(''));
        halt(0);

     end;




     if ParamStr(1)='-dd' then begin
       GLOBAL_INI:=MyConf.Create();
       GLOBAL_INI.debug:=True;
       GLOBAL_INI.RRDTOOL_LOAD_AVERAGE();
       GLOBAL_INI.RDDTOOL_LOAD_CPU_GENERATE();
       GLOBAL_INI.RDDTOOL_LOAD_MEMORY_GENERATE();
       halt(0);
     end;

     if ParamStr(1)='-distri' then begin
        writeln('Distribution: ',install.LinuxInfosDistri());
        halt(0)
     end;

     if ParamStr(1)='-queuegraph' then begin
        GLOBAL_INI:=MyConf.Create();
        GLOBAL_INI.MAILGRAPH_RECONFIGURE();
        halt(0)
     end;

     if ParamStr(1)='-yorel' then begin
        if ParamStr(2)='install' then begin
           GLOBAL_INI:=MyConf.Create();
           GLOBAL_INI.YOREL_RECONFIGURE('');
           halt(0);
        end;
     end;

     if ParamStr(1)='-www' then begin
            GLOBAL_INI:=MyConf.Create();
            writeln('www root path=',GLOBAL_INI.get_www_root());
            GLOBAL_INI.Free;
            halt(0);
     end;

     if ParamStr(1)='-inet' then begin
            postfix_addon:=Tpostfix_addon.Create();
            GLOBAL_INI:=MyConf.Create();
            writeln('Inet interfaces detected : ',GLOBAL_INI.get_LINUX_INET_INTERFACES());
            postfix_addon.inet_interfaces();
            GLOBAL_INI.Free;
            halt(0);
     end;
//##############################################################################
 if ParamStr(1)='-emailrelay' then begin
          if ParamStr(2)='clean' then begin
             GLOBAL_INI:=MyConf.Create();
             GLOBAL_INI.ARTICA_FILTER_CLEAN_QUEUE();
             halt(0);
          end;
     zMENUS:=Tmenus.Create;
     zMENUS.HELP_EMAILRELAY();
  end;

   if ParamStr(1)='-tls' then begin
            postfix_addon:=Tpostfix_addon.Create();
            postfix_addon.SetLogout();
            postfix_addon.ConfigTLS();
            halt(0);
     end;
//##############################################################################
     if ParamStr(1)='-shutdown' then begin
            writeln('Shutdown artica-postfix daemon...');
            GLOBAL_INI:=MyConf.Create();
            PRC:=Tprocessinfos.Create;
            if ParamStr(2)='force' then begin
               GLOBAL_INI.ARTICA_STOP();
               GLOBAL_INI.ARTICA_STOP();
               GLOBAL_INI.ARTICA_STOP();
               PRC.AutoKill(true);
               sleep(100);
               GLOBAL_INI.ARTICA_STOP();
               PRC.AutoKill(true);
               halt(0);
            end;
            
              if ParamStr(2)='ldap' then begin
                 GLOBAL_INI.ARTICA_STOP();
                 GLOBAL_INI.LDAP_STOP();
                 halt(0);
              end;
              
             if ParamStr(2)='imap' then begin
                 GLOBAL_INI.CYRUS_DAEMON_STOP();
                 halt(0);
              end;
              
            if ParamStr(2)='kav6' then begin
                 GLOBAL_INI.KAV6_STOP();
                 halt(0);
              end;
              
            if ParamStr(2)='squid' then begin
                 GLOBAL_INI.SQUID_STOP();
                 GLOBAL_INI.DANSGUARDIAN_STOP();
                 GLOBAL_INI.KAV4PROXY_STOP();
                 halt(0);
              end;
              
            if ParamStr(2)='dansguardian' then begin
                 GLOBAL_INI.DANSGUARDIAN_STOP();
                 halt(0);
              end;
              
            if ParamStr(2)='boa' then begin
                 GLOBAL_INI.BOA_STOP();
                 halt(0);
              end;
              
            if ParamStr(2)='ftp' then begin
                 GLOBAL_INI.PURE_FTPD_STOP();
                 halt(0);
              end;
              
            if ParamStr(2)='mysql' then begin
                 GLOBAL_INI.ARTICA_STOP();
                 GLOBAL_INI.MYSQL_ARTICA_STOP();
                 halt(0);
              end;
              
             if ParamStr(2)='apache' then begin
                 writeln('stopping apache....');
                 GLOBAL_INI.APACHE_ARTICA_STOP();
                 halt(0);
              end;
              
             if ParamStr(2)='spamd' then begin
                 GLOBAL_INI.SPAMASSASSIN_STOP();
                 halt(0);
              end;
              
              
             if ParamStr(2)='clamd' then begin
                 GLOBAL_INI.CLAMD_STOP();
                 halt(0);
              end;
              
             if ParamStr(2)='freshclam' then begin
                 GLOBAL_INI.FRESHCLAM_STOP();
                 halt(0);
              end;
              

             if ParamStr(2)='saslauthd' then begin
                 GLOBAL_INI.ARTICA_STOP();
                 GLOBAL_INI.SASLAUTHD_STOP();
                 halt(0);
              end;
             if ParamStr(2)='amavis' then begin
                 GLOBAL_INI.ARTICA_STOP();
                 GLOBAL_INI.AMAVISD_STOP();
                 halt(0);
              end;

              
            if length(ParamStr(2))>0 then begin
               writeln('Usage:');
               writeln('/etc/init.d/artica-postfix stop ldap|imap|amavis|kav6|squid|dansgardian|boa|ftp|mysql|apache|spamd|clamd|freshclam');
               writeln('');
               halt(0);
            end;
            GLOBAL_INI.ARTICA_STOP();
            sleep(100);
            GLOBAL_INI.ARTICA_STOP();
            sleep(100);
            PRC.AutoKill(false);
            GLOBAL_INI.ARTICA_STOP();
            sleep(100);
            halt(0);

     end;
//##############################################################################
     if ParamStr(1)='-restart' then begin
          PRC:=Tprocessinfos.Create;
          PRC.AutoKill(false);
          GLOBAL_INI:=MyConf.Create();
          GLOBAL_INI.SYSTEM_START_ARTICA_DAEMON();
          halt(0);
     end;
//##############################################################################
     if ParamStr(1)='-awstats' then begin
            if ParamStr(2)='reconfigure' then begin
               install.INSTALL_AWSTATS();
               halt(0);
            end;
            if ParamStr(2)='generate' then begin
              GLOBAL_INI:=MyConf.Create();
              GLOBAL_INI.AWSTATS_GENERATE();
              halt(0);
            end;
    end;

//##############################################################################

     if ParamStr(1)='-procmail' then begin
           if ParamStr(2)='conf' then begin
              postfix_addon:=Tpostfix_addon.Create();
              postfix_addon.PROCMAIL_MASTER_CF;
              postfix_addon.PROCMAIL_PROCMAILRC;
              writeln('Done, please restart Postfix service');
              halt(0);
           end;

           if ParamStr(2)='status' then begin
              GLOBAL_INI:=MyConf.Create();
              GLOBAL_INI.PROCMAIL_INSTALLED();
              halt(0);
           end;
     end;

//##############################################################################

   if ParamStr(1)='-repos' then begin
            zMENUS:=Tmenus.Create();
            GLOBAL_INI:=myconf.Create;
            status:=true;

            REGEX.Expression:='-cyrus';
            if REGEX.Exec(s) then begin
               GLOBAL_INI.set_MANAGE_MAILBOX_SERVER('cyrus');
               GLOBAL_INI.set_MANAGE_MAILBOXES('yes');
            end;

            REGEX.Expression:='-status';
            if REGEX.Exec(s) then begin
               status:=false;
            end;

            REGEX.Expression:='check-applis';
            if REGEX.Exec(s) then begin
               GLOBAL_INI.GetAllApplisInstalled();
               halt(0);
            end;

            if ParamStr(2)='-status' then begin
               deb:=TDebian.Create();
               deb.debug:=True;
               deb.echo_local:=True;
               deb.ShowRepositories('');
               halt(0);
            end;

            if ParamStr(2)='simulate' then begin
               deb:=TDebian.Create();
               deb.debug:=True;
               deb.echo_local:=True;
               deb.AnalyseRequiredPackages(ParamStr(3));
               halt(0);
            end;
            

            


             zMENUS.install_Packages(status);

            halt(0);
    end;
//##############################################################################

      if ParamStr(1)='-autoinstall' then begin
           zMENUS:=Tmenus.Create();
           zMENUS.install_Packages_addon(ParamStr(2));
           halt(0);
      end;

      if ParamStr(1)='-autoremove' then begin
           zMENUS:=Tmenus.Create();
           zMENUS.remove_Packages_addon(ParamStr(2));
           halt(0);
      end;

//##############################################################################

      if ParamStr(1)='-horde' then begin
         if ParamStr(2)='install' then begin
             install.HORDE_RECONFIGURE();
             halt(0);
          end;

          if ParamStr(2)='reconfigure' then begin
             install.HORDE_RECONFIGURE();
             halt(0);
          end;

         halt(0);
      end;
//##############################################################################
      if ParamStr(1)='-roundcube' then begin
         if ParamStr(2)='install' then begin
             install.ROUNDCUBE_RECONFIGURE();
             halt(0);
          end;

          if ParamStr(2)='reconfigure' then begin
             install.ROUNDCUBE_RECONFIGURE();
             halt(0);
          end;

         halt(0);
      end;
//##############################################################################

   if ParamStr(1)='-ldap' then begin
   GLOBAL_INI:=MyConf.Create();
      REGEX.Expression:='status';
      if REGEX.Exec(s) then begin
         install.LDAP_STATUS(false,true);
         halt(0);
      end;
      REGEX.Expression:='setup';
      if REGEX.Exec(s) then begin
         zMENUS:=Tmenus.Create;
         zMenus.ldap_setup(true);
         halt(0);
      end;
      
      REGEX.Expression:='verify';
      if REGEX.Exec(s) then begin
         GLOBAL_INI.LDAP_VERIFY_SCHEMA();
         halt(0);
      end;
      
      REGEX.Expression:='default';
      if REGEX.Exec(s) then install.LDAP_DEFAULT_CONFIG();
      REGEX.Expression:='cyrus';
      if REGEX.Exec(s) then install.LDAP_SET_CYRUS_ADM();
      REGEX.Expression:='install';
      if REGEX.Exec(s) then install.LDAP_LOCAL_CONFIG();
      REGEX.Expression:='cyrus';
      if REGEX.Exec(s) then install.LDAP_SET_CYRUS_ADM();
      REGEX.Expression:='fix-authd';
      if REGEX.Exec(s) then begin
         GLOBAL_INI:=MyConf.Create();
         GLOBAL_INI.SASLAUTHD_TEST_INITD();
         halt(0);
      end;

      halt(0);
   end;

//##############################################################################
    if ParamStr(1)='-mysql' then begin
       GLOBAL_INI:=MyConf.Create();

       if ParamStr(2)='status' then begin
              writeln('Mysql account.................:',GLOBAL_INI.MYSQL_ROOT());
              writeln('Testing account...............:',GLOBAL_INI.MYSQL_ACTION_TESTS_ADMIN());
              writeln('PID Number....................:',GLOBAL_INI.MYSQL_ARTICA_PID());
              writeln('PID File......................:',GLOBAL_INI.MYSQL_SERVER_PARAMETERS_CF('pid-file'));
              writeln('starting with.................:',GLOBAL_INI.MYSQL_ARTICA_START_CMDLINE());
              halt(0);
       end;
       if ParamStr(2)='setadmin' then begin
          GLOBAL_INI.MYSQL_ACTION_CREATE_ADMIN(ParamStr(3),ParamStr(4));
          halt(0);
       end;

       if ParamStr(2)='artica-filter' then begin
          install.INSTALL_FILTER_DATABASE;
          halt(0);
       end;


    end;


    if ParamStr(1)='artica-filter' then begin
         GLOBAL_INI:=MyConf.Create();
         writeln(GLOBAL_INI.ARTICA_FILTER_GET_ALL_PIDS());
         halt(0);

    end;

//############################# DNSMASQ #########################################
    if ParamStr(1)='-dnsmasq' then begin
          if ParamStr(2)='version' then begin
             GLOBAL_INI:=MyConf.Create();
             writeln('dnsmasq version: "'+GLOBAL_INI.DNSMASQ_VERSION + '"');
             halt(0);
          end;
         if ParamStr(2)='reconfigure' then begin
            zMENUS.install_Packages_addon('APP_DNSMASQ');
            halt(0);
         end;

         zMenus.HELP_DNSMASQ();
         halt(0);

    end;

//############################# POSTFIX #########################################
    if ParamStr(1)='-testldap' then begin
      GLOBAL_INI:=MyConf.Create();
      GLOBAL_INI.LDAP_TESTS();
      halt(0);
    end;


   if ParamStr(1)='-postfix' then begin
      GLOBAL_INI:=MyConf.Create();
      if ParamStr(2)='conf' then begin
          writeln('Postfix version..........:',GLOBAL_INI.POSTFIX_VERSION());
          writeln('Headers checks (regexp)..:',GLOBAL_INI.POSTFIX_HEADERS_CHECKS());
          writeln('Logs path................:',GLOBAL_INI.get_LINUX_MAILLOG_PATH());
          writeln('Ldap compliance..........:',GLOBAL_INI.POSTFIX_LDAP_COMPLIANCE());
          writeln('master.cf path...........:',GLOBAL_INI.POSFTIX_MASTER_CF_PATH());


          halt(0);
      end;

      if ParamStr(2)='alllogs' then begin
         GLOBAL_INI.POSTFIX_EXPORT_LOGS();
         halt(0);
      end;

       if ParamStr(2)='fix-sasl' then begin
         install.POSTFIX_SET_SASL();
         halt(0);
      end;

       if ParamStr(2)='errors' then begin
          GLOBAL_INI.POSTFIX_LAST_ERRORS();
          halt(0);
       end;



      if ParamStr(2)='cert' then begin
         install.debug:=True;
         writeln('Result ',install.GenerateCertificateFileName(''));
         halt(0);
      end;


      if ParamStr(2)='check-config' then begin
             GLOBAL_INI.POSTFIX_REPLICATE_MAIN_CF(ParamStr(3));
             halt(0);
      end;


       if ParamStr(2)='inet' then begin
          POSTFIX:=Tpostfix_standard.Create;
          POSTFIX.debug:=True;
          POSTFIX.ChangeAutoIpInterfaces;
          halt(0);
       end;

      if ParamStr(2)='rrd' then begin
         GLOBAL_INI.debug:=True;
         GLOBAL_INI.RDDTOOL_POSTFIX_MAILS_CREATE_DATABASE();
         GLOBAL_INI.RDDTOOL_POSTFIX_MAILS_SENT_STATISTICS();
         GLOBAL_INI.RDDTOOL_POSTFIX_MAILS_SENT_GENERATE();
         halt(0);
      end;

       if ParamStr(2)='postmap' then begin
          GLOBAL_INI.debug:=True;
          GLOBAL_INI.POSTFIX_CHECK_POSTMAP();
          halt(0);
       end;
       if ParamStr(2)='queue' then begin
          if ParamStr(3)='cache' then begin
              GLOBAL_INI.POSFTIX_CACHE_QUEUE();
              halt(0);
          end;

          if ParamStr(3)='cache_delete' then begin
              GLOBAL_INI.POSFTIX_DELETE_FILE_FROM_CACHE(ParamStr(4));
              halt(0);
          end;


          Writeln('Files emails number: ',GLOBAL_INI.POSTFIX_QUEUE_FILE_NUMBER(ParamStr(3)));
          halt(0);
       end;

       if ParamStr(2)='queuelist' then begin
          list:=TStringList.Create;
          list.AddStrings(GLOBAL_INI.POSFTIX_READ_QUEUE_FILE_LIST(StrToInt(ParamStr(3)),StrToInt(ParamStr(4)),ParamStr(5),true));
          if length(ParamStr(6))>0 then begin
              list.SaveToFile(ParamStr(6));
              list.Free;
          end;
          halt(0);
       end;




      if length(ParamStr(2))>0 then begin
         writeln('Unable to determine your querie... see --help ');
         zMENUS:=TMenus.Create();
         ZMENUS.HELP_POSTFIX();
         halt(0);
      end;
      POSTFIX:=Tpostfix_standard.Create;
      POSTFIX.Configure_postfix_ldap();
      halt(0);
   end;

     if ParamStr(1)='-filter'  then begin
     POSTFIX_ADDON:=Tpostfix_addon.Create;
     POSTFIX_ADDON.SetPostFixContentFilter(ParamStr(2),ParamStr(3));
     halt(0);
     end;

     if ParamStr(1)='-send-subqueue'  then begin
       GLOBAL_INI:=MyConf.Create();

        writeln('Artica-send subqueue: ' +  ParamStr(2) + '........',GLOBAL_INI.ARTICA_SEND_SUBQUEUE_NUMBER(ParamStr(2)));
     halt(0);
     end;


//################################## CYRUS #####################################
     if ParamStr(1)='-cyrus'  then begin
        postfix_addon:=Tpostfix_addon.Create();
         if ParamStr(2)='status' then begin
            postfix_addon.cyrusStatus();
         end;

         if ParamStr(2)='uninstall' then begin
            install.CYRUS_UNINSTALL();
            halt(0);
         end;

         if ParamStr(2)='cyrus22' then begin
            GLOBAL_INI:=MyConf.Create();
            GLOBAL_INI.CYRUS_SET_V2('yes');
            POSTFIX:=Tpostfix_standard.Create;
            POSTFIX_ADDON:=Tpostfix_addon.Create;
            zMENUS:=Tmenus.Create();

            zMENUS.install_Packages(true);
            install.LDAP_SET_CYRUS_ADM();
            writeln('SET CYRUS IN MASTER.CF');
            POSTFIX_ADDON.set_cyrusMastercf();
            halt(0);
         end;


         if ParamStr(2)='lmtp' then begin
           postfix_addon.debug:=True;
           postfix_addon.force_to_lmtp:=True;
           postfix_addon.set_cyrusMastercf();
         end;
         
         if ParamStr(2)='make' then begin
                writeln('configure saslauthd and cyrus');
                install.SASLAUTHD_CONFIGURE();
                install.CYRUS_IMAPD_CONFIGURE();
                halt(0);
            end;

        if length(ParamStr(2))=0 then begin
           postfix_addon.debug:=True;
           postfix_addon.set_cyrusMastercf();
        end;
        halt(0);
     end;
//################################## aveserver##################################

     if ParamStr(1)='-mailav'  then begin
            if ParamStr(2)='delete' then begin
               install.RECONFIGURE_MASTER_CF();
               halt(0);
            end;

            if ParamStr(2)='remove' then begin
               install.KAV_UNINSTALL();
               halt(0);
            end;


            if ParamStr(2)='reconfigure' then begin
               install.RECONFIGURE_MASTER_CF();
               halt(0);
            end;
            if ParamStr(2)='template' then begin
               GLOBAL_INI:=MyConf.Create();
               writeln(GLOBAL_INI.AVESERVER_GET_TEMPLATE_DATAS(ParamStr(3),ParamStr(4)));
               halt(0);
            end;
            if ParamStr(2)='save_templates' then begin
               GLOBAL_INI:=MyConf.Create();
               GLOBAL_INI.AVESERVER_REPLICATE_TEMPLATES();
               halt(0);
            end;

            if ParamStr(2)='help' then begin
               zMENUS.HELP_AVESERVER();
               halt(0);
            end;
            if ParamStr(2)='pattern' then begin
               GLOBAL_INI:=MyConf.Create();
               writeln(GLOBAL_INI.AVESERVER_PATTERN_DATE());
               halt(0);
            end;

            if ParamStr(2)='replicate' then begin
               GLOBAL_INI:=MyConf.Create();
               GLOBAL_INI.AVESERVER_REPLICATE_kav4mailservers(trim(ParamStr(3)));
               halt(0);
            end;



        POSTFIX_ADDON:=Tpostfix_addon.Create;
        POSTFIX_ADDON.install_kaspersky_mail_servers();
        POSTFIX_ADDON.Free;
        halt(0);
     end;


     if ParamStr(1)='-checkstatus'  then begin
              PRC:=Tprocessinfos.Create;
              if PRC.isProcessExists2('artica-postfix') then begin
                 writeln('artica-postfix daemon status: RUN');
              end
              else  begin
                    writeln('artica-postfix daemon status: OFF');
              end;
              halt(0);
      end;

       if ParamStr(1)='-stat'  then begin
          GLOBAL_INI:=myconf.Create;
          if ParamStr(2)='fetchmail' then begin
             GLOBAL_INI.debug:=True;
             writeln('',GLOBAL_INI.FETCHMAIL_STATUS());
             halt(0);
          end;
          if ParamStr(2)='all' then begin
             GLOBAL_INI.debug:=True;
             GLOBAL_INI.SYSTEM_DAEMONS_STATUS();
             halt(0);
          end;
          halt(0);
       end;



      if ParamStr(1)='-watchdog'  then begin
              GLOBAL_INI:=myconf.Create;
              
              if ParamStr(2)='ldap' then begin
                 GLOBAL_INI.LDAP_START();
                 GLOBAL_INI.ARTICA_START();
                 halt(0);
              end;
              
             if ParamStr(2)='imap' then begin
                 GLOBAL_INI.CYRUS_DAEMON_START();
                 halt(0);
              end;
              

             if ParamStr(2)='kav6' then begin
                 GLOBAL_INI.KAV6_START();
                 halt(0);
              end;
              
             if ParamStr(2)='squid' then begin
                 GLOBAL_INI.SQUID_START();
                 GLOBAL_INI.DANSGUARDIAN_START();
                 GLOBAL_INI.KAV4PROXY_START();
                 halt(0);
              end;
              
             if ParamStr(2)='boa' then begin
                 GLOBAL_INI.BOA_START();
                 halt(0);
              end;
              
             if ParamStr(2)='dansguardian' then begin
                 GLOBAL_INI.DANSGUARDIAN_START();
                 halt(0);
              end;
              
              if ParamStr(2)='mysql' then begin
                 GLOBAL_INI.MYSQL_ARTICA_START();
                 GLOBAL_INI.ARTICA_START();
                 halt(0);
              end;
              

              
              if ParamStr(2)='apache' then begin
                 GLOBAL_INI.APACHE_ARTICA_START();
                 halt(0);
              end;
              
              if ParamStr(2)='ftp' then begin
                 GLOBAL_INI.PURE_FTPD_START();
                 halt(0);
              end;
              
              if ParamStr(2)='spamd' then begin
                 GLOBAL_INI.SPAMASSASSIN_START();
                 halt(0);
              end;
              
              if ParamStr(2)='clamd' then begin
                 GLOBAL_INI.CLAMD_START();
                 halt(0);
              end;
              
              if ParamStr(2)='freshclam' then begin
                 GLOBAL_INI.FRESHCLAM_START();
                 halt(0);
              end;
              
              if ParamStr(2)='saslauthd' then begin
                 GLOBAL_INI.SASLAUTHD_START();
                 GLOBAL_INI.ARTICA_START();
                 halt(0);
              end;


              if ParamStr(2)='amavis' then begin
                 GLOBAL_INI.AMAVISD_START();
                 GLOBAL_INI.ARTICA_START();
                 halt(0);
              end;

        if length(ParamStr(2))>0 then begin
               writeln('Usage:');
               writeln('/etc/init.d/artica-postfix start ldap|amavis|saslauthd|imap|kav6|squid|dansgardian|boa|ftp|mysql|apache|spamd|clamd|freshclam');
               writeln('');
               halt(0);
            end;
              
              
              GLOBAL_INI.SYSTEM_START_ARTICA_DAEMON();
              halt(0);
      end;
//######################## K Anti-spam #########################################
     if ParamStr(1)='-kas'  then begin
      GLOBAL_INI:=myconf.Create;
            if ParamStr(2)='remove' then begin
               install.KAS_UNINSTALL();
               halt(0);
            end;

            if ParamStr(2)='reconfigure' then begin
            install.RECONFIGURE_MASTER_CF();
            halt(0);
            end;

            if ParamStr(2)='conf' then begin
              GLOBAL_INI.KAS_APPLY_RULES(ParamStr(3));
              halt(0);
            end;


            if ParamStr(2)='delete' then begin
               install.RECONFIGURE_MASTER_CF();
               halt(0);
            end;

        install.KAS_INSTALL();
        install.RECONFIGURE_MASTER_CF();
        halt(0);
     end;
//##############################################################################
    if ParamStr(1)='-build'  then begin
         SYS:=Tsystem.Create();
         SYS.ScanArticaFiles('');
         SYS.BuildArticaFiles();
         halt(0);
    end;


     if ParamStr(1)='-init'  then begin
        GLOBAL_INI:=MyConf.Create();
        install.install_init_d();
         halt(0);
     end;

     if ParamStr(1)='-gdlib'  then begin
        GLOBAL_INI:=MyConf.Create();
        GLOBAL_INI.debug:=true;
        GLOBAL_INI.PHP5_ENABLE_GD_LIBRARY();
        halt(0);
     end;

     if ParamStr(1)='-mailgraph' then begin
        ZMENUS:=Tmenus.Create();
        zMENUS.install_Packages_addon('APP_MAILGRAPH');
        halt(0);
     end;

     if ParamStr(1)='-quarantine' then begin
             GLOBAL_INI:=myconf.Create;
         if ParamStr(2)='read' then begin
                 writeln('"' + ParamStr(5) + '" user...........: ' + GLOBAL_INI.PROCMAIL_QUARANTINE_SIZE( ParamStr(5)) + ' kb');
                 writeln('"' + ParamStr(5) + '" user...........: ' + GLOBAL_INI.PROCMAIL_QUARANTINE_USER_FILE_NUMBER( ParamStr(5)) + ' messages number');
                 GLOBAL_INI.PROCMAIL_READ_QUARANTINE(StrToInt(ParamStr(3)),StrToInt(ParamStr(4)),ParamStr(5));
                 halt(0);

         end;

        writeln('"' + ParamStr(2) + '" user...........: ' + GLOBAL_INI.PROCMAIL_QUARANTINE_SIZE( ParamStr(2)) + ' kb');
        writeln('"' + ParamStr(2) + '" user...........: ' + GLOBAL_INI.PROCMAIL_QUARANTINE_USER_FILE_NUMBER( ParamStr(2)) + ' messages number');


        halt(0);
     end;

//------------------------------------------------------------------------------

       if ParamStr(1)='-selinux_off' then begin
          install.Disable_se_linux();
          halt(0);
       end;
//------------------------------------------------------------------------------
       if ParamStr(1)='-apache' then begin
              if ParamStr(2)='status' then begin
                 install.APACHE_STATUS();
                 halt(0);
              end;
               if ParamStr(2)='setup' then begin
                  install.ARTICA_WEB();
                  halt(0);
               end;

       end;
//------------------------------------------------------------------------------

       if ParamStr(1)='-iplocal' then begin
          GLOBAL_INI:=MyConf.Create();
          GLOBAL_INI.SYSTEM_GET_ALL_LOCAL_IP;
          halt(0);
       end;


       if ParamStr(1)='-nics' then begin
          GLOBAL_INI:=MyConf.Create();
         writeln(GLOBAL_INI.SYSTEM_NETWORK_LIST_NICS);
          halt(0);
       end;

       if ParamStr(1)='-nic-infos' then begin
             GLOBAL_INI:=MyConf.Create();
             GLOBAL_INI.SYSTEM_NETWORK_INFO_NIC(ParamStr(2));
             halt(0);
       end;

       if ParamStr(1)='-nic-configure' then begin
             GLOBAL_INI:=MyConf.Create();
             GLOBAL_INI.SYSTEM_NETWORK_RECONFIGURE();
             halt(0);
       end;

       if ParamStr(1)='-ifconfig' then begin
             GLOBAL_INI:=MyConf.Create();
             writeln(GLOBAL_INI.SYSTEM_NETWORK_IFCONFIG());
             halt(0);
       end;

       if ParamStr(1)='-allips' then begin
             GLOBAL_INI:=MyConf.Create();
             GLOBAL_INI.SYSTEM_ALL_IPS();
             halt(0);
       end;




//------------------------------------------------------------------------------
       if ParamStr(1)='-cron' then begin
           if ParamStr(2)='list' then begin
              GLOBAL_INI:=MyConf.Create();
              GLOBAL_INI.SYSTEM_CRON_TASKS();
              halt(0);
           end;

       end;
//------------------------------------------------------------------------------

 if ParamStr(1)='-userslist' then begin
          GLOBAL_INI:=MyConf.Create();
          GLOBAL_INI.SYSTEM_USER_LIST();
          halt(0);
  end;

  if ParamStr(1)='-replic_cron' then begin
     GLOBAL_INI:=MyConf.Create();
     GLOBAL_INI.SYSTEM_CRON_REPLIC_CONFIGS();
     halt(0);
  end;

  if ParamStr(1)='-ps' then begin
     GLOBAL_INI:=MyConf.Create();
     GLOBAL_INI.SYSTEM_PROCESS_PS();
     halt(0);
  end;

  if ParamStr(1)='-pm' then begin
     GLOBAL_INI:=MyConf.Create();
     writeln(ParamStr(2) + '=',GLOBAL_INI.SYSTEM_PROCESS_MEMORY(ParamStr(2)));
     halt(0);
  end;

   if ParamStr(1)='-watch-filter' then begin
     GLOBAL_INI:=MyConf.Create();
     GLOBAL_INI.ARTICA_FILTER_WATCHDOG();
     halt(0);
  end;

//------------------------------------------------------------------------------

  if ParamStr(1)='-dspam' then begin


     writeln('unable to understand your query, type dspam not supported');
     halt(0);
  end;
//------------------------------------------------------------------------------
if  ParamStr(1)='-versions' then begin
        GLOBAL_INI:=MyConf.Create();
        GLOBAL_INI.CGI_ALL_APPLIS_INSTALLED();
        writeln(GLOBAL_INI.ArrayList.Text);
        halt(0);
end;
if  ParamStr(1)='-geoip-updates' then begin
       install.GEOIP_UPDATES();
       halt(0);
end;

if  ParamStr(1)='-proxy' then begin
       GLOBAL_INI:=MyConf.Create();
       GLOBAL_INI.SYSTEM_GET_HTTP_PROXY();
       halt(0);
end;

if  ParamStr(1)='-perl-upgrade' then begin
       install.PERL_UPGRADE();
       halt(0);
end;

if  ParamStr(1)='-perl-patch' then begin
       GLOBAL_INI:=MyConf.Create();
       GLOBAL_INI.PATCHING_PERL_TO_ARTICA(ParamStr(2));
       halt(0);
end;

if  ParamStr(1)='@INC' then begin
       GLOBAL_INI:=MyConf.Create();
       writeln('Perl INC folders...:');
       GLOBAL_INI.PERL_INCFolders();
       halt(0);
end;

if  ParamStr(1)='-mailman-check' then begin
    install.MAILMAN_CHECK_CONFIG;
    halt(0)
end;

if  ParamStr(1)='-ldap-install' then begin
    install.OPENLDAP_INSTALL(true);
    halt(0)
end;

if  ParamStr(1)='-sasl-install' then begin
    install.LIBSASL_INSTALL(false,false);
    install.SASLAUTHD_CONFIGURE();
    halt(0)
end;
if  ParamStr(1)='-mailman-install' then begin
    install.MAILMAN_INSTALL();
    halt(0)
end;

if  ParamStr(1)='-kav-install' then begin
    install.KAV_INSTALL();
    halt(0)
end;


if  ParamStr(1)='-kav-milter-remove' then begin
    install.KAVMILTER_UNINSTALL();
    writeln('done...');
    halt(0)
end;

if  ParamStr(1)='-set-host' then begin
     GLOBAL_INI:=MyConf.Create();
      GLOBAL_INI.SYSTEM_SET_HOSTENAME(ParamStr(2));
      writeln('Done... "'  + ParamStr(2) + '"');
     halt(0)
end;
if  ParamStr(1)='-web-configure' then begin
     install.ARTICA_WEB();
     halt(0)
end;

if  ParamStr(1)='-kav-proxy' then begin
     install.KAVPROXY_INSTALL();
     halt(0)
end;

if  ParamStr(1)='-rrd-install' then begin
     install.KAVPROXY_INSTALL();
     halt(0)
end;

if  ParamStr(1)='-du' then begin
     SYS:=Tsystem.Create();
     writeln('size of '+ ParamStr(2) + '=' + IntTostr((SYS.GetDirectoryList(ParamStr(2))div 1024)div 1000) + ' Mb');
     halt(0)
end;


if  ParamStr(1)='-build-deb' then begin
     GLOBAL_INI.BuildDeb(ParamStr(2),ParamStr(3));
     halt(0);
end;


if ParamStr(1)='-init-postfix' then begin
     install.POSTFIX_INIT();
     halt(0);
end;


if ParamStr(1)='-init-cyrus' then begin
     install.CYRUS_IMPAD_INIT();
     install.LDAP_SET_CYRUS_ADM();
     halt(0);
end;

if ParamStr(1)='-squid-rrd' then begin
   GLOBAL_INI:=MyConf.Create();
   GLOBAL_INI.SQUID_RRD_INIT();
   halt(0);
end;
if ParamStr(1)='-filestatus' then begin
   writeln('stat ' + ParamStr(2) + '...');
   GLOBAL_INI:=MyConf.Create();
   GLOBAL_INI.StatFile(ParamStr(2));
   halt(0);
end;

if ParamStr(1)='-watch-queue' then begin
   GLOBAL_INI:=MyConf.Create();
   GLOBAL_INI.ARTICA_SEND_WATCHDOG_QUEUE;
   halt(0);
end;


if ParamStr(1)='-purge-bightml' then begin
   GLOBAL_INI:=MyConf.Create();
   GLOBAL_INI.WATCHDOG_PURGE_BIGHTML();
   halt(0);
end;

if ParamStr(1)='-reconfigure-master' then begin
   install.RECONFIGURE_MASTER_CF();
   halt(0);
end;

if ParamStr(1)='-artica-web-install' then begin
    zMENUS:=Tmenus.Create();
    zMENUS.ARTICA_WEB_ONLY_WITH_STEP();
    halt(0);
end;


if ParamStr(1)='-php-mysql' then begin
    install.MYSQL_INSTALL();
    install.PHP5_INSTALL();
    halt(0);
end;

if ParamStr(1)='-php5' then begin
install.MYSQL_INSTALL();
    install.PHP5_INSTALL();
    halt(0);
end;

if ParamStr(1)='-mysql-install' then begin
    install.MYSQL_INSTALL();
    install.PHP5_INSTALL();
    halt(0);
end;

if ParamStr(1)='-mysql-reconfigure' then begin
    install.MYSQL_RECONFIGURE();
    halt(0);
end;

if ParamStr(1)='-init-roundcube' then begin
    install.MYSQL_RECONFIGURE();
    install.ROUNDCUBE_RECONFIGURE();
    halt(0);
end;

if ParamStr(1)='-balance-install' then begin
    install.BALANCE_INSTALL();
    halt(0);
end;

if ParamStr(1)='-crossroads-install' then begin
    install.BALANCE_INSTALL();
    halt(0);
end;

if paramStr(1)='--sqlexec' then begin
   GLOBAL_INI:=MyConf.Create();
   GLOBAL_INI.MYSQL_ACTION_IMPORT_DATABASE(ParamStr(2),ParamStr(3));
   halt(0);
end;

if paramStr(1)='--sqlquery' then begin
   GLOBAL_INI:=MyConf.Create();
   GLOBAL_INI.MYSQL_ACTION_QUERY_DATABASE(ParamStr(2),ParamStr(3));
   halt(0);
end;





if ParamStr(1)='-postfix-reconfigure-master' then begin
   install.RECONFIGURE_MASTER_CF();
   install.POSTFIX_CONFIGURE_MAIN_CF();
   GLOBAL_INI:=MyConf.Create();
   GLOBAL_INI.POSTFIX_STOP();
   fpsystem('/usr/sbin/postfix start');
   halt(0);
end;

if ParamStr(1)='-pfqueue-install' then begin
    install.PFQUEUE_INSTALL();
    halt(0);
end;


if ParamStr(1)='-squid-install' then begin
    install.SQUID_INSTALL();
    halt(0);
end;

if ParamStr(1)='-squid-configure' then begin
    install.SQUID_CONFIGURE();
    GLOBAL_INI:=MyConf.Create();
    GLOBAL_INI.SQUID_RRD_INIT();
    halt(0);
end;

if ParamStr(1)='-init-artica' then begin
    install.INIT_ARTICA();
    halt(0);
end;

if ParamStr(1)='-dansguardian-install' then begin
    install.DANSGUARDIAN_INSTALL();
    halt(0);
end;

if ParamStr(1)='linux-net-dev' then begin
   install.PERL_LINUX_NET_DEV();
   halt(0);
end;

if paramStr(1)='-dansguardian-mem' then begin
   GLOBAL_INI:=MyConf.Create();
   writeln('Dansguardian memory:',IntToStr(global_ini.SYSTEM_PROCESS_MEMORY(global_ini.DANSGUARDIAN_PID())));
   halt(0);
end;

if paramStr(1)='-squid-security' then begin
   GLOBAL_INI:=MyConf.Create();
   install.KAVPROXY_RECONFIGURE();
   halt(0);
end;

if paramStr(1)='-pure-ftpd' then begin
   install.PUREFTPD_INSTALL();
   halt(0);
end;
if paramStr(1)='-perl-addons' then begin
   zMENUS:=Tmenus.Create();
   ZMenus.install_Packages_addon('APP_MAKE');
   install.PERL_ADDONS();
   halt(0);
end;

if paramStr(1)='-awstats-install' then begin
   install.AWSTATS_INSTALL();
   halt(0);
end;

if paramStr(1)='-awstats-reconfigure' then begin
   install.AWSTAT_RECONFIGURE();
   halt(0);
end;

if paramStr(1)='-rrd-install' then begin
   zMENUS:=Tmenus.Create();
   ZMenus.install_Packages_addon('APP_MAKE');
   install.RRD_INSTALL();
   halt(0);
end;



if ParamStr(1)='mysql-ps' then begin
   GLOBAL_INI:=MyConf.Create();
   writeln('SYSTEM_PROCESS_LIST_PID ->');
   writeln(GLOBAL_INI.SYSTEM_PROCESS_LIST_PID('/opt/artica/libexec/mysqld'));
   halt(0)
end;


if ParamStr(1)='-ldap-rm-syncrepl' then begin
   GLOBAL_INI:=MyConf.Create();
   GLOBAL_INI.LDAP_SYNCREPL_DELETE();
   halt(0);
end;

if ParamStr(1)='-curl-install' then begin
   ZMenus.install_Packages_addon('MAKE');
   install.LIBCURL_INSTALL(false);
   halt(0);
end;

if ParamStr(1)='-cross-rq' then begin
    GLOBAL_INI:=MyConf.Create();
    GLOBAL_INI.CROSSROADS_SEND_REQUESTS_TO_SERVER('');
   halt(0);
end;

if ParamStr(1)='--mirror' then begin
   install.Mirror();
   halt(0);
end;

if ParamStr(1)='-perl-db-file' then begin
   install.PERL_DBD_FILE();
   halt(0);
end;

if ParamStr(1)='-amavisd-install' then begin
zMenus:=Tmenus.Create();
   zMenus.install_Packages_addon('APP_MAKE');
    install.AMAVISD();
    halt(0);
end;
   
if ParamStr(1)='-unrar-install' then begin
zMenus:=Tmenus.Create();
   zMenus.install_Packages_addon('APP_MAKE');
    install.UNRAR_INSTALL();
    halt(0);
end;

if ParamStr(1)='-clamav-install' then begin
zMenus:=Tmenus.Create();
   zMenus.install_Packages_addon('APP_MAKE');
    install.CLAMAV_INSTALL();
    halt(0);
end;

if ParamStr(1)='-amavis-install' then begin
    zMenus:=Tmenus.Create();
    zMenus.install_Packages_addon('APP_MAKE');
    install.AMAVISD();
    halt(0);
end;

if ParamStr(1)='-spamassassin-install' then begin
    zMenus:=Tmenus.Create();
    zMenus.install_Packages_addon('APP_MAKE');
    install.SPAMASSASSIN_INSTALL();
    halt(0);
end;

if ParamStr(1)='-mem' then begin
     GLOBAL_INI:=MyConf.Create();
     writeln('proccess ',ParamStr(2),'=',GLOBAL_INI.SYSTEM_PROCESS_MEMORY(ParamStr(2)) , ' ko');
     writeln('Status ',GLOBAL_INI.SYSTEM_PROCESS_STATUS(ParamStr(2)));
     halt(0);
end;
if ParamStr(1)='--status' then begin
     GLOBAL_INI:=MyConf.Create();
     writeln(GLOBAL_INI.GLOBAL_STATUS());
     halt(0);
end;

if ParamStr(1)='--ls' then begin
     SYS:=TSystem.Create();
     writeln('initialize : ' +  ParamStr(2));
     sys.RecusiveListFiles(ParamStr(2));
     writeln(sys.DirListFiles.Text);
     halt(0);
end;

if ParamStr(1)='-ldap-acl' then begin
   GLOBAL_INI:=MyConf.Create();
   GLOBAL_INI.LDAP_VERIFY_RIGHTS();
   halt(0);
end;

if ParamStr(1)='-patch-perlconf' then begin
   install.PATCHING_Config_heavy_pl();
   halt(0);
end;

if ParamStr(1)='--mydiff' then begin
    GLOBAL_INI:=MyConf.Create();
     GLOBAL_INI.deb_files_extists_between(ParamStr(2),ParamStr(3));
   halt(0);
end;

if ParamStr(1)='--saver' then begin
    GLOBAL_INI:=MyConf.Create();
   writeln('Spamassassin version:',  GLOBAL_INI.SPAMASSASSIN_VERSION(),' ',GLOBAL_INI.SPAMASSASSIN_PATTERN_VERSION());
   halt(0);
end;

if ParamStr(1)='--clamver' then begin
    GLOBAL_INI:=MyConf.Create();
   writeln('Spamassassin version:',  GLOBAL_INI.CLAMAV_VERSION(),' ',GLOBAL_INI.CLAMAV_PATTERN_VERSION());
   halt(0);
end;

if ParamStr(1)='-p0f-install' then begin
   zMenus:=Tmenus.Create();
   zMenus.install_Packages_addon('APP_MAKE');
   install.POF_INSTALL();
   halt(0);
end;


if ParamStr(1)='--find-pid' then begin
   GLOBAL_INI:=MyConf.Create();
   writeln('Found:',GLOBAL_INI.SYSTEM_PROCESS_LIST_PID(ParamStr(2)));
   writeln('');
   writeln('');
   halt(0);
end;


if ParamStr(1)='--start' then begin
   GLOBAL_INI:=MyConf.Create();
   GLOBAL_INI.SYSTEM_START_ARTICA_ALL_DAEMON();
   writeln('');
   writeln('');
   halt(0);
end;

if ParamStr(1)='-init-amavis' then begin
    GLOBAL_INI:=MyConf.Create();
    install.AMAVISD_CONFIGURE();
    fpsystem('/usr/share/artica-postfix/bin/artica-ldap -amavis');
    install.RECONFIGURE_MASTER_CF();
    writeln('running spamassassin update');
    fpsystem('/opt/artica/bin/sa-update');
    writeln('running clamav update');
    writeln('restarting services');
    GLOBAL_INI.FRESHCLAM_START();
    GLOBAL_INI.AMAVISD_START();
    GLOBAL_INI.CLAMD_START();
    sleep(500);
    GLOBAL_INI.CLAMD_STOP();
    GLOBAL_INI.AMAVISD_STOP();
    GLOBAL_INI.FRESHCLAM_STOP();
    fpsystem('/etc/init.d/artica-postfix restart');
    halt(0);
end;


     if ParamStr(1)='--help' then begin
     GLOBAL_INI:=MyConf.Create();
     zMENUS:=TMenus.Create();
     writeln(GLOBAL_INI.get_ARTICA_PHP_PATH());
     writeln('');
     writeln('');
     writeln('Infos *********************************************');
     writeln('To install features run ' + ParamStr(0) + ' setup');
     writeln('to access to menus run  ' + ParamStr(0) + ' addons');
     writeln('****************************************************');
     writeln('');
     writeln('');
     writeln(chr(9) +'artica-install usages:-install cyrus|v2|v1|default|kav|kas|graph|procmail|roundcube|dnsmasq|all');
     writeln(chr(9) +'Example 1: artica-install -install cyrus kas kav graph procmail default');
     writeln(chr(9) +'Example 2: artica-install -install all default');
     writeln(chr(9)+chr(9)+'cyrus            : set cyrus in installation mode');
     writeln(chr(9)+chr(9)+'v2               : set cyrus-2.2 in installation mode instead cyrus21 packages (for debian systems)');
     writeln(chr(9)+chr(9)+'v1               : set cyrus21 in installation mode instead cyrus-2.2 packages (for debian systems)');
     writeln(chr(9)+chr(9)+'default          : no human intercations everything will be automatic');
     writeln(chr(9)+chr(9)+'kav              : auto-install Kaspersky Mail Antivirus');
     writeln(chr(9)+chr(9)+'kas              : auto-install Kaspersky Anti-spam entreprise edition');
     writeln(chr(9)+chr(9)+'procmail         : auto-install procmail');
     writeln(chr(9)+chr(9)+'roundcube        : auto-install roundcube front-end webmail client');
     writeln(chr(9)+chr(9)+'awstats          : auto-install awstats');
     writeln(chr(9)+chr(9)+'dnsmasq          : auto-install dnsmasq');
     writeln(chr(9)+chr(9)+'all              : maximum applications (full groupware/security mail server)');

     writeln('');
     writeln(chr(9) +'Artica-install auto-install daemon commands:');
     writeln(chr(9)+chr(9)+'-autoinstall [APP]: used by the artica-postfix daemon added in command line [APP]');
     writeln(chr(9)+chr(9)+'-autoremove [APP]: used by the artica-postfix daemon added in command line [APP] "X" says that artica support remove');
     writeln(chr(9)+chr(9)+'                    the application plugin to install');
     writeln(chr(9)+chr(9)+'                    APP_FETCHMAIL    -> Fetchmail [X]');
     writeln(chr(9)+chr(9)+'                    APP_CYRUS        -> Cyrus MDA');
     writeln(chr(9)+chr(9)+'                    APP_KAS3         -> Kaspersky anti-spam [X]');
     writeln(chr(9)+chr(9)+'                    APP_AVESERVER    -> Kaspersky antivirus mail [X]');
     writeln(chr(9)+chr(9)+'                    APP_RRDTOOL      -> rddtool engine');
     writeln(chr(9)+chr(9)+'                    APP_DNSMASQ      -> Dns lite engine');
     writeln(chr(9)+chr(9)+'                    APP_MAILRELAY    -> SMTP engine used as content-filter');
     writeln(chr(9)+chr(9)+'                    APP_DSPAM        -> Dspam anti-spam bayesian technology');
     writeln(chr(9)+chr(9)+'                    APP_SQLITE       -> Database engine');




     writeln('');
     writeln(chr(9) +'Artica-postfix daemon commands:');
     writeln(chr(9)+chr(9)+'-shutdown        : Stopping artica-postfix daemon');
     writeln(chr(9)+chr(9)+'-shutdown force  : force killing artica-postfix daemon and all threads');
     writeln(chr(9)+chr(9)+'-checkstatus     : Check status');
     writeln(chr(9)+chr(9)+'-watchdog        : Check status and start daemon if down');




     writeln('') ;
     writeln(chr(9) +'Artica-install usages: -init');
     writeln('');
     writeln(chr(9) + 'artica usages:................................................');
     writeln(chr(9)+chr(9)+'-init            : Configure artica-postfix daemon in init.d init scripts.');
     writeln('');

     writeln(chr(9) + 'Repositories usages: -repos cyrus|status|check-applis|simulate name');
     writeln(chr(9)+chr(9)+'-repos           : Install required repositories.');
     writeln(chr(9)+chr(9)+'status           : show required repositories (didn''t perform installation operations)');
     writeln(chr(9)+chr(9)+'cyrus            : Include cyrus in operations');
     writeln(chr(9)+chr(9)+'check-applis     : Show & determine installed applications status ');
     writeln(chr(9)+chr(9)+'simulate name    : Simulate repositories required by (name), name are in repositories.txt ');

     writeln('');
     writeln(chr(9) + 'Status usages: -stat');
     writeln(chr(9)+chr(9)+'-stat fetchmail  : Fetchmail status.');
     writeln(chr(9)+chr(9)+'-stat all        : get all status of supported processes');

     writeln('');
     writeln(chr(9) + 'webmail usages:');
     writeln(chr(9)+chr(9)+'-horde install    : reinstall the webmail (horde) application');
     writeln(chr(9)+chr(9)+'-horde reconfigure: reconfigure the webmail (horde) application but not install files..');
     writeln(chr(9)+chr(9)+'-roundcube install: reinstall the webmail (roundcube) application');
     writeln(chr(9)+chr(9)+'-roundcube reconfigure: reconfigure the webmail (roundcube) application but not install files..');

     writeln('');
     writeln(chr(9) + 'LDAP usages: -ldap install|cyrus|status|cyrus');
     writeln(chr(9)+chr(9)+'slapd {start|stop}start/stop ldap if installed via compilation mode');
     writeln(chr(9)+chr(9)+'install          : Configure ldap settings');
     writeln(chr(9)+chr(9)+'verify           : verify mandatory settings before start LDAP');
     writeln(chr(9)+chr(9)+'setup..          : Restart ldap part of setup ');
     writeln(chr(9)+chr(9)+'status           : Settings status');
     writeln(chr(9)+chr(9)+'default          : Create a new config file');
     writeln(chr(9)+chr(9)+'cyrus            : Set cyrus administrator');
     writeln(chr(9)+chr(9)+'fix-authd        : Parse init.d saslauthd to verify if ldap is enabled');





     writeln('');
     writeln(chr(9) + 'Cyrus usages:................................................');
     writeln(chr(9)+chr(9)+'-ldap cyrus      : Adding cyrus administrator in ldap server');
     writeln(chr(9)+chr(9)+'-cyrus           : Configure cyrus settings with postfix using cyrus deliver');
     writeln(chr(9)+chr(9)+'-cyrus lmtp      : force to configure postfix for using LMTP Socket path');
     writeln(chr(9)+chr(9)+'-cyrus status    : Get settings status');
     writeln(chr(9)+chr(9)+'-cyrus uninstall : Uninstall cyrus (with purge)');
     writeln(chr(9)+chr(9)+'-cyrus cyrus22   : install cyrus 2.2.x');
     writeln(chr(9)+chr(9)+'-cyrus make      : configure saslauthd and cyrus when compiling cyrus-imap (make way)');

     writeln('');
     writeln(chr(9) + 'procmail usages:..............................................');
     writeln(chr(9)+chr(9)+'-procmail conf   : integrate procmail in mail process');
     writeln(chr(9)+chr(9)+'-procmail status : give status of procmail...');

     writeln('');
     writeln(chr(9) + 'awstats usages:..............................................');
     writeln(chr(9)+chr(9)+'-awstats reconfigure.....: reconfigure awstats');
     writeln(chr(9)+chr(9)+'-awstats generate........: generate config files in artica www folder');



     zMENUS.HELP_POSTFIX() ;

     zMENUS.HELP_AVESERVER();

     zMENUS.HELP_DSPAM();



     writeln(chr(9)+chr(9)+'-kas             : Install and configure Kaspersky Anti-Spam gateway');
     writeln(chr(9)+chr(9)+'-kas conf [path] : Apply rules stored in specific folder [path]');
     writeln(chr(9)+chr(9)+'-kas reconfigure : reconfigure Kaspersky Anti-Spam gateway');
     writeln(chr(9)+chr(9)+'-kas remove      : uninstall Kaspersky Anti-Spam gateway');
     writeln(chr(9)+chr(9)+'-kas delete      : remove Kaspersky Anti-Spam gateway from master.cf');

     writeln('');
     writeln(chr(9) + 'Quarantine usages');
     writeln(chr(9)+chr(9)+'-quarantine user : get infos from user quarantine');
     writeln(chr(9)+chr(9)+'-quarantine read : read quarantine infos from user quarantine');
     writeln(chr(9)+chr(9)+'                (from file number)');
     writeln(chr(9)+chr(9)+'                (to file number)');
     writeln(chr(9)+chr(9)+'                (user)');
     writeln(chr(9)+chr(9)+'example -quarantine read 0 100 user1 ');

     writeln('');
     writeln(chr(9) + 'Mysql usages');
     writeln(chr(9)+chr(9)+'-mysql status...........: status of required settings');
     writeln(chr(9)+chr(9)+'-mysql setadmin.........: create mysql administrator..');
     writeln(chr(9)+chr(9)+ chr(9) + 'ex: -mysql setadmin administrator password');
     writeln(chr(9)+chr(9)+'-mysql artica-filter....: Creating database for artica-filter');
     writeln(chr(9)+chr(9)+'-mysql-install..........: Install Mysql server');
     writeln(chr(9)+chr(9)+'-php-mysql..............: recompile artica php for mysql');
     writeln(chr(9)+chr(9)+'--sqlexec filname database: Execute SQL commands for database to "file"');
     writeln(chr(9)+chr(9)+'--sqlquery database ''command'' : query SQL command from "command" in "database"');


     writeln('');
     writeln(chr(9) + 'Web server apache 2 usages');
     writeln(chr(9)+chr(9)+'-apache status   : get required infos for configuring apache system');
     writeln(chr(9)+chr(9)+'-apache setup    : configure apache for Artica');
     writeln(chr(9)+chr(9)+'-gdlib      : installing GD library for jpGraph component');
     writeln(chr(9)+chr(9)+'-vhost port : installing virtual host in defined port (port)');
     writeln(chr(9)+chr(9)+'example -vhost 13300 -> install artica vhost on this port');


     writeln('');
     writeln(chr(9) +'Network commands:');
     writeln(chr(9)+chr(9)+'-ip NIC..........: get IP from NIC (eth0, eth1...)');
     writeln(chr(9)+chr(9)+'-iplocal.........: Get local IP');
     writeln(chr(9)+chr(9)+'-nics............: Get list of all eth* set on this computer');
     writeln(chr(9)+chr(9)+'-nic-infos [nics]: Get parameters of the interface specified');
     writeln(chr(9)+chr(9)+'-nic-configure...: apply settings saved from artica ');
     writeln(chr(9)+chr(9)+'-ifconfig........: Get maximum informations of all nic');
     writeln(chr(9)+chr(9)+'-allips..........: Get all ip on this computer');


     writeln('');
     writeln(chr(9) +'Artica-install others commands:');
     writeln(chr(9)+chr(9)+'-UTC.............: test UTC conversion date');
     writeln(chr(9)+chr(9)+'-UTC date........: test UTC conversion date input');
     writeln(chr(9)+chr(9)+'-du [path].......: Get directory size of [path]');
     writeln(chr(9)+chr(9)+'-mailgraph.......: installing mailgraph component');
     writeln(chr(9)+chr(9)+'-distri..........: Get distribution name');
     writeln(chr(9)+chr(9)+'-libc............: Get libc version');
     writeln(chr(9)+chr(9)+'-check-repos.....: Testing required repostirories');
     writeln(chr(9)+chr(9)+'-check-befor.....: Check settings before get repositories');
     writeln(chr(9)+chr(9)+'-check-pack......: Check installed packages in debug mode');
     writeln(chr(9)+chr(9)+'-selinux_off.....: Disabled systems armors securities');
     writeln(chr(9)+chr(9)+'-enable-services.: Activate required service for full mail server');
     writeln(chr(9)+chr(9)+'-cron list.......: List all cron task in xml "like" mode');
     writeln(chr(9)+chr(9)+'-userslist.......: List all users stored in this system');
     writeln(chr(9)+chr(9)+'-replic_cron.....: Replic cron settings from artica to crond.d');
     writeln(chr(9)+chr(9)+'-ps..............: Parse system tasks');
     writeln(chr(9)+chr(9)+'-pm PID..........: Get memory in Ko of a defined process pid');
     writeln(chr(9)+chr(9)+'-watch-filter....: Execute watchdog feature on artica-filter process');
     writeln(chr(9)+chr(9)+'-versions........: Get versions of all installed products');
     writeln(chr(9)+chr(9)+'-proxy...........: Get proxy settings in env');
     writeln(chr(9)+chr(9)+'-exim-remove.....: remove Exim4');
     writeln(chr(9)+chr(9)+'-perl-upgrade....: Upgrade perl (if required)');
     writeln(chr(9)+chr(9)+'@INC.............: Get perl folders');
     writeln(chr(9)+chr(9)+'-set-host........: Change hostname');
     writeln(chr(9)+chr(9)+'-mailman-check...: Check mailman config');
     writeln(chr(9)+chr(9)+'-ldap-install....: Install Openldap');
     writeln(chr(9)+chr(9)+'-ldap-rm-syncrepl: Remove syncrepl entries (for dev)');

     
     writeln(chr(9)+chr(9)+'-sasl-install....: Install cyrus-sasl');
     writeln(chr(9)+chr(9)+'-mailman-install.: Install mailman');
     writeln(chr(9)+chr(9)+'-awstats-install.: Install awstats (use --force to reinstall)');
     writeln(chr(9)+chr(9)+'-awstats-reconfigure: reconfigure awstats');
     writeln(chr(9)+chr(9)+'-kav-install.....: Install Kaspersky for mail server (milter edition)');
     writeln(chr(9)+chr(9)+'-kav-milter-remove: remove Kaspersky for mail server (milter edition)');
     writeln(chr(9)+chr(9)+'-web-configure...: Reconfigure artica-web');
     writeln(chr(9)+chr(9)+'-kav-proxy.......: Install Kav Proxy');
     writeln(chr(9)+chr(9)+'-rrd-install.....: Install rrd tool');
     writeln(chr(9)+chr(9)+'-install-web-artica: Install artica web');
     writeln(chr(9)+chr(9)+'-init-postfix....: Initialize postfix Installation after the debian package');
     writeln(chr(9)+chr(9)+'-squid-rrd.......: Initialize Squid rrd tool for statistics');
     writeln(chr(9)+chr(9)+'-filestatus file.: Freepascal stat file');
     writeln(chr(9)+chr(9)+'-watch-queue.....: Release blocked mails in artica-filter queue');
     writeln(chr(9)+chr(9)+'-purge-bightml...: Scan the bightml queue and delete old files and directories');
     writeln(chr(9)+chr(9)+'-reconfigure-master: reconfigure /etc/postfix/master.cf');
     writeln(chr(9)+chr(9)+'-artica-web-install: Install only artica web with pause of each step');
     writeln(chr(9)+chr(9)+'-php5............: Install artica php');

     writeln(chr(9)+chr(9)+'-init-roundcube..: reconfigure mysql and roundcube after unpack repositories');
     writeln(chr(9)+chr(9)+'-pfqueue-install.: Install pfqueue tool');
     writeln(chr(9)+chr(9)+'-squid-install...: Get and compile squid proxy server');
     writeln(chr(9)+chr(9)+'-dansguardian-install: Install danseguardian + Squid');
     writeln(chr(9)+chr(9)+'-squid-security..: Check installing squid-security packages features.');
     writeln(chr(9)+chr(9)+'-pure-ftpd.......: Install pure-ftpd');
     writeln(chr(9)+chr(9)+'-perl-patch directory: scan a directory and change perl interpreter path ');
     writeln(chr(9)+chr(9)+'-perl-addons.....: Check perl dependencies, install them if requires. ');
     writeln(chr(9)+chr(9)+'-rrd-install.....: Install rrd (use --force) to reinstall');
     writeln(chr(9)+chr(9)+'-curl-install....: Install curl');
     writeln(chr(9)+chr(9)+'-cross-rq........: Send slaves requests to master');
     writeln(chr(9)+chr(9)+'-crossroads-install: Install crossroads (--force supported)');
     writeln(chr(9)+chr(9)+'-balance-install.: Compile "crossroads product" (load balancing,--force supported)');
     writeln(chr(9)+chr(9)+'--mirror [path]..: translate all packages from internet to disk');
     writeln(chr(9)+chr(9)+'-amavisd-install.: Install amavisd-new on system');
     writeln(chr(9)+chr(9)+'-unrar-install...: Install unrar on system');
     writeln(chr(9)+chr(9)+'-clamav-install..: Install clamav on system');
     writeln(chr(9)+chr(9)+'-amavis-install..: Install clamav, amavis, spamassassin,razor');
     writeln(chr(9)+chr(9)+'-spamassassin-install: Install spamassassin');

     writeln(chr(9)+chr(9)+'-mem [PID].......: Get full memory used by PID and all fork processes');
     writeln(chr(9)+chr(9)+'--status.........: Get full status of services (in ini file structure)');
     writeln(chr(9)+chr(9)+'-ldap-acl........: Verify ldap acl (use --verbose for output)');
     writeln(chr(9)+chr(9)+'-p0f-install.....: Install p0f');
     writeln(chr(9)+chr(9)+'--find-pid [pattern]: Found pids of a local process from specific "pattern" ');
     writeln(chr(9)+chr(9)+'--mydiff path1 path2: Found files already exists in 2 paths specified');
     writeln(chr(9)+chr(9)+'--start..........: Start all services...');






     writeln('');
     writeln('');
     writeln(chr(9)+chr(9)+'***************************************************');
     writeln(chr(9)+chr(9)+'Install features.: run ' + ParamStr(0) + ' setup');
     writeln(chr(9)+chr(9)+'Menu access:.....: run  ' + ParamStr(0) + ' addons');
     writeln(chr(9)+chr(9)+'****************************************************');
     writeln('');
     writeln('');


     halt(0);
     exit;
     end;




     writeln('Your command line "' + ParamStr(1) + ' ' + ParamStr(2) + '" is not understood');
     writeln('use --help to see orders');
     install.Free;
     halt(0);



end.
