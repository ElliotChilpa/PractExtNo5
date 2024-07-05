clc
clear all
close all

% Definición de las coordenadas del centro de la celda principal
a = 0; % Coordenada x del centro
b = 0; % Coordenada y del centro
c = input("Ingresa el valor del lado del hexagono (km): "); % Valor del lado del hexágono
n_usuarios = input("Ingresa la cantidad de usuarios por celda: "); % Cantidad de usuarios por celda

% Exponente de pérdidas por distancia
alpha = 10; % Aquí se define el valor de α, ajusta este valor según sea necesario

% Cálculo de apotema de los hexágonos
apotema = (sqrt(3) * c) / 2;

% Cálculo de potencia de los usuarios
P_tx = 10 * log10(10 * 1000); % Potencia de transmisión en dBm
G_tx = 12; % Ganancia de transmisión en dB
G_rx = 2; % Ganancia de recepción en dB

% Desviación estándar de pérdidas por ensombrecimiento (Variable aleatoria)
desvia = 7;
ad = makedist('Normal', 'mu', 0, 'sigma', desvia);

% Dibujar hexágonos y usuarios
[x, y, rx, ry] = DibujarHexagonos_y_usuarios(a, b, c, n_usuarios);

% Suma de potencias para cálculo total
suma_para_Ptotal = P_tx + G_tx + G_rx;

% Variables para almacenar los datos de cada usuario
Distancias = cell(1, 7);
Omega = cell(1, 7);
L_i_k = cell(1, 7);

% Cálculo de potencias de los usuarios en cada celda
for i = 1:7
    for j = 1:length(rx{i})
        for z = 1:7
            if z == 1
                % Distancia al centro de la celda principal
                d = sqrt((rx{i}(j) - a)^2 + (ry{i}(j) - b)^2) * 1000;
            else
                % Distancia a las celdas vecinas
                aaux = 2 * apotema * cosd(60 * (z - 2) + 30);
                baux = 2 * apotema * sind(60 * (z - 2) + 30);
                d = sqrt((rx{i}(j) - (a + aaux))^2 + (ry{i}(j) - (b + baux))^2) * 1000;
            end
            % Asignar una pérdida por ensombrecimiento a cada usuario
            Omega_i_k = random(ad);
            % Cálculo de la pérdida
            L_i_k{i}(j, z) = 10 * alpha * log10(d) + Omega_i_k;
            % Cálculo de la potencia
            Potencias{i}(j, z) = suma_para_Ptotal - L_i_k{i}(j, z);
            % Almacenar la distancia y la pérdida por ensombrecimiento
            Distancias{i}(j, z) = d;
            Omega{i}(j, z) = Omega_i_k;
        end
    end
end

% Asociar usuarios a la estación base que proporciona la mayor potencia
Usuarios_ordenados = cell(1, 7);
p = length(rx{1});
Base_asociada = cell(1, 7);

for i = 1:7
    for j = 1:p
        [P_max, zz] = max(Potencias{i}(j, :));
        Usuarios_ordenados{zz}(end + 1, 1:9) = [rx{i}(j) ry{i}(j) Potencias{i}(j, :)];
        Base_asociada{i}(j) = zz;
    end
end
Usuarios_ordenados{7}(1, :) = [];

% Selección de 5 usuarios aleatorios del total
total_usuarios = vertcat(Usuarios_ordenados{:});
indices_aleatorios = randperm(size(total_usuarios, 1), 5);
usuarios_resaltados = total_usuarios(indices_aleatorios, 1:2);

% Definir colores para los hexágonos
colores = {'r', 'g', 'b', 'c', 'm', 'y', 'k'};
nombre_colores = {'rojo', 'verde', 'azul', 'cian', 'magenta', 'amarillo', 'negro'};

