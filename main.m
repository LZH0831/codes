clear; clc; close all;

%% 1. 全局仿真参数
sim_global.params_list = [
    1, 256;   
    2, 512;   
    3, 768;   
];

sim_global.min_errors = 2000;    
sim_global.max_bits = 1e7;       
sim_global.EbN0_dB = 0:1:24;     
sim_global.x0 = 0.123456;        

configs = {
    struct('channel_type', 'AWGN', 'linestyle', '--', 'marker', 'o', 'name', 'AWGN'), ...
    struct('channel_type', 'Rayleigh', 'linestyle', '-', 'marker', 's', 'name', 'Rayleigh') ...
};

rayleigh_cfg.L = 2;
rayleigh_cfg.delays = [0, 1];    
rayleigh_cfg.powers = [0.5, 0.5]; 

num_params = size(sim_global.params_list, 1);
num_configs = length(configs);
num_snr = length(sim_global.EbN0_dB);

BER_results = zeros(num_params, num_configs, num_snr);

fprintf('=== MCSI-DCSK 系统仿真开始 ===\n');
fprintf('最大比特数: %d, 最小错误数: %d\n', sim_global.max_bits, sim_global.min_errors);

%% 2. 仿真主循环
for p_idx = 1:num_params
    N = sim_global.params_list(p_idx, 1);
    beta = sim_global.params_list(p_idx, 2);

    theta = beta / 2;
    M = log2(theta / N);
    
    bits_per_symbol = N * (M + 1);
    
    ref_chaos_seq = generate_chaos_seq(theta, sim_global.x0);
    
    fprintf('\n>> [参数组 %d/%d] N = %d, Beta = %d (M = %d)\n', p_idx, num_params, N, beta, M);
    
    for cfg_idx = 1:num_configs
        curr_cfg = configs{cfg_idx};
        fprintf('   正在运行信道: %s ...\n', curr_cfg.name);
        
        if strcmp(curr_cfg.channel_type, 'Rayleigh')
            frames_per_batch = 20; 
        else
            frames_per_batch = 500; 
        end
        
        for snr_idx = 1:num_snr
            EbN0_dB = sim_global.EbN0_dB(snr_idx);
            
            total_errors = 0;
            total_processed_bits = 0;
            
            while (total_errors < sim_global.min_errors) && (total_processed_bits < sim_global.max_bits)
                
                n_bits = frames_per_batch * bits_per_symbol;
                tx_bits = randi([0, 1], 1, n_bits);
                
                tx_matrix = transmitter(tx_bits, N, M, theta, ref_chaos_seq);
                
                if strcmp(curr_cfg.channel_type, 'Rayleigh')
                    L_cp = max(rayleigh_cfg.delays) + 2; 
                else
                    L_cp = 0; 
                end
                
                if L_cp > 0
                    tx_matrix_cp = [tx_matrix(:, end-L_cp+1:end), tx_matrix];
                else
                    tx_matrix_cp = tx_matrix;
                end
                
                tx_serial = reshape(tx_matrix_cp.', 1, []);
                
                if strcmp(curr_cfg.channel_type, 'Rayleigh')
                    rx_serial = Multipath_Rayleigh_Channel(tx_serial, EbN0_dB, ...
                                beta, bits_per_symbol, rayleigh_cfg);
                else
                    [rx_serial, ~] = AWGN_Channel(tx_serial, EbN0_dB, ...
                                     beta, bits_per_symbol);
                end
                
                rx_serial = rx_serial(1:length(tx_serial)); 
                rx_matrix_cp = reshape(rx_serial, beta + L_cp, []).';
                
                if L_cp > 0
                    rx_matrix = rx_matrix_cp(:, L_cp+1:end);
                else
                    rx_matrix = rx_matrix_cp;
                end
                
                rec_bits = receiver(rx_matrix, N, M, theta);
                
                errs = sum(abs(tx_bits - rec_bits));
                total_errors = total_errors + errs;
                total_processed_bits = total_processed_bits + length(tx_bits);
            end
            
            if total_processed_bits > 0
                BER_results(p_idx, cfg_idx, snr_idx) = total_errors / total_processed_bits;
            else
                BER_results(p_idx, cfg_idx, snr_idx) = 0;
            end
        
            fprintf('      Eb/N0=%4.1f dB | BER=%.2e | Bits=%d | Errs=%d\n', ...
                EbN0_dB, BER_results(p_idx, cfg_idx, snr_idx), total_processed_bits, total_errors);
            
             if total_errors == 0 && total_processed_bits >= sim_global.max_bits
                fprintf('      Eb/N0=%.1f 检测到 BER=0，跳过后续高信噪比点。\n', EbN0_dB);
                break;
            end
        end
    end
end

%% 3. 绘图
figure('Name', 'MCSI-DCSK Reproduction', 'Color', 'w');

param_styles = {
    struct('color', 'r', 'marker_awgn', 'o', 'marker_ray', '*'), ... 
    struct('color', 'b', 'marker_awgn', 'x', 'marker_ray', 'o'), ... 
    struct('color', 'k', 'marker_awgn', '+', 'marker_ray', 'd')      
};

legend_str = {};
p_handles = [];

for p_idx = 1:num_params
    N = sim_global.params_list(p_idx, 1);
    beta = sim_global.params_list(p_idx, 2);
    style = param_styles{p_idx};
    
    ber_awgn = squeeze(BER_results(p_idx, 1, :));
    valid_mask = ber_awgn > 0;
    if any(valid_mask)
        semilogy(sim_global.EbN0_dB(valid_mask), ber_awgn(valid_mask), ...
            ['--' style.marker_awgn], 'Color', style.color, 'LineWidth', 1.5, 'MarkerSize', 6);
        hold on;
        legend_str{end+1} = sprintf('N=%d, \\beta=%d, AWGN', N, beta);
    end
    
    ber_ray = squeeze(BER_results(p_idx, 2, :));
    valid_mask = ber_ray > 0;
    if any(valid_mask)
        semilogy(sim_global.EbN0_dB(valid_mask), ber_ray(valid_mask), ...
            ['-' style.marker_ray], 'Color', style.color, 'LineWidth', 1.5, 'MarkerSize', 6);
        hold on;
        legend_str{end+1} = sprintf('N=%d, \\beta=%d, Rayleigh', N, beta);
    end
end

grid on;
title('MCSI-DCSK BER Performance (Comparison with Fig 4.3)');
xlabel('E_b/N_0 (dB)');
ylabel('BER');
legend(legend_str, 'Location', 'southwest');
axis([0 24 1e-5 1]); 
set(gca, 'YScale', 'log');

fprintf('\n=== 仿真完成 ===\n');