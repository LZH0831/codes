function Symbols1=Channel(Symbols0,L,N,M,SNR)
    [P,Block_Num]=size(Symbols0);
    if L==1
        aphla=1;%退化为AWGN信道
    else
        aphla=(sqrt(1/(2*L)))*(randn(1,L)+1i*randn(1,L));
    end
    Symbols1=zeros(P,Block_Num);
    for b=1:Block_Num
        cur_block=zeros(P,1);
        for l=1:L
            Tau=l-1;
            shifted = [zeros(Tau, 1); Symbols0(1:end-Tau, b)];
            cur_block = cur_block + aphla(l) * shifted;
        end
        pre_block=zeros(P,1);
        if b>1
            for l=2:L
                Tau=l-1;
                tail=Symbols0(end-Tau+1:end,b-1);
                pre_block(1:Tau)=pre_block(1:Tau)+h(l)*tail;
            end
        end
        Symbols1(:,b)=cur_block+pre_block;
    end
    
    nr=randn(P,Block_Num);          
    ni=randn(P,Block_Num);          
    Noise=(sqrt(2)/2)*(nr+1i*ni); 
    theta = N * 2^M; 
    Eb_actual = theta * (N + 1) / (N * (M + 1));
    noise_scale = sqrt(Eb_actual / SNR);
    Symbols1 = Symbols1 + noise_scale * Noise;
end





