function [S_k, info] = CSK_Transmitter(bit_block, p)
% CSK_TRANSMITTER 发射机逻辑
% 输入:
%   bit_block: 二进制比特向量
%   p: 参数结构体 (sys_params)
% 输出:
%   S_k: 发射信号向量
%   info: 包含 a, b, q, r 等中间变量的结构体，用于调试或辅助接收

    %% 1. 比特分组与映射
    % 1.1 码索引比特 -> a
    code_index_bits = bit_block(1 : p.m_c);
    a = bi2de(code_index_bits, 'left-msb');
    
    % 1.2 循环移位比特 -> b
    shift_index_bits = bit_block(p.m_c+1 : p.m_c+p.m_s);
    b = bi2de(shift_index_bits, 'left-msb');
    
    % 1.3 调制比特 -> q
    mod_bit = bit_block(end);
    q = 2 * mod_bit - 1;  % 0->-1, 1->+1

    %% 2. 沃尔什码生成与选择
    hadamard_matrix = hadamard(p.P);
    walsh_codes = hadamard_matrix(1:p.N, :);
    
    % 选择沃尔什码序列 (根据原逻辑)
    if a+1 < p.N
        r = p.N;  
    else
        r = 1;  
    end
    w_r = walsh_codes(r, :);       % 参考Walsh码
    w_a = walsh_codes(a+1, :);     % 信息Walsh码

    %% 3. 混沌序列生成
    % 调用外部函数 generate_chaos_sequence
    c = generate_chaos_sequence(p.theta, p.x0);

    %% 4. 循环移位操作
    % 调用外部函数 generate_cyclic_shift_matrix
    T_theta = generate_cyclic_shift_matrix(p.theta);
    
    if b == 0
        Cx_shifted = c;
    else
        Cx_shifted = c * (T_theta^b);
    end

    %% 5. 信号构建
    % Kronecker 积扩频
    S_k = kron(w_r, c) + kron(w_a, q * Cx_shifted);
    
    %% 打包调试信息
    info.a = a;
    info.b = b;
    info.q = q;
    info.r = r;
end