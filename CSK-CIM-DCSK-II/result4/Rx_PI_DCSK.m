function Bitsre = Rx_PI_DCSK(m, theta, Block_Num, Symbols1)
    M = 2^m;
    bits = m + 1;
    Bitsre_mat = zeros(bits, Block_Num);
    
    for i = 1:Block_Num
        r_ref = Symbols1(1:theta, i).';
        r_inf = Symbols1(theta+1:end, i).';
        
        D_m = zeros(1, M);
        for j = 1:M
            shift_amount = j - 1;
            
            r_ref_perm = circshift(r_ref, [0, shift_amount]);
            
            D_m(j) = sum(r_ref_perm .* r_inf); 
        end
        
        [~, max_idx] = max(abs(D_m));
        b_hat = max_idx - 1;
        q_hat = sign(D_m(max_idx));
        
        b_bits = bitget(b_hat, m:-1:1);
        q_bit = (q_hat + 1) / 2;
        Bitsre_mat(:, i) = [b_bits, q_bit].';
    end
    Bitsre = Bitsre_mat(:).';
end