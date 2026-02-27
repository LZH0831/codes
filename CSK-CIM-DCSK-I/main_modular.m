%% CSK-CIM-DCSK-I 系统主程序 (模块化版)
clear; clc; close all;

%% 1. 参数设置
sys_params.m_c = 2;              % 码索引调制比特数
sys_params.m_s = 3;              % 循环移位索引调制比特数
sys_params.beta = 512;           % 扩频因子
sys_params.x0 = 0.123456;        % 混沌初始值
% 派生参数计算
sys_params.P = 2^(sys_params.m_c + 1);    % Walsh码长度
sys_params.theta = sys_params.beta / sys_params.P; % 每一段的长度
sys_params.N = 2^sys_params.m_c;          % 码索引空间大小
sys_params.M = 2^sys_params.m_s;          % 移位索引空间大小

%% 2. 原始信息生成
% 传输比特块 (这里使用你提供的固定序列，实际应用可随机生成)
tx_bits = [0, 1, 1, 1, 0, 1];  % 011101
fprintf('=== 发送端 ===\n');
fprintf('原始传输比特: %s\n', num2str(tx_bits));

%% 3. 发射机 (Transmitter)
% 调用发射机函数，返回发射信号 S_k 和 真实参数 info (用于验证)
[S_k, tx_info] = CSK_Transmitter(tx_bits, sys_params);

% 显示发射端中间结果
fprintf('映射结果 -> 码索引 a: %d, 移位索引 b: %d, 调制符号 q: %d\n', ...
    tx_info.a, tx_info.b, tx_info.q);
fprintf('参考Walsh码索引 r: %d (接收端需知晓)\n', tx_info.r);

%% 4. 信道传输 (Channel)
% 理想无噪信道
r_k = S_k;
fprintf('\n=== 信道传输 ===\n');
fprintf('理想无噪信道，接收信号 r_k = S_k\n');

%% 5. 接收机 (Receiver)
% 调用接收机函数，返回恢复的比特和检测到的中间参数
% 注意：根据原算法逻辑，接收端解调需要知道参考码索引 r。
% 在实际非协作通信中通常约定固定 r，但在本仿真中需传入 tx_info.r
[rx_bits, rx_info] = CSK_Receiver(r_k, tx_info.r, sys_params);

fprintf('\n=== 接收端 ===\n');
fprintf('检测结果 -> a_hat: %d, b_hat: %d, q_hat: %d\n', ...
    rx_info.a_hat, rx_info.b_hat, rx_info.q_hat);
fprintf('恢复传输比特: %s\n', num2str(rx_bits));

%% 6. 性能评估
error_num = sum(abs(tx_bits - rx_bits));
fprintf('\n=== 结果统计 ===\n');
if error_num == 0
    fprintf('SUCCESS: 比特完全恢复，传输无误。\n');
else
    fprintf('FAIL: 存在 %d 个误码。\n', error_num);
end

