close all;
clear all;
clc
disp('Vesztes�g sz�m�t�s T-type topol�gia eset�re');
%h�l�zati param�terek------------------------------------------------------
disp('PARAM�TEREK ------------------------------------------------------');
omega       =   2*50*pi;
Pn          =   5e3;                        % A maxim�lis teljes�tm�ny
Un          =   230;                        % N�vleges f�zis effekt�v
Udc         =   2*sqrt(2)*Un*1.05;          % 5% szab�lyoz�si tartal�k

% 3 f�zis� oldal f�lvezet�inek terhel�se-----------------------------------

f_sw        =   50e3;                     % Kapcsol�si freki
I_in_pk     =   5*sqrt(2)*Pn/3/Un;        % Cs�cs a legalacsonyabb h�l�zati feszn�l,
                                          % 5* t�lterhel�shez

% % IGBT adatok------------------------------------------------------------
% % F3L50R06W1E3_B11
disp('F�lvezet� modul: NXH80T120L2Q0S2G -------------------------');
R_IGBT      =   0.3/(150-50);           % Diff ellen�ll�s karakterisztika alapj�n
U0_IGBT     =   1.9;                    % Nyit� fesz
E_SW_IGBT   =   (0.72+1.7)*1e-3;        % 60A, 350V munkapontban kapcsol�si vesztes�g
ZTHJH       =   0.6;                    % ??
RTHJH       =   0.6;               % Thermalresistance 
                                        % casetoheatsink + junctiontocase

% % Di�da adatok-----------------------------------------------------------

R_DIODE     =   0.01;                  % Di�da ellen�ll�s
U0_DIODE    =   0.9;                   % Di�da nyit�fesz
E_SW_DIODE  =   1e-3;                  % 60A, 350V munkapontban kapcsol�si vesztes�g
ZTHDJH      =   0.5;                   % ??
RTHDJH      =   1.5;                   % Thermalresistance 
                                       % casetoheatsink + junctiontocase

%--------------------------------------------------------------------------
% % Inverter �zemi sz�m�t�sok, T3=1, T1=PWM, T4=!PWM, a t�bbi
% % f�lvezet� kikapcsolt
% % Az injekt�lt 3. harmonikus kit�lt�si t�nyez�re gyakorolt hat�s�t
% % elhanyagoljuk !!!!!!!!
disp('INVERTER �zem ----------------------------------------------------');
% T1------------------------- T1=PWM
U_in_pk     =   sqrt(2)*Un ; 
I_T1_AV     =   I_in_pk*U_in_pk/Udc/2;              % ki kell integr�lni �s kij�n
I_T1_RMS    =   I_in_pk*sqrt(U_in_pk/Udc/pi*4/3);   % ki kell integr�lni �s kij�n
% A kapcsol�si vesztes�g kb. line�ris a kapcsolt �rammal �s fesz�lts�ggel
% Van kapcsol�si �s vezet�si vesztes�g is!!
P_T1        =   U0_IGBT*I_T1_AV+I_T1_RMS^2*R_IGBT+E_SW_IGBT*f_sw*I_in_pk/pi/50*Udc/2/300 
t_T1_JH     =   P_T1*(ZTHJH+RTHJH);

% T4------------------------- T4=!PWM
U_in_pk     =   sqrt(2)*Un ; 
I_T4_AV     =   I_in_pk/pi-I_T1_AV;                 %ellen�tem miatt
I_T4_RMS    =   I_in_pk/2-I_T1_RMS;                 %ellen�tem miatt
% A kapcsol�si vesztes�g kb. line�ris a kapcsolt �rammal �s fesz�lts�ggel
% Van kapcsol�si �s vezet�si vesztes�g is!!
P_T4        =   U0_IGBT*I_T4_AV+I_T4_RMS^2*R_IGBT+E_SW_IGBT*f_sw*I_in_pk/pi/50*Udc/2/300 
t_T4_JH     =   P_T4*(ZTHJH+RTHJH);

% T3------------------------- folytonos �zem T3=1 ,de csak T4=!PWM alatt
% folyik rajta �ram
I_T3_AV     =   I_T4_AV;                             %ugyanaz ,mint T4-re                             
I_T3_RMS    =   I_T4_RMS;                            %ugyanaz ,mint T4-re 
%Csak vezet�si vesztes�g van, mert nem kapcsol, viszont csak addig ameddig
%T4 be van kapcsolva, magyurl PWM! id�pillanatokban!!
P_T3        =   U0_IGBT*I_T3_AV+I_T3_RMS^2*R_IGBT   % T3 disszip�ci�ja 
                                                     % ki kell integr�lni �s kij�n
t_T3_JH     =   P_T3*(ZTHJH+RTHJH);                  % H�t�t�nkh�z k�pesti t�lh�m�rs�klet


disp('Modul disszip�ci�:');
% Eg�sz modul vesztes�ge
P_SUM_modul =   2*(P_T1+P_T3+P_T4)

% Egyenir�ny�t� �zemi sz�m�t�sok-----------------------------------------
fprintf('Egyenir�ny�t� �zem:\n');
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

% Fojt� m�retez�s----------------------------------------------------------

f0              =   1e3;                          % A sz�r� saj�tfrekvenci�ja �resj�r�sban
IL_f_sw_p2p     =   I_in_pk*0.25 ;                % Maxim�lis kapcsol�si frekenci�s hull�moss�g 
L               =   Udc/(8*IL_f_sw_p2p*f_sw);
C               =   1/L/(2*pi*f0)^2;
iC              =   Un*omega*C;                   % Kondi alapharmonikus �ram rms
I_sc            =   2e3;                          % H�l�zat r�vidz�r�si �rama
Zgrid           =   Un/I_sc;                      % H�l�zat impedanci�ja
Lgrid           =   Zgrid/sqrt(2)/omega;          % H�l�zat induktivit�sa 
                                                  % Xgrid=Rgrid felt�telez�ssel
Rgrid           =   Zgrid/sqrt(2);                % H�l�zat ellen�ll�sa