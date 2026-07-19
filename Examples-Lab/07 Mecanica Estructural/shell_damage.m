%% Shell Damage — seccion de cascara RC por capas (M-kappa con dano de concreto)
% -------------------------------------------------------------------------
% Seccion de cascara/placa de hormigon armado, por metro de ancho, analizada
% por CAPAS (layered shell section). Momento-curvatura con dano de concreto
% por capa (reusa el modelo de concrete_damage). La cascara se ablanda
% (softening) al crecer el dano = "shell damage".
%
% Concreto (identico a concrete_damage):
%   E=30000 MPa, fc=30, ec0=0.0020, ecu=0.0035, ft=3, et0=ft/E=0.0001,
%   etf=0.0005, Z=(1-0.2)/(ecu-ec0)=533.33.
%   sc(e): traccion elastico hasta et0 luego ft*exp(-(e-et0)/etf);
%          compresion (x=-e) parabola -fc*(2r-r^2) hasta ec0,
%          luego -fc*max(0.2, 1-Z*(x-ec0)).
%   Dano d(e)=clamp(1 - sc/(E*e), 0, 1).
% Acero: Es=200000, fy=420, elasto-plastico: ss(e)=clamp(Es*e, -fy, fy).
%
% Seccion (por metro de ancho):
%   t=200 mm, b=1000 mm, nc=20 capas (dz=10). Centro de capa i:
%   z_i=-t/2 + dz*(i-0.5). Acero As=1000 mm2/m en cada cara, cover=25,
%   brazo zs=t/2-cover=75.
%
% Formulacion (e(z)=e0 + kappa*z):
%   Para cada kappa:
%   1. Resolver e0 por equilibrio axial N(e0)=0 (biseccion).
%   2. Momento M(kappa)=Sum sc*b*dz*z_i + acero.
%   3. Dano en fibra de compresion: d_comp = d(e0 - kappa*t/2).
%
% Valores VALIDADOS (deben coincidir):
%   kappa=5.0e-6  -> M=40.80  d=0.082
%   kappa=1.0e-5  -> M=51.15  d=0.127
%   kappa=1.5e-5  -> M=67.74  d=0.175
%   kappa=1.64e-5 -> M=72.34 (pico)  d=0.188
%   kappa=2.0e-5  -> M=71.21  d=0.206
%   kappa=3.0e-5  -> M=69.94  d=0.253
%   kappa=4.0e-5  -> M=69.75  d=0.297
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

% Acero
Es = 200000;    % MPa
fy = 420;       % MPa

%% Geometria de la seccion (por metro de ancho)
t     = 200;            % mm  espesor
b     = 1000;           % mm  ancho (1 m)
nc    = 20;             % numero de capas de concreto
dz    = t/nc;           % = 10 mm  espesor de capa
As    = 1000;           % mm2/m  acero en cada cara
cover = 25;             % mm  recubrimiento
zs    = t/2 - cover;    % = 75 mm  brazo del acero

% Centros de las capas de concreto: z_i = -t/2 + dz*(i-0.5)
zc = zeros(1, nc);
for i = 1:nc
    zc(i) = -t/2 + dz*(i - 0.5);
end

fprintf('=== Shell Damage — seccion de cascara RC por capas (M-kappa) ===\n\n');
fprintf('t = %.0f mm, b = %.0f mm, nc = %d capas (dz = %.0f mm)\n', t, b, nc, dz);
fprintf('As = %.0f mm2/m por cara, cover = %.0f mm, zs = %.0f mm\n', As, cover, zs);
fprintf('E = %.0f, fc = %.0f, ft = %.0f, Z = %.2f | Es = %.0f, fy = %.0f\n\n', ...
        E, fc, ft, Z, Es, fy);

%% Barrido de curvatura kappa con un LOOP (200 puntos, de 0 a 4e-5)
Nk    = 200;
kappa = linspace(0, 4e-5, Nk);
Mv    = zeros(1, Nk);   % momento  [kN.m/m]
dcv   = zeros(1, Nk);   % dano en fibra de compresion [-]

for k = 1:Nk
    kp = kappa(k);

    % --- Biseccion para e0: equilibrio axial N(e0)=0 ---
    a  = -0.01;   % limite inferior de e0
    bb =  0.01;   % limite superior de e0
    Na = axial_force(a,  kp, zc, dz, b, zs, As, E, fc, ft, ec0, et0, etf, Z, Es, fy);
    for it = 1:60
        e0 = 0.5*(a + bb);
        Nm = axial_force(e0, kp, zc, dz, b, zs, As, E, fc, ft, ec0, et0, etf, Z, Es, fy);
        if (Na > 0) == (Nm > 0)
            a  = e0;
            Na = Nm;
        else
            bb = e0;
        end
    end
    e0 = 0.5*(a + bb);

    % --- Momento M(kappa) ---
    M = 0;
    for i = 1:nc
        ei = e0 + kp*zc(i);
        M  = M + sc(ei, E, fc, ec0, et0, etf, Z) * b * dz * zc(i);
    end
    % acero: +zs y -zs
    M = M + ss(e0 + kp*zs, Es, fy) * As * ( zs);
    M = M + ss(e0 - kp*zs, Es, fy) * As * (-zs);
    Mv(k) = M / 1e6;   % N.mm -> kN.m/m

    % --- Dano en fibra de compresion (borde superior z=-t/2) ---
    ecomp   = e0 - kp*t/2;
    dcv(k)  = dmg(ecomp, E, fc, ec0, et0, etf, Z);
