close all;
clear all;
clc

%hálózati paraméterek------------------------------------------------------
%disp('PARAMÉTEREK ------------------------------------------------------');
omega       =   2*50*pi;
Pn          =   5e3;                        % A maximális teljesítmény
Un          =   230;                        % Névleges fázis effektív
Udc         =   2*sqrt(2)*Un*1.05;          % 5% szabályozási tartalék

% 3 fázisú oldal félvezetõinek terhelése-----------------------------------

f_sw        =   50e3;                     % Kapcsolási freki
I_in_pk     =   5*sqrt(2)*Pn/3/Un;        % Csúcs a legalacsonyabb hálózati fesznél,
                                          % 5* túlterheléshez

% % IGBT adatok------------------------------------------------------------
% % F3L50R06W1E3_B11
fprintf('---------------------------------\nFélvezetõ modul: F3L50R06W1E3_B11\n---------------------------------\n');
R_IGBT      =   0.9/(70-20);            % Diff ellenállás karakterisztika alapján
U0_IGBT     =   0.8;                    % Nyitó fesz
E_SW_IGBT   =   (0.35+1.5)*1e-3;        % 50A, 300V munkapontban kapcsolási veszteség
ZTHJH       =   0.36;                   % ??
RTHJH       =   0.75+0.7;               % Thermalresistance 
                                        % casetoheatsink + junctiontocase

% % Dióda adatok-----------------------------------------------------------

R_DIODE     =   0.01;                   % Dióda ellenállás
U0_DIODE    =   0.9;                    % Dióda nyitófesz
E_SW_DIODE  =   1.5e-3;                 % 50A, 300V munkapontban kapcsolási veszteség
ZTHDJH      =   0.5;                    % ??
RTHDJH      =   1.8;                    % Thermalresistance 
                                        % casetoheatsink + junctiontocase

%--------------------------------------------------------------------------
%------------------------------NPC-----------------------------------------
%--------------------------------------------------------------------------
fprintf('Veszteség számítás NPC topológia esetére\n');                                        
%--------------------------------------------------------------------------
% % Inverter üzemi számítások, T2=1, T1=PWM, D5=!PWM, <T3=!PWM>, a többi
% % félvezetõ kikapcsolt
% % Az injektált 3. harmonikus kitöltési tényezõre gyakorolt hatását
% % elhanyagoljuk !!!!!!!!
fprintf('Inverter üzem:\n');
% T2-------------------------
I_T2_AV     =   I_in_pk/pi;                            % Áram középérték T2-re                              
I_T2_RMS    =   I_in_pk/2;                             % Áram effektív érték T2-re
P_T2        =   U0_IGBT*I_T2_AV+I_T2_RMS^2*R_IGBT;      % T2 disszipációja 
                                                       % ki kell integrálni és kijön
t_T2_JH     =   P_T2*(ZTHJH+RTHJH);                    % Hûtõtönkhöz képesti túlhõmérséklet

% T1-------------------------
U_in_pk     =   sqrt(2)*Un ; 
I_T1_AV     =   I_in_pk*U_in_pk/Udc/2;              % ki kell integrálni és kijön
I_T1_RMS    =   I_in_pk*sqrt(U_in_pk/Udc/pi*4/3);   % ki kell integrálni és kijön
% A kapcsolási veszteség kb. lineáris a kapcsolt árammal és feszültséggel
% Van kapcsolási és vezetési veszteség is T1 esetén, így mindkettõt
% figyelembe véve:
P_T1        =   U0_IGBT*I_T1_AV+I_T1_RMS^2*R_IGBT+E_SW_IGBT*f_sw*I_in_pk/pi/50*Udc/2/300; 
t_T1_JH     =   P_T1*(ZTHJH+RTHJH);

% D5--------------------------
I_D5_AV     =   I_T2_AV-I_T1_AV;                    %ellenütem miatt
%i_D5_AVell=I_in_pk/(2*pi)*(2-U_in_pk/Udc*pi);
% Integrálással kihozható
I_D5_RMS    =   I_in_pk*sqrt(1/2/pi*(pi/2-2*U_in_pk/Udc*4/3));
% Van vezetési és kapcsolási veszteség is
P_D5        =   U0_DIODE*I_D5_AV+I_D5_RMS^2*R_DIODE+E_SW_DIODE*f_sw*I_T1_AV/50*Udc/2/300;
t_D5_JH     =   P_D5*(ZTHDJH+RTHDJH);               % Hûtõtönkhöz képesti túlhõmérséklet

fprintf('Modul disszipáció:');
% Egész modul vesztesége
P_SUM_modul =   2*(P_T1+P_T2+P_D5)

