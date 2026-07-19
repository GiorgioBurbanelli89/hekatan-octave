% Subplot_Multiples.m — Cuatro figuras con funciones trigonometricas
% Nota: el motor Octave dibuja cada figure() como un grafico independiente.
clear; clc;

x = linspace(0, 4*pi, 200);

figure;
plot(x, sin(x), 'r', 'LineWidth', 1.5);
title('sin(x)'); xlabel('x'); ylabel('sin(x)'); grid on;

figure;
plot(x, cos(x), 'b', 'LineWidth', 1.5);
title('cos(x)'); xlabel('x'); ylabel('cos(x)'); grid on;

figure;
plot(x, sin(x).^2, 'g', 'LineWidth', 1.5);
title('sin^2(x)'); xlabel('x'); ylabel('sin^2(x)'); grid on;

% tan(x/4) tiene asintota en x = 2*pi; se acota a [-5, 5] porque
% el motor Octave no soporta ylim().
yt = min(max(tan(x/4), -5), 5);
figure;
plot(x, yt, 'm', 'LineWidth', 1.5);
title('tan(x/4) acotada a [-5,5]'); xlabel('x'); ylabel('tan(x/4)'); grid on;

fprintf('Cuatro funciones trigonometricas en figuras separadas.\n');
