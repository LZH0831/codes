function rec_bits = receiver(rx_signal, N, M, theta)
% RECEIVER MCSI-DCSK 接收机实现 (完全修正版)
% 包含：1. 复数信号处理(瑞利信道支持); 2. 索引对齐逻辑; 3. 类型修复

    [num_symbols, frame_len] = size(rx_signal);
    
    if frame_len ~= 2*theta
        error('接收信号帧长与参数不匹配');
    end
    
    bits_per_subblock = M + 1;
    total_bits = num_symbols * N * bits_per_subblock;
    rec_bits = zeros(1, total_bits);
    
    % 每个分块的大小
    block_size = theta / N; 
    
    % 逐符号处理
    for i = 1:num_symbols
        r_ref = rx_signal(i, 1:theta);
        r_inf = rx_signal(i, theta+1:end);
        
        % 2. 相关器组运算
        I = zeros(1, theta);
        
        % 遍历所有可能的移位 (1 到 theta)
        for k = 1:theta
            r_ref_shifted = circshift(r_ref, k); 
            
            % 关键：使用共轭处理瑞利信道的相位旋转
            I(k) = sum(conj(r_ref_shifted) .* r_inf);
        end
        
        % 3. 索引检测与解调
        symbol_bits = zeros(1, N * bits_per_subblock);
        
        for n = 1:N
            idx_start = (n-1) * block_size + 1;
            idx_end   = n * block_size;
            I_sub = I(idx_start : idx_end);
            
            % --- 索引检测 ---
            [~, max_local_idx] = max(abs(I_sub));
            
            % 恢复数值: 
            % 接收机遍历 k 从 1 开始，所以找到索引 1 对应数值 0
            % 发射机现在已经 +1 了，所以这里 -1 就能完美还原
            detected_map_dec = max_local_idx - 1;
            
            % --- 映射比特恢复 ---
            map_bits_rec = zeros(1, M);
            for b = 1:M
               % 使用 uint32 防止 double 类型报错
               map_bits_rec(b) = bitget(uint32(detected_map_dec), M-b+1);
            end
            % 注意：Tx 是 MSB 累加，这里解出来也要对应顺序
            % bitget(..., 1) 是 LSB。如果 b=1，M-b+1=M (高位)
            % 逻辑: b=1 (循环第一次) -> 取第 M 位 (最高位) -> 存入 map_bits_rec(1)
            % 这与 Tx 逻辑一致。
            
            % --- 符号解调 ---
            % 取峰值处的原始值
            val_at_max = I_sub(max_local_idx);
            
            if real(val_at_max) >= 0
                mod_bit_rec = 1;
            else
                mod_bit_rec = 0;
            end
            
            % 填入结果
            bit_start_pos = (n-1)*bits_per_subblock + 1;
            symbol_bits(bit_start_pos : bit_start_pos + M - 1) = map_bits_rec;
            symbol_bits(bit_start_pos + M) = mod_bit_rec;
        end
        
        rec_bits( (i-1)*length(symbol_bits)+1 : i*length(symbol_bits) ) = symbol_bits;
    end
end