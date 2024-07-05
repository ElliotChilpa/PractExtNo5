clc
clear all
close all

% Definición de las coordenadas del centro de la celda principal
a = 0; % Coordenada x del centro
b = 0; % Coordenada y del centro
c = input("Ingresa el valor del lado del hexagono (km): "); % Valor del lado del hexágono
n_usuarios = input("Ingresa la cantidad de usuarios por celda: "); % Cantidad de usuarios por celda
K = input("Ingresa el factor de reuso: "); % Factor de reuso

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
[x, y, rx, ry] = DibujarHexagonos_y_usuarios(a, b, c, n_usuarios, K);

% Suma de potencias para cálculo total
suma_para_Ptotal = P_tx + G_tx + G_rx;

% Variables para almacenar los datos de cada usuario
Distancias = cell(1, 7);
Omega = cell(1, 7);
L_i_k = cell(1, 7);
Potencias = cell(1, 7);
PotenciaRecepcion = cell(1, 7);

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
Base_asociada = [];

for i = 1:7
    for j = 1:length(rx{i})
        [P_max, zz] = max(Potencias{i}(j, :));
        Usuarios_ordenados{zz}(end + 1, 1:9) = [rx{i}(j) ry{i}(j) Potencias{i}(j, :)];
        Base_asociada = [Base_asociada; zz];
        PotenciaRecepcion{zz}(end + 1) = P_max; % Guardar la potencia de recepción
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

% Definir la tabla CQI
CQI_table = {
    0, 'No Tx', 0, 0, -6.9336, 0;
    1, 'QPSK', 0.0762, 0.1523, -5.146, 27.414;
    2, 'QPSK', 0.1172, 0.2344, -3.18, 42.192;
    3, 'QPSK', 0.1885, 0.377, -1.25, 67.866;
    4, 'QPSK', 0.3, 0.6016, 0.094, 108.288;
    5, 'QPSK', 0.44, 0.877, 1.09, 157.866;
    6, 'QPSK', 0.59, 1.1758, 2.97, 211.644;
    7, '16QAM', 0.37, 1.4766, 5.31, 265.788;
    8, '16QAM', 0.48, 1.9141, 7.72, 344.538;
    9, '16QAM', 0.6, 2.4063, 9.55, 433.134;
    10, '64QAM', 0.45, 2.7305, 10.47, 491.499;
    11, '64QAM', 0.55, 3.3223, 12.34, 598.014;
    12, '64QAM', 0.65, 3.9023, 14.37, 702.414;
    13, '64QAM', 0.75, 4.5234, 16.48, 814.278;
    14, '64QAM', 0.85, 5.1152, 17.81, 920.736;
    15, '64QAM', 0.93, 5.5547, 20.31, 999.846
};

% Calcular SINR y asignar CQI y tasas de transmisión a los usuarios seleccionados
SINR = zeros(size(total_usuarios, 1), 1);
CQI = zeros(size(total_usuarios, 1), 1);
TasaAsignada = zeros(size(total_usuarios, 1), 1);

for i = 1:size(total_usuarios, 1)
    potencia_recepcion = PotenciaRecepcion{Base_asociada(i)}(1);
    
    % Calcular la interferencia total de las estaciones base vecinas
    interferencia_total = 0;
    for z = 2:7
        interferencia_total = interferencia_total + 10^(Potencias{Base_asociada(i)}(1, z) / 10);
    end
    interferencia_total = 10 * log10(interferencia_total);
    
    % Calcular SINR
    SINR(i) = potencia_recepcion - interferencia_total;
    
    % Asignar CQI basado en SINR
    for k = 1:size(CQI_table, 1)
        if SINR(i) < CQI_table{k, 5}
            CQI(i) = CQI_table{max(1, k-1), 1};
            TasaAsignada(i) = CQI_table{max(1, k-1), 6}; % Asignar tasa de bits por recurso
            break;
        elseif k == size(CQI_table, 1)
            CQI(i) = CQI_table{k, 1};
            TasaAsignada(i) = CQI_table{k, 6}; % Asignar tasa de bits por recurso
        end
    end
end

% Contar el número de usuarios para cada CQI por estación base
counts_per_base = cell(1, 7);
tasa_promedio_base = zeros(1, 7);

