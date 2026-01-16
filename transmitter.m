function tx_signal = transmitter(bits, N, M, theta, chaos_seq)
% TRANSMITTER MCSI-DCSK 发射机实现 (修正版)
% 修正了移位索引从 1 开始，与接收机对齐

    % 1. 参数校验与重塑
    bits_per_subblock = M + 1;
    bits_per_symbol = N * bits_per_subblock;
    
    num_bits = length(bits);
    num_symbols = num_bits / bits_per_symbol;
    
    if floor(num_symbols) ~= num_symbols
        error('输入比特长度必须是 N(M+1) 的整数倍');
    end
    
    % 将比特流重塑为: [符号数, N*(M+1)]
    bits_reshaped = reshape(bits, bits_per_symbol, num_symbols).';
    
    % 预分配输出矩阵
    tx_signal = zeros(num_symbols, 2 * theta);
    
    % 2. 符号生成循环
    for i = 1:num_symbols
        current_bits = bits_reshaped(i, :);
        info_bearing_signal = zeros(1, theta);
        
        % 3. 分组处理
        for n = 1:N
            % 提取第 n 组的比特
            group_bits = current_bits( (n-1)*bits_per_subblock + 1 : n*bits_per_subblock );
            
            % --- 映射比特 (前 M 位) -> 循环移位索引 ---
            map_bits = group_bits(1:M);
            
            % 二进制转十进制 (MSB first)
            local_idx = 0;
            for b = 1:M
                local_idx = local_idx + map_bits(b) * 2^(M-b); 
            end
            
            % --- 计算全局移位量 ---
            % 关键修改：必须 +1，使移位范围变为 [1, theta]
            % 这样接收机检查 k=1 时，才能对应上 local_idx=0
            block_size = theta / N;
            global_shift = (n-1) * block_size + local_idx + 1; 
            
            % --- 调制比特 ---
            mod_bit = group_bits(end);
            q_n = 2 * mod_bit - 1; % 1 -> +1, 0 -> -1
            
            % --- 循环移位与调制 ---
            shifted_seq = circshift(chaos_seq, global_shift);
            
            % --- 叠加 ---
            info_bearing_signal = info_bearing_signal + q_n * shifted_seq;
        end
        
        % 4. 帧构建
        tx_signal(i, :) = [chaos_seq, info_bearing_signal];
    end

end