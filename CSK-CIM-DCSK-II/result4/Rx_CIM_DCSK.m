function Bitsre = Rx_CIM_DCSK(m, theta, Block_Num, Symbols1)
    P = 2^m; 
    R = theta / P;
    bits = m + 1;
    Bitsre_mat = zeros(bits, Block_Num);
    H = hadamard(P);
    
    for i = 1:Block_Num
        r_ref = Symbols1(1:theta, i).';
        r_inf = Symbols1(theta+1:end, i).';
        
        D_m = zeros(1, P);
        for a = 1:P
            w_a = H(a, :);
            w_exp = kron(w_a, ones(1, R));
            D_m(a) = sum((w_exp .* r_ref) .* r_inf); 
        end
        
        [~, max_idx] = max(abs(D_m));
        a_hat = max_idx - 1;
        q_hat = sign(D_m(max_idx));
        
        a_bits = bitget(a_hat, m:-1:1);
        q_bit = (q_hat + 1) / 2;
        Bitsre_mat(:, i) = [a_bits, q_bit].';
    end
    Bitsre = Bitsre_mat(:).';
end