% Egyenirányító üzemi számítások-----------------------------------------
fprintf('Egyenirányító üzem:');
%T2=!PWM D4=PWM
I_D4_AV         =   I_T1_AV;
I_D4_RMS        =   I_T1_RMS;
P_D4            =   U0_DIODE*I_D4_AV+I_D4_RMS^2*R_DIODE+E_SW_DIODE*f_sw*I_D4_AV/50*Udc/2/300
t_D4_JH         =   P_D4*(ZTHDJH+RTHDJH);
I_T2_AV_rect    =   I_D5_AV;
I_T2_RMS_rect   =   I_D5_RMS;
P_T2_rect       =   U0_IGBT*I_T2_AV_rect+I_T2_RMS_rect^2*R_IGBT+E_SW_IGBT*f_sw*I_in_pk/pi/50*Udc/2/300
t_T2_JH_rect    =   P_T2_rect*(ZTHJH+RTHJH);
fprintf('---------------------------------\n');
%--------------------------------------------------------------------------
%------------------------------T-type--------------------------------------
%--------------------------------------------------------------------------
fprintf('Veszteség számítás T-type topológia esetére\n');
%--------------------------------------------------------------------------
% % Inverter üzemi számítások, T3=1, T1=PWM, T4=!PWM, a többi
% % félvezetõ kikapcsolt
% % Az injektált 3. harmonikus kitöltési tényezõre gyakorolt hatását
% % elhanyagoljuk !!!!!!!!
fprintf('Inverter üzem:\n');
% T1------------------------- T1=PWM
U_in_pk     =   sqrt(2)*Un ; 
I_T1_AV     =   I_in_pk*U_in_pk/Udc/2;              % ki kell integrálni és kijön
I_T1_RMS    =   I_in_pk*sqrt(U_in_pk/Udc/pi*4/3);   % ki kell integrálni és kijön
% A kapcsolási veszteség kb. lineáris a kapcsolt árammal és feszültséggel
% Van kapcsolási és vezetési veszteség is!!
P_T1        =   U0_IGBT*I_T1_AV+I_T1_RMS^2*R_IGBT+E_SW_IGBT*f_sw*I_in_pk/pi/50*Udc/2/300; 
t_T1_JH     =   P_T1*(ZTHJH+RTHJH);

% T4------------------------- T4=!PWM
U_in_pk     =   sqrt(2)*Un ; 
I_T4_AV     =   I_in_pk/pi-I_T1_AV;                 %ellenütem miatt
I_T4_RMS    =   I_in_pk/2-I_T1_RMS;                 %ellenütem miatt
% A kapcsolási veszteség kb. lineáris a kapcsolt árammal és feszültséggel
% Van kapcsolási és vezetési veszteség is!!
P_T4        =   U0_IGBT*I_T4_AV+I_T4_RMS^2*R_IGBT+E_SW_IGBT*f_sw*I_in_pk/pi/50*Udc/2/300; 
t_T4_JH     =   P_T4*(ZTHJH+RTHJH);

% T3------------------------- folytonos üzem T3=1 ,de csak T4=!PWM alatt
% folyik rajta áram
I_T3_AV     =   I_T4_AV;                             %ugyanaz ,mint T4-re                             
I_T3_RMS    =   I_T4_RMS;                            %ugyanaz ,mint T4-re 
%Csak vezetési veszteség van, mert nem kapcsol, viszont csak addig ameddig
%T4 be van kapcsolva, magyurl PWM! idõpillanatokban!!
P_T3        =   U0_IGBT*I_T3_AV+I_T3_RMS^2*R_IGBT;   % T3 disszipációja 
                                                     % ki kell integrálni és kijön
t_T3_JH     =   P_T3*(ZTHJH+RTHJH);                  % Hûtõtönkhöz képesti túlhõmérséklet


fprintf('Modul disszipáció:\n');
% Egész modul vesztesége
P_SUM_modul =   2*(P_T1+P_T3+P_T4)

% Egyenirányító üzemi számítások-----------------------------------------
fprintf('Egyenirányító üzem:\n');
%T3=!PWM T1=PWM
I_D4_AV         =   I_T1_AV;
I_D4_RMS        =   I_T1_RMS;
P_D4            =   U0_DIODE*I_D4_AV+I_D4_RMS^2*R_DIODE+E_SW_DIODE*f_sw*I_D4_AV/50*Udc/2/300
t_D4_JH         =   P_D4*(ZTHDJH+RTHDJH);
I_T3_AV_rect    =   I_T4_AV;
I_T3_RMS_rect   =   I_T4_RMS;
P_T3_rect       =   U0_IGBT*I_T3_AV_rect+I_T3_RMS_rect^2*R_IGBT+E_SW_IGBT*f_sw*I_in_pk/pi/50*Udc/2/300
t_T3_JH_rect    =   P_T3_rect*(ZTHJH+RTHJH);

fprintf('---------------------------------\n');
%--------------------------------------------------------------------------
%---------------------------Fojtó méretezés--------------------------------
%--------------------------------------------------------------------------

f0              =   1e3;                          % A szûrõ sajátfrekvenciája üresjárásban
IL_f_sw_p2p     =   I_in_pk*0.25 ;                % Maximális kapcsolási frekenciás hullámosság 
L               =   Udc/(8*IL_f_sw_p2p*f_sw);
C               =   1/L/(2*pi*f0)^2;
iC              =   Un*omega*C;                   % Kondi alapharmonikus áram rms
I_sc            =   2e3;                          % Hálózat rövidzárási árama
Zgrid           =   Un/I_sc;                      % Hálózat impedanciája
Lgrid           =   Zgrid/sqrt(2)/omega;          % Hálózat induktivitása 
                                                  % Xgrid=Rgrid feltételezéssel
Rgrid           =   Zgrid/sqrt(2);                % Hálózat ellenállása