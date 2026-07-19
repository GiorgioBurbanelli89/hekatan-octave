%% Cyclic Damage — concreto ciclico no lineal (histeresis, dano persistente)
% -------------------------------------------------------------------------
% Mismo modelo que concrete_damage (elasticidad danada sigma=(1-d)*E*e) pero
% con el DANO como ESTADO PERSISTENTE (maximo historico). Al recorrer un
% protocolo de reversas de carga aparecen los LAZOS DE HISTERESIS: la descarga
% y la recarga quedan sobre la secante (1-d)*E al origen, con el dano d
% CONGELADO del maximo historico. El dano solo CRECE (nunca se cura), y la
% rigidez de descarga se APLANA en cada ciclo (rigidez degradada).
%
% Reproduce la elasticidad danada secante de ASDConcrete1D (ASDEA/STKO):
% sin deformacion plastica residual (los lazos vuelven al origen).
%
% Convencion: e > 0 = traccion, e < 0 = compresion.
%
% Propiedades del concreto (identicas a concrete_damage):
%   E=30000 MPa, fc=30, ec0=0.0020, ecu=0.0035, ft=3, et0=ft/E=0.0001,
%   etf=0.0005, Z=(1-0.2)/(ecu-ec0)=533.33.
%
% Envelope sc(e): traccion elastico hasta et0 luego ft*exp(-(e-et0)/etf);
%   compresion (x=-e) parabola -fc*(2r-r^2) hasta ec0, luego residual
%   -fc*max(0.2, 1-Z*(x-ec0)). Dano secante d(e)=clamp(1 - sc/(E*e), 0, 1).
%
% Maquina de estado (loop sobre el protocolo de deformacion):
%   estado persistente: etmax (max e>0 historico), ecmax (max |e| en
%   compresion historico). NO se resetean.
%   si e >= 0 : etmax = max(etmax, e);  dt = d(etmax);  sigma = (1-dt)*E*e
%   si e <  0 : ecmax = max(ecmax,-e);  dc = d(-ecmax); sigma = (1-dc)*E*e
%   (CIERRE DE FISURA: cada rama usa SU propio dano; al invertir el signo la
%    rigidez de la otra rama vuelve a mandar.)
%
% Protocolo de deformacion (reversas, amplitudes crecientes):
%   0 -> -0.0006 -> 0 -> -0.0012 -> 0 -> -0.0020 -> 0 -> -0.0030 -> 0
%     -> +0.0001 -> 0 -> -0.0040
%
% Valores VALIDADOS en los picos del envelope (deben coincidir):
%   e=-0.0006  sigma=-15.30  d=0.150
%   e=-0.0012  sigma=-25.20  d=0.300
%   e=-0.0020  sigma=-30.00  d=0.500 (pico fc)
%   e=-0.0030  sigma=-14.00  d=0.844
%   e=-0.0040  sigma= -6.00  d=0.950 (residual 0.2fc)
%   e=+0.0001  sigma=  3.00  d=0.000 (traccion)
% -------------------------------------------------------------------------
clear; clc; close all;

%% Propiedades del material — concreto (identico a concrete_damage)
E   = 30000;    % MPa
fc  = 30;       % MPa
ft  = 3;        % MPa
ec0 = 0.0020;   % deformacion pico en compresion
ecu = 0.0035;   % deformacion ultima en compresion
et0 = ft/E;     % = 0.0001, deformacion pico en traccion
etf = 0.0005;   % softening en traccion
Z   = (1 - 0.2)/(ecu - ec0);   % = 533.33

fprintf('=== Cyclic Damage — concreto ciclico (histeresis, dano persistente) ===\n\n');
fprintf('E = %.0f MPa, fc = %.0f MPa, ft = %.0f MPa\n', E, fc, ft);
fprintf('ec0 = %.4f, ecu = %.4f, et0 = %.4f, etf = %.4f, Z = %.2f\n\n', ...
        ec0, ecu, et0, etf, Z);

%% Protocolo de deformacion (reversas de amplitud creciente)
% Puntos de retorno del protocolo (SIN notacion cientifica):
wp   = [0, -0.0006, 0, -0.0012, 0, -0.0020, 0, -0.0030, 0, 0.0001, 0, -0.0040];
nsub = 40;      % subpasos por segmento

% Construir el vector de deformacion recorriendo cada segmento lineal
epsv = wp(1);
for j = 1:(numel(wp)-1)
    seg  = linspace(wp(j), wp(j+1), nsub+1);
    epsv = [epsv, seg(2:end)];   % descartar el primero (duplicado)
end
Ns = numel(epsv);

%% Loop sobre el protocolo con ESTADO PERSISTENTE (etmax, ecmax)
sigv = zeros(1, Ns);    % esfuerzo sigma [MPa]  -> lazos de histeresis
dtv  = zeros(1, Ns);    % dano en traccion  dt [-]  (persistente, crece)
dcv  = zeros(1, Ns);    % dano en compresion dc [-] (persistente, crece)

