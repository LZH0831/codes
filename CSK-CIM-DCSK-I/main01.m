%% CSK-CIM-DCSK-I 系统 BER 性能仿真 (同时绘制 AWGN 和 Rayleigh)
% 依赖文件: 
%   1. CSK_Transmitter.m
%   2. CSK_Receiver.m
%   3. AWGN_Channel.m
%   4. Multipath_Rayleigh_Channel.m
%   5. generate_chaos_sequence.m, generate_cyclic_shift_matrix.m

clear; clc; close all;

%% 1. 全局仿真参数
sim_global.beta = 512;        % 扩频因子
sim_global.min_errors = 100;  % 停止准则：至少收集到的错误比特数
sim_global.max_bits = 1e7;    % 最大发送比特数 (根据电脑性能调整，越高曲线越平滑)

sim_global.EbN0_dB = 0:2:24;  

% 瑞利信道参数
sim_global.rayleigh_cfg.L = 2;
sim_global.rayleigh_cfg.delays = [0, 1];
sim_global.rayleigh_cfg.powers = [0.5, 0.5];

%% 2. 参数配置 (根据图片调整颜色和标记)
% 图片对应关系推断：
% mc=2, ms=1 (Blue Circle)   -> 'b', 'o'
% mc=1, ms=2 (Red Diamond)   -> 'r', 'd'
% mc=3, ms=2 (Black Triangle)-> 'k', '^'
% mc=2, ms=3 (Magenta Square)-> 'm', 's'

configs = {
    struct('m_c', 2, 'm_s', 1, 'color', 'b', 'marker', 'o', 'name', 'm_c=2, m_s=1'), ...
    struct('m_c', 1, 'm_s', 2, 'color', 'r', 'marker', 'd', 'name', 'm_c=1, m_s=2'), ...
    struct('m_c', 3, 'm_s', 2, 'color', 'k', 'marker', '^', 'name', 'm_c=3, m_s=2'), ...
    struct('m_c', 2, 'm_s', 3, 'color', 'm', 'marker', 's', 'name', 'm_c=2, m_s=3') ...
};

num_configs = length(configs);
num_snr = length(sim_global.EbN0_dB);

% 预分配两个结果矩阵，分别存储 AWGN 和 Rayleigh 的结果
BER_AWGN = zeros(num_configs, num_snr);
BER_Rayleigh = zeros(num_configs, num_snr);

fprintf('=== CSK-CIM-DCSK-I 仿真启动 (AWGN & Rayleigh 对比) ===\n');
h_bar = waitbar(0, '初始化仿真...');

