%% CSK-CIM-DCSK-I 系统 BER 性能仿真 
% 依赖文件: 
%   1. CSK_Transmitter.m (发射机函数)
%   2. CSK_Receiver.m (接收机函数)
%   3. generate_chaos_sequence.m
%   4. generate_cyclic_shift_matrix.m
clear; clc; close all;

%% 1. 全局仿真参数
sim_global.beta = 512;        % 扩频因子
sim_global.min_errors = 100;  % 停止准则：至少收集到的错误比特数
sim_global.max_bits = 1e7;    % 防止死循环的最大发送比特数 (针对极高SNR)
sim_global.EbN0_dB = 0:2:24;  % 信噪比范围 (dB)

% 可选: 'AWGN' 或 'Rayleigh'
sim_global.channel_type = 'Rayleigh';

% 瑞利信道特有参数 (仅当 channel_type='Rayleigh' 时生效)
sim_global.rayleigh_cfg.L = 2;
sim_global.rayleigh_cfg.delays = [0, 1];
sim_global.rayleigh_cfg.powers = [0.5, 0.5];

% 定义不同的参数配置 (对比实验)
configs = {
    struct('m_c', 2, 'm_s', 1, 'color', 'b', 'marker', 'o', 'name', 'm_c=2, m_s=1 '), ...
    struct('m_c', 1, 'm_s', 2, 'color', 'r', 'marker', 'd', 'name', 'm_c=1, m_s=2 '), ...
    struct('m_c', 3, 'm_s', 2, 'color', 'k', 'marker', '^', 'name', 'm_c=3, m_s=2 '), ...
    struct('m_c', 2, 'm_s', 3, 'color', 'm', 'marker', 's', 'name', 'm_c=2, m_s=3 ') ...
};

num_configs = length(configs);
num_snr = length(sim_global.EbN0_dB);
BER_results = zeros(num_configs, num_snr);

fprintf('=== CSK-CIM-DCSK-I 仿真启动 ===\n');
fprintf('当前信道类型: %s\n', sim_global.channel_type);
fprintf('停止准则: 累计错误 >= %d 或 总比特 >= %.1e\n', ...
    sim_global.min_errors, sim_global.max_bits);

h_bar = waitbar(0, '初始化仿真...');

%% 2. 仿真主循环
for cfg_idx = 1:num_configs
    % --- 当前配置参数准备 ---
    curr_cfg = configs{cfg_idx};
    
    % 构建传递给函数的系统参数结构体 sys_params
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
        EbN0_lin = 10^(EbN0_dB/10);
        
        total_errors = 0;
        total_bits = 0;
        block_count = 0;
        
        % 更新进度条
        progress = ((cfg_idx-1)*num_snr + snr_idx) / (num_configs*num_snr);
        waitbar(progress, h_bar, ...
            sprintf('配置 %d/%d | SNR %.1f dB | 搜集错误中...', ...
            cfg_idx, num_configs, EbN0_dB));
        
        % === 动态停止循环 (Minimum Error Criterion) ===
        while total_errors < sim_global.min_errors && total_bits < sim_global.max_bits
            block_count = block_count + 1;
            
            % 1. 生成随机比特 & 更新混沌初值 (增加随机性)
            tx_bits = randi([0, 1], 1, bits_per_block);
            sys_params.x0 = rand(); % 每次传输使用随机初值
            
            % 2. 发射机 (模块化调用)
            %
            [S_k, tx_info] = CSK_Transmitter(tx_bits, sys_params);
            
            % 3. 信道传输 (根据开关选择)
            if strcmp(sim_global.channel_type, 'Rayleigh')
                % 调用瑞利信道函数
                r_k = Multipath_Rayleigh_Channel(S_k, EbN0_dB, ...
                      sys_params.beta, bits_per_block, sim_global.rayleigh_cfg);
            else
                % 调用 AWGN 信道函数
                r_k = AWGN_Channel(S_k, EbN0_dB, sys_params.beta, bits_per_block);
            end
            
            % 4. 接收机 (模块化调用)
            % 注意：需传入参考码索引 tx_info.r
            %
            [rx_bits, ~] = CSK_Receiver(r_k, tx_info.r, sys_params);
            
            % 5. 统计错误
            bit_errs = sum(abs(tx_bits - rx_bits));
            total_errors = total_errors + bit_errs;
            total_bits = total_bits + bits_per_block;
        end
        
        % 计算该 SNR 点的 BER
        BER_results(cfg_idx, snr_idx) = total_errors / total_bits;
        
        fprintf('  Eb/N0 = %4.1f dB | BER = %.2e | 错误数 = %d | 总比特 = %d\n', ...
            EbN0_dB, BER_results(cfg_idx, snr_idx), total_errors, total_bits);
    end
end
close(h_bar);

%% 3. 绘图与结果展示
figure;
for i = 1:num_configs
    semilogy(sim_global.EbN0_dB, BER_results(i, :), ...
        [configs{i}.color, '-' configs{i}.marker], ...
        'LineWidth', 1.5, 'MarkerFaceColor', configs{i}.color, ...
        'DisplayName', configs{i}.name);
    hold on;
end

grid on;
title(['CSK-CIM-DCSK-I BER Performance (\beta=' num2str(sim_global.beta) ')']);
xlabel('E_b/N_0 (dB)');
ylabel('Bit Error Rate (BER)');
legend('Location', 'southwest');
ylim([1e-5 1]);