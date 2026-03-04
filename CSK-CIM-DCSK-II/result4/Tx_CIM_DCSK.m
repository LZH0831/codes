function [Bits, Symbols0] = Tx_CIM_DCSK(m, theta, Block_Num)
    P = 2^m;
    R = theta / P;
    bits = m + 1; 
    Bits = randi([0, 1], bits, Block_Num);
    
    a_arr = (2.^((m-1):-1:0)) * Bits(1:m, :);
    q_arr = 2 * Bits(end, :) - 1;
    
    H = hadamard(P);
    Symbols0 = zeros(2*theta, Block_Num);
    
    for i = 1:Block_Num
        x0 = rand() * 2 - 1; 
        c = generate_chaos_seq(theta, x0);
        c = (c - mean(c)) / std(c); 
        w_a = H(a_arr(i) + 1, :);
        w_exp = kron(w_a, ones(1, R)); 
        info = q_arr(i) * (w_exp .* c); 
        Symbols0(:, i) = [c, info].';
    end
end