function Symbols1 = Channel2(Symbols0, tau_vec, N, M, SNR)
    [P, Block_Num] = size(Symbols0);
    Symbols1 = zeros(P, Block_Num);
    L = length(tau_vec);  
    pre_alpha = zeros(1, L);
    for b = 1:Block_Num
        cur_alpha = sqrt(1/(2*L))*sqrt(randn(1,L).^2+randn(1,L).^2);
        cur_block = zeros(P, 1);
        for l = 1:L
            Tau = tau_vec(l); 
            shifted = [zeros(Tau, 1); Symbols0(1:end-Tau, b)];
            cur_block = cur_block + cur_alpha(l) * shifted;
        end
        pre_block = zeros(P, 1);
        if b > 1
            for l = 2:L
                Tau = tau_vec(l);
                tail = Symbols0(end-Tau+1:end, b-1);
                pre_block(1:Tau) = pre_block(1:Tau) + pre_alpha(l) * tail;
            end
        end
        Symbols1(:, b) = cur_block + pre_block;
        pre_alpha = cur_alpha;
    end
    nr=randn(P, Block_Num);          
    Eb=mean(sum(abs(Symbols0).^2))/(N*(M+1));
    Noise=sqrt(Eb/(2*SNR))*nr; 
    Symbols1=Symbols1+Noise;
end