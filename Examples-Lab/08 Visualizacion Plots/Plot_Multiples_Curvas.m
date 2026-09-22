% Plot_Multiples_Curvas.m — Varias curvas en el mismo plot
%
% OJO (Hekatan Octave): Octave NO es MATLAB 2017a. Diferencias que importan aqui:
%   - legend() NO se renderiza          -> etiquetar cada curva con text()
%   - title/xlabel/ylabel solo se pintan si DESPUES hay un comando de dibujo
clear; clc;

x = linspace(-pi, pi, 200);

figure;
plot(x, sin(x), 'r-', 'LineWidth', 1.5); hold on;
plot(x, cos(x), 'b--', 'LineWidth', 1.5);
plot(x, sin(x).*cos(x), 'g:', 'LineWidth', 2);

xlabel('x [rad]');
ylabel('y');
title('sin, cos y su producto');

% Etiquetas sobre cada curva (sustituyen a legend en Octave)
text(1.75, 0.95, 'sin(x)');
text(-0.95, 0.60, 'cos(x)');
text(0.55, 0.42, 'sin(x)*cos(x)');

% Este ultimo dibujo fuerza el repintado: sin el, title/xlabel/ylabel no salen
plot(x, zeros(size(x)), 'k-');
hold off;
grid on;

fprintf('Tres curvas etiquetadas con text() — en Octave legend() no se dibuja.\n');