etmax = 0;              % max e>0 historico (traccion)
ecmax = 0;              % max |e| historico en compresion
dt    = 0;              % dano de traccion  congelado
dc    = 0;              % dano de compresion congelado

for k = 1:Ns
    e = epsv(k);
    if e >= 0
        % --- rama de traccion ---
        etmax = max(etmax, e);
        dt    = dmg(etmax, E, fc, ec0, et0, etf, Z);   % dano secante del envelope
        sigv(k) = (1 - dt) * E * e;                     % secante danada al origen
    else
        % --- rama de compresion ---
        ecmax = max(ecmax, -e);
        dc    = dmg(-ecmax, E, fc, ec0, et0, etf, Z);
        sigv(k) = (1 - dc) * E * e;
    end
    dtv(k) = dt;
    dcv(k) = dc;
end

%% Verificacion de los picos del envelope (deben coincidir con la tabla)
fprintf('=== Valores de referencia en los picos del envelope ===\n');
fprintf('   e          sigma(MPa)     d\n');
chk = [-0.0006, -0.0012, -0.0020, -0.0030, -0.0040, 0.0001];
for j = 1:numel(chk)
    ej = chk(j);
    sj = sc(ej, E, fc, ec0, et0, etf, Z);
    dj = dmg(ej, E, fc, ec0, et0, etf, Z);
    fprintf('  %+8.5f   %9.3f   %6.3f\n', ej, sj, dj);
end
fprintf('\n');
fprintf('Dano final:  dt(traccion) = %.3f,  dc(compresion) = %.3f\n', dt, dc);
fprintf('Pasos del protocolo: %d (%d segmentos x %d subpasos)\n\n', ...
        Ns, numel(wp)-1, nsub);

%% Grafica 1 — HISTERESIS sigma vs e (lazos: descarga/recarga secante)
% Se traza la trayectoria completa con plot (linea): cada descarga a e=0 y la
% recarga forman un lazo cuya pendiente se APLANA al crecer el dano.
figure;
plot(epsv*1000, sigv, 'b-', 'LineWidth', 1.4); hold on;
grid on;
xlabel('deformacion  \epsilon  [milesimas]');
ylabel('esfuerzo  \sigma  [MPa]');
title('Cyclic Damage — histeresis \sigma(\epsilon) (lazos secantes)');
% marcar los picos del envelope alcanzados
epk = [-0.0006, -0.0012, -0.0020, -0.0030, -0.0040, 0.0001];
for j = 1:numel(epk)
    spk = sc(epk(j), E, fc, ec0, et0, etf, Z);
    plot(epk(j)*1000, spk, 'ko', 'MarkerFaceColor', 'w', 'MarkerSize', 6);
end
text(-2.0*1, -30, '  pico -30 MPa (d=0.5)', 'VerticalAlignment', 'top');

%% Grafica 2 — Degradacion: dano dt y dc vs paso (persistente, solo crece)
figure;
plot(1:Ns, dcv*100, 'r-', 'LineWidth', 1.8); hold on;
plot(1:Ns, dtv*100, 'g-', 'LineWidth', 1.8);
grid on;
xlabel('paso del protocolo  [-]');
ylabel('dano  d  [%]');
title('Cyclic Damage — degradacion del dano d_c y d_t (escalonada)');
% etiquetas de las curvas con text() (este motor no renderiza legend al final;
% ademas un comando de dibujo tras el titulo asegura que titulo/ejes salgan)
text(Ns*0.50, 92, 'd_c  compresion (rojo)', 'Color', 'r');
text(Ns*0.50,  6, 'd_t  traccion (verde)', 'Color', [0 0.5 0]);

fprintf('Listo — 2 graficas: histeresis sigma(e) y degradacion d(paso).\n');

%% ------------------------------------------------------------------------
%% Funciones constitutivas del concreto (reuso de concrete_damage)
%% ------------------------------------------------------------------------

function s = sc(e, E, fc, ec0, et0, etf, Z)
    % Envelope sc(e). e>0 traccion, e<0 compresion.
    if e >= 0
        if e <= et0
            s = E*e;                          % elastico
        else
            s = 3.0*exp(-(e - et0)/etf);      % softening traccion (ft=3)
        end
    else
        x = -e;                               % magnitud en compresion
        if x <= ec0
            r = x/ec0;
            s = -fc*(2*r - r^2);              % parabola Hognestad
        else
            s = -fc*max(0.2, 1 - Z*(x - ec0));% rama descendente + residual
        end
    end
end

function d = dmg(e, E, fc, ec0, et0, etf, Z)
    % Dano secante del envelope d(e) = clamp(1 - sc/(E*e), 0, 1), d(0)=0.
    if e == 0
        d = 0;
    else
        s = sc(e, E, fc, ec0, et0, etf, Z);
        d = min(max(1 - s/(E*e), 0), 1);
    end
end
