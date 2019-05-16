close all;
clear all;
clc
disp('Veszteség számítás NPC topológia esetére');
%hálózati paraméterek------------------------------------------------------
disp('PARAMÉTEREK ------------------------------------------------------');
omega       =   2*50*pi;
Pn          =   5e3;                        % A maximális teljesítmény
Un          =   230;                        % Névleges fázis effektív
Udc         =   2*sqrt(2)*Un*1.05;          % 5% szabályozási tartalék

% 3 fázisú oldal félvezetõinek terhelése-----------------------------------

f_sw        =   25e3;                     % Kapcsolási freki
I_in_pk     =   5*sqrt(2)*Pn/3/Un;        % Csúcs a legalacsonyabb hálózati fesznél,
                                          % 5* túlterheléshez

% % IGBT adatok------------------------------------------------------------
% % F3L50R06W1E3_B11
disp('Félvezetõ modul: F3L50R06W1E3_B11 adatai -------------------------');
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
% % Inverter üzemi számítások, T2=1, T1=PWM, D5=!PWM, <T3=!PWM>, a többi
% % félvezetõ kikapcsolt
% % Az injektált 3. harmonikus kitöltési tényezõre gyakorolt hatását
% % elhanyagoljuk !!!!!!!!
disp('INVERTER üzem ----------------------------------------------------');
% T2-------------------------
I_T2_AV     =   I_in_pk/pi;                            % Áram középérték T2-re                              
I_T2_RMS    =   I_in_pk/2;                             % Áram effektív érték T2-re
P_T2        =   U0_IGBT*I_T2_AV+I_T2_RMS^2*R_IGBT      % T2 disszipációja 
                                                       % ki kell integrálni és kijön
t_T2_JH     =   P_T2*(ZTHJH+RTHJH);                    % Hûtõtönkhöz képesti túlhõmérséklet

% T1-------------------------
U_in_pk     =   sqrt(2)*Un ; 
I_T1_AV     =   I_in_pk*U_in_pk/Udc/2;              % ki kell integrálni és kijön
I_T1_RMS    =   I_in_pk*sqrt(U_in_pk/Udc/pi*4/3);   % ki kell integrálni és kijön
% A kapcsolási veszteség kb. lineáris a kapcsolt árammal és feszültséggel
% Van kapcsolási és vezetési veszteség is T1 esetén, így mindkettõt
% figyelembe véve:
P_T1        =   U0_IGBT*I_T1_AV+I_T1_RMS^2*R_IGBT+E_SW_IGBT*f_sw*I_in_pk/pi/50*Udc/2/300 
t_T1_JH     =   P_T1*(ZTHJH+RTHJH);

% D5--------------------------
I_D5_AV     =   I_T2_AV-I_T1_AV;                    %ellenütem miatt
%i_D5_AVell=I_in_pk/(2*pi)*(2-U_in_pk/Udc*pi);
% Integrálással kihozható
I_D5_RMS    =   I_in_pk*sqrt(1/2/pi*(pi/2-2*U_in_pk/Udc*4/3));
% Van vezetési és kapcsolási veszteség is
P_D5        =   U0_DIODE*I_D5_AV+I_D5_RMS^2*R_DIODE+E_SW_DIODE*f_sw*I_T1_AV/50*Udc/2/300
t_D5_JH     =   P_D5*(ZTHDJH+RTHDJH);               % Hûtõtönkhöz képesti túlhõmérséklet

disp('Modul disszipáció:');
% Egész modul vesztesége
P_SUM_modul =   2*(P_T1+P_T2+P_D5);

% Egyenirányító üzemi számítások-----------------------------------------
disp('EGYENIRÁNYÍTÓ üzem -----------------------------------------------');
I_D4_AV         =   I_T1_AV;
I_D4_RMS        =   I_T1_RMS;
P_D4            =   U0_DIODE*I_D4_AV+I_D4_RMS^2*R_DIODE+E_SW_DIODE*f_sw*I_D4_AV/50*Udc/2/300
t_D4_JH         =   P_D4*(ZTHDJH+RTHDJH);
I_T2_AV_rect    =   I_D5_AV;
I_T2_RMS_rect   =   I_D5_RMS;
P_T2_rect       =   U0_IGBT*I_T2_AV_rect+I_T2_RMS_rect^2*R_IGBT+E_SW_IGBT*f_sw*I_in_pk/pi/50*Udc/2/300
t_T2_JH_rect    =   P_T2_rect*(ZTHJH+RTHJH);

% Fojtó méretezés----------------------------------------------------------

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

