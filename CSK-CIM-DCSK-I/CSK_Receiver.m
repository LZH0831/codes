function [recovered_bits, info] = CSK_Receiver(r_k, r_index, p)
% CSK_RECEIVER 接收机逻辑
% 输入:
%   r_k: 接收到的信号向量
%   r_index: 参考Walsh码的索引 (在原代码逻辑中，接收端解调依赖此值)
%   p: 参数结构体
% 输出:
%   recovered_bits: 恢复出的比特流
%   info: 检测到的中间变量 (a_hat, b_hat 等)

    %% 1. 准备工作
    hadamard_matrix = hadamard(p.P);
    walsh_codes = hadamard_matrix(1:p.N, :);
    w_r = walsh_codes(r_index, :); % 获取参考Walsh码

    %% 2. 接收信号分段处理
    % 将接收信号重塑为 P 行 theta 列
    r_segments = reshape(r_k, p.theta, p.P)';

    %% 3. 计算循环移位信号 (解扩过程)
    r_s = zeros(p.N, p.theta); 
    for m = 1:p.N
        temp = zeros(1, p.theta);
        for k = 1:p.P
            temp = temp + walsh_codes(m, k) * r_segments(k, :);
        end
        r_s(m, :) = temp / p.P;
    end

    %% 4. 恢复参考信号 (使用已知的参考码 w_r)
    c_x_tilde = zeros(1, p.theta);
    for k = 1:p.P
        c_x_tilde = c_x_tilde + w_r(k) * r_segments(k, :);
    end
    c_x_tilde = c_x_tilde / p.P;

    %% 5. 检测码索引 a
    % 对解扩后的各路信号进行能量检测
    I_m = zeros(1, p.N);
    for m = 1:p.N
        I_m(m) = r_s(m, :) * r_s(m, :)';  
    end
    
    % 根据原算法，排除参考码所在的通道
    I_m(r_index) = 0; 
    
    [~, a_hat_idx] = max(I_m);
    a_hat = a_hat_idx - 1; % 索引转数值 (MATLAB索引从1开始)
    
    % 提取出对应的信息载波分量
    r_inf = r_s(a_hat_idx, :);

    %% 6. 检测循环移位索引 b
    % 生成移位矩阵
    T_theta = generate_cyclic_shift_matrix(p.theta);
    
    D_n = zeros(1, p.M);
    for n = 0 : p.M-1  
        if n == 0
            c_x_shifted_local = c_x_tilde;  
        else
            c_x_shifted_local = c_x_tilde * (T_theta^n);  
        end
        % 互相关计算
        D_n(n+1) = real(c_x_shifted_local * r_inf');  
    end

    [~, b_hat_idx] = max(abs(D_n));
    b_hat = b_hat_idx - 1;

    %% 7. 检测调制符号 q
    q_hat = sign(D_n(b_hat_idx));

    %% 8. 符号到比特转换
    a_bits_hat = de2bi(a_hat, p.m_c, 'left-msb');
    b_bits_hat = de2bi(b_hat, p.m_s, 'left-msb');
    q_bit_hat = (q_hat + 1) / 2;
    
    recovered_bits = [a_bits_hat, b_bits_hat, q_bit_hat];
    
    %% 打包调试信息
    info.a_hat = a_hat;
    info.b_hat = b_hat;
    info.q_hat = q_hat;
    info.c_x_tilde = c_x_tilde; % 返回恢复的混沌用于绘图
end