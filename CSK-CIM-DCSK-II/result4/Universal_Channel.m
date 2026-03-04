function Symbols1 = Universal_Channel(Symbols0, L, SNR, bits_per_sym)
    [frame_len, Block_Num] = size(Symbols0);
    Symbols1 = zeros(frame_len, Block_Num);
    pre_alpha = zeros(1, L); 
    
    for b = 1:Block_Num
        if L == 1
            cur_alpha = 1;
        else
            cur_alpha = sqrt(1/(2*L)) * sqrt(randn(1, L).^2 + randn(1, L).^2);
        end
        
        cur_block = zeros(frame_len, 1);
        for l = 1:L
            Tau = l - 1;
            shifted = [zeros(Tau, 1); Symbols0(1:end-Tau, b)];
            cur_block = cur_block + cur_alpha(l) * shifted;
        end
        pre_block = zeros(frame_len, 1);
        if b > 1
            for l = 2:L
                Tau = l - 1;
                tail = Symbols0(end-Tau+1:end, b-1);
                pre_block(1:Tau) = pre_block(1:Tau) + pre_alpha(l) * tail;
            end
        end
        
        Symbols1(:, b) = cur_block + pre_block;
        pre_alpha = cur_alpha;
    end

    Eb = mean(sum(abs(Symbols0).^2)) / bits_per_sym;
    nr = randn(frame_len, Block_Num);
    Noise = sqrt(Eb / (2 * SNR)) * nr;
    Symbols1 = Symbols1 + Noise;
end