end

%% Verificacion de los valores de referencia (deben coincidir con la tabla)
fprintf('=== Valores de referencia ===\n');
fprintf('   kappa(1/mm)   M(kN.m/m)   d_comp\n');
kchk = [5.0e-6, 1.0e-5, 1.5e-5, 1.64e-5, 2.0e-5, 3.0e-5, 4.0e-5];
for j = 1:numel(kchk)
    kp = kchk(j);
    a  = -0.01; bb = 0.01;
    Na = axial_force(a, kp, zc, dz, b, zs, As, E, fc, ft, ec0, et0, etf, Z, Es, fy);
    for it = 1:60
        e0 = 0.5*(a + bb);
        Nm = axial_force(e0, kp, zc, dz, b, zs, As, E, fc, ft, ec0, et0, etf, Z, Es, fy);
        if (Na > 0) == (Nm > 0), a = e0; Na = Nm; else, bb = e0; end
    end
    e0 = 0.5*(a + bb);
    M = 0;
    for i = 1:nc
        M = M + sc(e0 + kp*zc(i), E, fc, ec0, et0, etf, Z) * b * dz * zc(i);
    end
    M = M + ss(e0 + kp*zs, Es, fy)*As*zs + ss(e0 - kp*zs, Es, fy)*As*(-zs);
    dj = dmg(e0 - kp*t/2, E, fc, ec0, et0, etf, Z);
    fprintf('  %10.3e   %8.2f   %6.3f\n', kp, M/1e6, dj);
end
[Mpk, ipk] = max(Mv);
fprintf('\n  Momento pico M = %.2f kN.m/m en kappa = %.3e 1/mm\n\n', Mpk, kappa(ipk));

%% Grafica 1 — Momento vs curvatura (sube al pico y luego ablanda por dano)
figure;
plot(kappa*1e6, Mv, 'b-', 'LineWidth', 1.8); hold on;
grid on;
xlabel('curvatura  \kappa  [10^{-6} 1/mm]');
ylabel('momento  M  [kN\cdotm/m]');
title('Shell Damage — momento-curvatura M(\kappa)');
% marcar el pico
plot(kappa(ipk)*1e6, Mpk, 'ko', 'MarkerFaceColor', 'w', 'MarkerSize', 8);
text(kappa(ipk)*1e6, Mpk, sprintf('  pico M=%.1f', Mpk), 'VerticalAlignment', 'bottom');

%% Grafica 2 — Dano en la fibra de compresion vs curvatura (crece)
% Se grafica en porcentaje (0-100 %) para una escala vertical legible.
figure;
plot(kappa*1e6, dcv*100, 'r-', 'LineWidth', 1.8); hold on;
grid on;
xlabel('curvatura  \kappa  [10^{-6} 1/mm]');
ylabel('dano en fibra de compresion  d_{comp}  [%]');
title('Shell Damage — dano en compresion d(\kappa)');
% marcar el dano final (un comando de dibujo tras el titulo asegura que el
% titulo y los ejes se rendericen en el PNG)
plot(kappa(end)*1e6, dcv(end)*100, 'ko', 'MarkerFaceColor', 'r', 'MarkerSize', 7);
text(kappa(end)*1e6, dcv(end)*100, sprintf('  d_{comp}=%.1f%%', dcv(end)*100), ...
     'VerticalAlignment', 'top', 'HorizontalAlignment', 'right');

fprintf('Listo — 2 graficas: M(kappa) y d_comp(kappa).\n');

%% ------------------------------------------------------------------------
%% Funciones constitutivas (concreto = reuso de concrete_damage)
%% ------------------------------------------------------------------------

function s = sc(e, E, fc, ec0, et0, etf, Z)
    % Esfuerzo del concreto sc(e). e>0 traccion, e<0 compresion.
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
    % Dano escalar d(e) = clamp(1 - sc/(E*e), 0, 1), d(0)=0.
    if e == 0
        d = 0;
    else
        s = sc(e, E, fc, ec0, et0, etf, Z);
        d = min(max(1 - s/(E*e), 0), 1);
    end
end

function s = ss(e, Es, fy)
    % Acero elasto-plastico: ss(e) = clamp(Es*e, -fy, fy).
    s = min(max(Es*e, -fy), fy);
end

function N = axial_force(e0, kp, zc, dz, b, zs, As, E, fc, ft, ec0, et0, etf, Z, Es, fy)
    % Fuerza axial N(e0) = suma capas concreto + acero (2 caras).
    N = 0;
    nc = numel(zc);
    for i = 1:nc
        ei = e0 + kp*zc(i);
        N  = N + sc(ei, E, fc, ec0, et0, etf, Z) * b * dz;
    end
    N = N + ss(e0 + kp*zs, Es, fy) * As;
    N = N + ss(e0 - kp*zs, Es, fy) * As;
end
