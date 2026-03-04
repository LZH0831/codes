function [Bits, Symbols0] = Tx_PI_DCSK(m, theta, Block_Num)
    bits = m + 1;
    Bits = randi([0, 1], bits, Block_Num);

    b_arr = (2.^((m-1):-1:0)) * Bits(1:m, :);
    q_arr = 2 * Bits(end, :) - 1;
    
    Symbols0 = zeros(2*theta, Block_Num);
    for i = 1:Block_Num
        x0 = rand() * 2 - 1; 
        c = generate_chaos_seq(theta, x0);
        c = (c - mean(c)) / std(c); 
        c_perm = circshift(c, [0, b_arr(i)]); 
        info = q_arr(i) * c_perm;
        Symbols0(:, i) = [c, info].';
    end
end