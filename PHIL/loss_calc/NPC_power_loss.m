close all;
clear all;
clc
disp('Vesztes�g sz�m�t�s NPC topol�gia eset�re');
%h�l�zati param�terek------------------------------------------------------
disp('PARAM�TEREK ------------------------------------------------------');
omega       =   2*50*pi;
Pn          =   4e3;                        % A maxim�lis teljes�tm�ny
Un          =   230;                        % N�vleges f�zis effekt�v
Udc         =   sqrt(3)*sqrt(2)*Un*1.05     % 5% szab�lyoz�si tartal�k
% 3 f�zis� oldal f�lvezet�inek terhel�se-----------------------------------
f_sw        =   50e3;                     % Kapcsol�si freki
I_in_pk     =   (4*sqrt(2)*Pn/3/Un)/5;    % Cs�cs a legalacsonyabb h�l�zati feszn�l,
                                          % 5* t�lterhel�shez
% % FET adatok-------------------------------------------------------------
% % IPW65R080CFD
disp('F�lvezet� modul:IPW65R080CFD adatai -------------------------');
R_dson      =   0.155;                  %T=60C Diff ellen�ll�s karakterisztika alapj�n
                                        %T=125C 0.175
t_r         =   20e-9;                  %rise time
t_f         =   8e-9;                   %fall time
ZTHJH       =   0;                      %???? =0
RTHJH       =   9.9+0.32;                   % Thermalresistance 
                                        % casetoambient + junctiontocase
% % Di�da adatok-----------------------------------------------------------
R_DIODE     =   0.2/9;                 % Di�da ellen�ll�s
Qrr         =   1e-6;
U0_DIODE    =   0.5;                    % Di�da nyit�fesz
E_SW_DIODE  =   Qrr*Udc/2;              % kapcsol�si vesztes�g (energia)
ZTHDJH      =   ZTHJH;                  % ??
RTHDJH      =   RTHJH;                  % Thermalresistance 
                                        % casetoambient + junctiontocase
%--------------------------------------------------------------------------
% % Inverter �zemi sz�m�t�sok, T2=1, T1=PWM, D5=!PWM, <T3=!PWM>, a t�bbi
% % f�lvezet� kikapcsolt
% % Az injekt�lt 3. harmonikus kit�lt�si t�nyez�re gyakorolt hat�s�t
% % elhanyagoljuk !!!!!!!!
disp('INVERTER �zem ----------------------------------------------------');
% T2-------------------------
I_T2_AV        =   I_in_pk/pi;                            % �ram k�z�p�rt�k T2-re                              
I_T2_RMS       =   I_in_pk/2;                             % �ram effekt�v �rt�k T2-re
P_sw_on        =   (I_T2_AV*Udc/2)*t_r*f_sw/2;
P_sw_off       =   (I_T2_AV*Udc/2)*t_f*f_sw/2;
P_T2_sw        =   P_sw_on  + P_sw_off  
P_T2_cond      =   (I_T2_RMS)^2*R_dson
P_T2_inv_pos   =   P_T2_cond                              % T2 disszip�ci�ja                                                       % ki kell integr�lni �s kij�n
t_T2_JH        =   P_T2_inv_pos*(ZTHJH+RTHJH)             % H�t�t�nkh�z k�pesti t�lh�m�rs�klet

% T1-------------------------
U_in_pk        =   sqrt(2)*Un ; 
I_T1_AV        =   I_in_pk*U_in_pk/Udc/2;              % ki kell integr�lni �s kij�n
I_T1_RMS       =   I_in_pk*sqrt(U_in_pk/Udc/pi*4/3);   % ki kell integr�lni �s kij�n
% A kapcsol�si vesztes�g kb. line�ris a kapcsolt �rammal �s fesz�lts�ggel
% Van kapcsol�si �s vezet�si vesztes�g is T1 eset�n, �gy mindkett�t
% figyelembe v�ve:
P_sw_on        =   (I_T1_AV*Udc/2)*t_r*f_sw/2;
P_sw_off       =   (I_T1_AV*Udc/2)*t_f*f_sw/2;
P_T1_sw        =   P_sw_on  + P_sw_off  
P_T1_cond      =   (I_T1_RMS)^2*R_dson
P_T1_inv_pos   =   P_T1_sw+P_T1_cond                      % T1 disszip�ci�ja                                                       % ki kell integr�lni �s kij�n
t_T1_JH        =   P_T1_inv_pos*(ZTHJH+RTHJH)             % H�t�t�nkh�z k�pesti t�lh�m�rs�klet

% D5--------------------------
I_D5_AV     =   I_T2_AV-I_T1_AV;                    %ellen�tem miatt
%i_D5_AVell=I_in_pk/(2*pi)*(2-U_in_pk/Udc*pi);
% Integr�l�ssal kihozhat� I_T1_RMS=I_in_pk*sqrt(U_in_pk/Udc/pi*4/3);
I_D5_RMS    =   I_in_pk*sqrt(1/2/pi*(pi/2-2*U_in_pk/Udc*4/3));
% Van vezet�si �s kapcsol�si vesztes�g is
P_D5_inv_pos        =   U0_DIODE*I_D5_AV+I_D5_RMS^2*R_DIODE+E_SW_DIODE*f_sw*I_T1_AV/50*Udc/2/300
t_D5_JH     =   P_D5_inv_pos*(ZTHDJH+RTHDJH);               % H�t�t�nkh�z k�pesti t�lh�m�rs�klet

% disp('Modul disszip�ci�:');
% % Eg�sz modul vesztes�ge
 P_SUM_modul =   2*(P_T1_inv_pos+P_T2_inv_pos+P_D5_inv_pos)
% 
% Egyenir�ny�t� �zemi sz�m�t�sok-----------------------------------------
disp('EGYENIR�NY�T� �zem -----------------------------------------------');
I_D4_AV         =   I_T1_AV;
I_D4_RMS        =   I_T1_RMS;
P_D4            =   U0_DIODE*I_D4_AV+I_D4_RMS^2*R_DIODE+E_SW_DIODE*f_sw*I_D4_AV/50*Udc/2/300
t_D4_JH         =   P_D4*(ZTHDJH+RTHDJH);
I_T2_AV_rect    =   I_D5_AV;
I_T2_RMS_rect   =   I_D5_RMS;
P_T2_rect       =   U0_IGBT*I_T2_AV_rect+I_T2_RMS_rect^2*R_dson+E_SW_FET*f_sw*I_in_pk/pi/50*Udc/2/300
t_T2_JH_rect    =   P_T2_rect*(ZTHJH+RTHJH);

% % % Fojt� m�retez�s----------------------------------------------------------
% % 
% % f0              =   1e3;                          % A sz�r� saj�tfrekvenci�ja �resj�r�sban
% % IL_f_sw_p2p     =   I_in_pk*0.25 ;                % Maxim�lis kapcsol�si frekenci�s hull�moss�g 
% % L               =   Udc/(8*IL_f_sw_p2p*f_sw);
% % C               =   1/L/(2*pi*f0)^2;
% % iC              =   Un*omega*C;                   % Kondi alapharmonikus �ram rms
% % I_sc            =   2e3;                          % H�l�zat r�vidz�r�si �rama
% % Zgrid           =   Un/I_sc;                      % H�l�zat impedanci�ja
% % Lgrid           =   Zgrid/sqrt(2)/omega;          % H�l�zat induktivit�sa 
% %                                                   % Xgrid=Rgrid felt�telez�ssel
% % Rgrid           =   Zgrid/sqrt(2);                % H�l�zat ellen�ll�sa
% % 