for i = 1:7
    counts_per_base{i} = zeros(1, length(CQI_table));
    usuarios_base = Usuarios_ordenados{i};
    sum_tasa = 0;
    for j = 1:size(usuarios_base, 1)
        usuario_idx = find(ismember(total_usuarios(:, 1:2), usuarios_base(j, 1:2), 'rows'));
        counts_per_base{i}(CQI(usuario_idx) + 1) = counts_per_base{i}(CQI(usuario_idx) + 1) + 1;
        sum_tasa = sum_tasa + TasaAsignada(usuario_idx);
    end
    if ~isempty(usuarios_base)
        tasa_promedio_base(i) = sum_tasa / size(usuarios_base, 1);
    end
end

% Mostrar un histograma para cada estación base
for i = 1:7
    figure(i + 4);
    bar([CQI_table{:, 1}], counts_per_base{i});
    xlabel('CQI');
    ylabel('Número de Usuarios');
    title(['Distribución de CQI en Estación Base ', num2str(i), ' (Color: ', nombre_colores{i}, ')']);
    grid on;
end

% Imprimir la tasa promedio de cada estación base
fprintf('Tasa promedio de cada estación base (kbps):\n');
for i = 1:7
    fprintf('Estación Base %d (%s): %.2f kbps\n', i, nombre_colores{i}, tasa_promedio_base(i));
end

% Imprimir la información de los usuarios seleccionados
fprintf('Información de los 5 usuarios seleccionados:\n');
fprintf('Usuario\tEstación Base\tColor\t\tDistancia (m)\tPérdida Ensombrecimiento (dB)\tPérdida Total (dB)\tPotencia Recepción (dBm)\tSINR (dB)\tCQI\tTasa (kbps)\n');
fprintf('--------------------------------------------------------------------------------------------------------------------------------------------------------------------------\n');
for i = 1:length(indices_aleatorios)
    usuario_idx = indices_aleatorios(i);
    [~, base_asociada] = max(total_usuarios(usuario_idx, 3:end));
    
    % Buscar el usuario en la estación base asociada
    usuarios_base = Usuarios_ordenados{base_asociada};
    for j = 1:size(usuarios_base, 1)
        if usuarios_base(j, 1) == total_usuarios(usuario_idx, 1) && usuarios_base(j, 2) == total_usuarios(usuario_idx, 2)
            dist = Distancias{base_asociada}(j, 1);
            perd_ensombrecimiento = Omega{base_asociada}(j, 1);
            perd_total = L_i_k{base_asociada}(j, 1);
            potencia_recepcion = PotenciaRecepcion{base_asociada}(j);
            sinr = SINR(usuario_idx);
            cqi = CQI(usuario_idx);
            tasa = TasaAsignada(usuario_idx);
            
            fprintf('%d\t\t%d\t\t%s\t%.2f\t\t%.2f\t\t\t%.2f\t\t%.2f\t\t%.2f\t\t%d\t%.2f\n', usuario_idx, base_asociada, nombre_colores{base_asociada}, dist, perd_ensombrecimiento, perd_total, potencia_recepcion, sinr, cqi, tasa);
            break;
        end
    end
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
for i = 7:-1:1
    plot(x(i, :), y(i, :), 'LineWidth', 2, 'Color', colores{i})
    grid on
    hold on
    plot(Usuarios_ordenados{i}(:, 1), Usuarios_ordenados{i}(:, 2), '.', 'Color', colores{i})
end
plot(usuarios_resaltados(:, 1), usuarios_resaltados(:, 2), 'ro', 'MarkerSize', 10, 'LineWidth', 2)
title({'Usuarios de cada estación base considerando la potencia recibida por el modelo lognormal'; 'Considerando \alpha = 10'})

% Gráfica con usuarios de la estación base central
figure(3)
for i = 7:-1:1
    plot(x(i, :), y(i, :), 'LineWidth', 2, 'Color', colores{i})
    grid on
    hold on
end
plot(Usuarios_ordenados{1}(:, 1), Usuarios_ordenados{1}(:, 2), '.', 'Color', colores{1})
title({'Usuarios de la estación base central considerando la potencia recibida por el modelo lognormal'; 'Considerando \alpha = 10'})

function [vectores_x, vectores_y, randomx, randomy] = DibujarHexagonos_y_usuarios(a, b, c, n_usuarios, K)
    apotema = sqrt(3) * c / 2;
    vectores_x = zeros(7, 7);
    vectores_y = zeros(7, 7);
    L = linspace(0, 2 * pi, 7);

    for i = 1:7
        if i == 1
            aaux = 0;
            baux = 0;
        else
            aaux = 2 * apotema * cosd(60 * (i - 2) + 30) * K;
            baux = 2 * apotema * sind(60 * (i - 2) + 30) * K;
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