% Imprimir la información de los usuarios seleccionados
for i = 1:length(indices_aleatorios)
    usuario_idx = indices_aleatorios(i);
    fprintf('Usuario %d\n', usuario_idx);
    fprintf('-------------------------\n');
    fprintf('Estación Base\tDistancia (m)\tPérdida Ensombrecimiento (dB)\tPérdida Total (dB)\n');
    for k = 1:7
        if ~isempty(find(Usuarios_ordenados{k}(:, 1) == total_usuarios(usuario_idx, 1) & Usuarios_ordenados{k}(:, 2) == total_usuarios(usuario_idx, 2), 1))
            fprintf('%d\t\t%.2f\t\t%.2f\t\t\t%.2f\n', k, Distancias{k}(usuario_idx), Omega{k}(usuario_idx), L_i_k{k}(usuario_idx));
        end
    end
    [~, base_asociada] = max(total_usuarios(usuario_idx, 3:end));
    fprintf('Base Asociada: %d (Color: %s)\n\n', base_asociada, nombre_colores{base_asociada});
end

% Gráfica de los hexágonos y usuarios
figure(1)
for i = 7:-1:1
    plot(x(i, :), y(i, :), 'LineWidth', 2, 'Color', colores{i})
    grid on
    hold on
    plot(rx{i}(:), ry{i}(:), '.', 'Color', colores{i})
end
title('Usuarios de cada estación base considerando únicamente la distancia')

% Gráfica con usuarios dispersos
figure(2)
subplot(2, 1, 1)
for i = 7:-1:1
    plot(x(i, :), y(i, :), 'LineWidth', 2, 'Color', colores{i})
    grid on
    hold on
    plot(Usuarios_ordenados{i}(:, 1), Usuarios_ordenados{i}(:, 2), '.', 'Color', colores{i})
end
plot(usuarios_resaltados(:, 1), usuarios_resaltados(:, 2), 'ro', 'MarkerSize', 10, 'LineWidth', 2)
title({'Usuarios de cada estación base considerando la potencia recibida por el modelo lognormal'; 'Considerando \alpha = 10'})

% Gráfica con usuarios de la estación base central
subplot(2, 1, 2)
for i = 7:-1:1
    plot(x(i, :), y(i, :), 'LineWidth', 2, 'Color', colores{i})
    grid on
    hold on
end
plot(Usuarios_ordenados{1}(:, 1), Usuarios_ordenados{1}(:, 2), '.', 'Color', colores{1})
title({'Usuarios de la estación base central considerando la potencia recibida por el modelo lognormal'; 'Considerando \alpha = 10'})

function [vectores_x, vectores_y, randomx, randomy] = DibujarHexagonos_y_usuarios(a, b, c, n_usuarios)
    apotema = sqrt(3) * c / 2;
    vectores_x = zeros(7, 7);
    vectores_y = zeros(7, 7);
    L = linspace(0, 2 * pi, 7);

    for i = 1:7
        if i == 1
            aaux = 0;
            baux = 0;
        else
            aaux = 2 * apotema * cosd(60 * (i - 2) + 30);
            baux = 2 * apotema * sind(60 * (i - 2) + 30);
        end
        vectores_x(i, :) = a + aaux + c * cos(L);
        vectores_y(i, :) = b + baux + c * sin(L);

        rx_aux = (a + aaux - c) + (a + aaux + c - a - aaux + c) * rand(n_usuarios, 1);
        ry_aux = (b + baux - apotema) + (b + baux + apotema - b - baux + apotema) * rand(n_usuarios, 1);
        p = inpolygon(rx_aux, ry_aux, vectores_x(i, :), vectores_y(i, :));
        rx_aux = rx_aux(p);
        ry_aux = ry_aux(p);

        while length(rx_aux) < n_usuarios
            new_rx_aux = (a + aaux - c) + (a + aaux + c - a - aaux + c) * rand(1, 1);
            new_ry_aux = (b + baux - apotema) + (b + baux + apotema - b - baux + apotema) * rand(1, 1);
            if inpolygon(new_rx_aux, new_ry_aux, vectores_x(i, :), vectores_y(i, :))
                rx_aux(end + 1) = new_rx_aux;
                ry_aux(end + 1) = new_ry_aux;
            end
        end

        randomx{i} = rx_aux;
        randomy{i} = ry_aux;
    end
end