%% 3. 仿真主循环
for cfg_idx = 1:num_configs
    curr_cfg = configs{cfg_idx};
    
    % --- 准备当前配置的系统参数 ---
    sys_params.m_c = curr_cfg.m_c;
    sys_params.m_s = curr_cfg.m_s;
    sys_params.beta = sim_global.beta;
    sys_params.P = 2^(sys_params.m_c + 1);
    sys_params.theta = sys_params.beta / sys_params.P;
    sys_params.N = 2^sys_params.m_c;
    sys_params.M = 2^sys_params.m_s;
    
    bits_per_block = sys_params.m_c + sys_params.m_s + 1;
    
    fprintf('\n正在仿真配置 [%s] ...\n', curr_cfg.name);
    
    % --- SNR 循环 ---
    for snr_idx = 1:num_snr
        EbN0_dB = sim_global.EbN0_dB(snr_idx);
        
        % 初始化计数器 (分为两组)
        errs_awgn = 0;
        errs_ray = 0;
        total_bits = 0;
        
        % 更新进度条
        progress = ((cfg_idx-1)*num_snr + snr_idx) / (num_configs*num_snr);
        waitbar(progress, h_bar, sprintf('配置 %s | SNR %d dB', curr_cfg.name, EbN0_dB));
        
        % === 动态停止循环 ===
        % 逻辑：只要总比特数没超标，且 (瑞利信道错误不够 或 AWGN错误不够) 就继续
        % 注意：高SNR下 AWGN 错误极少，为了避免死循环，主要依赖 max_bits 退出
        while total_bits < sim_global.max_bits && (errs_awgn < sim_global.min_errors)
            
            % 1. 生成数据 & 发射机
            tx_bits = randi([0, 1], 1, bits_per_block);
            sys_params.x0 = rand(); % 随机初值
            [S_k, tx_info] = CSK_Transmitter(tx_bits, sys_params);
            
            % ----------------------------------------------------
            % 2. 并行通过两个信道
            % ----------------------------------------------------
            
            % path A: AWGN 信道
            r_awgn = AWGN_Channel(S_k, EbN0_dB, sys_params.beta, bits_per_block);
            
            % path B: Rayleigh 信道
            r_ray = Multipath_Rayleigh_Channel(S_k, EbN0_dB, ...
                    sys_params.beta, bits_per_block, sim_global.rayleigh_cfg);
            
            % ----------------------------------------------------
            % 3. 分别接收与解调
            % ----------------------------------------------------
            
            % 解调 AWGN 信号
            [rx_bits_awgn, ~] = CSK_Receiver(r_awgn, tx_info.r, sys_params);
            
            % 解调 Rayleigh 信号 (CSK_Receiver 已支持复数输入)
            [rx_bits_ray, ~] = CSK_Receiver(r_ray, tx_info.r, sys_params);
            
            % ----------------------------------------------------
            % 4. 分别统计错误
            % ----------------------------------------------------
            errs_awgn = errs_awgn + sum(abs(tx_bits - rx_bits_awgn));
            errs_ray  = errs_ray  + sum(abs(tx_bits - rx_bits_ray));
            
            total_bits = total_bits + bits_per_block;
        end
        
        % 记录结果
        BER_AWGN(cfg_idx, snr_idx) = errs_awgn / total_bits;
        BER_Rayleigh(cfg_idx, snr_idx) = errs_ray / total_bits;
        
        fprintf('  SNR=%2d dB | AWGN BER=%.2e | Ray BER=%.2e (Bits=%d)\n', ...
            EbN0_dB, BER_AWGN(cfg_idx, snr_idx), BER_Rayleigh(cfg_idx, snr_idx), total_bits);
    end
end
close(h_bar);

%% 4. 绘图 (复现图片样式) figure('Color', 'w');

% 循环绘制每种配置的曲线
legend_entries = {};
p_handles = []; % 用于存储图例句柄

for i = 1:num_configs
    c = configs{i};
    
    % --- 绘制 AWGN 曲线 (实线 + 标记) ---
    semilogy(sim_global.EbN0_dB, BER_AWGN(i, :), ...
        ['-' c.color c.marker], 'LineWidth', 1.5, ...
        'MarkerFaceColor', 'w', 'MarkerSize', 7); 
    hold on;
    
    % --- 绘制 Rayleigh 曲线 (实线 + 标记) ---
    % 为了区分，两者使用相同的颜色和标记，但它们在图上的位置明显不同
    % (通常 Rayleigh 曲线在右上方，衰减慢)
    h = semilogy(sim_global.EbN0_dB, BER_Rayleigh(i, :), ...
        ['-' c.color c.marker], 'LineWid th', 1.5, ...
        'MarkerFaceColor', 'w', 'MarkerSize', 7);
    
    % 保存句柄用于图例 (只存 Rayleigh 的句柄即可，代表该配置)
    p_handles = [p_handles; h];
    legend_entries{end+1} = [c.name ', Sim'];
end

% 添加文字标注 (模仿原图中的圈注)
% 这里的坐标需要根据仿真结果微调，大致指向曲线群
text(6, 1e-2, 'AWGN', 'FontSize', 12, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
text(16, 1e-1, 'Rayleigh', 'FontSize', 12, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');

% 装饰图表
grid on;
title('CSK-CIM-DCSK-I System BER Simulation');
xlabel('Eb/N0 (dB)');
ylabel('BER');
axis([0 24 1e-5 1]); % 调整坐标轴范围匹配图片
legend(p_handles, legend_entries, 'Location', 'SouthWest');
set(gca, 'GridAlpha', 0.3, 'MinorGridAlpha', 0.1);