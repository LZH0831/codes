function Symbols1=Channel(Symbols0,L,N,M,SNR)
    [P,Block_Num]=size(Symbols0);
    Symbols1=zeros(P,Block_Num);
    pre_alpha=zeros(1,L);
    for b=1:Block_Num
        if L==1
            cur_alpha=1;%退化为AWGN信道
        else
            cur_alpha=(sqrt(1/(2*L)))*(randn(1,L)+1i*randn(1,L));
        end
        cur_block=zeros(P,1);
        for l=1:L
            Tau=l-1;
            shifted = [zeros(Tau, 1); Symbols0(1:end-Tau, b)];
            cur_block = cur_block + cur_alpha(l) * shifted;
        end
        pre_block=zeros(P,1);
        if b>1
            for l=2:L
                Tau=l-1;
                tail=Symbols0(end-Tau+1:end,b-1);
                pre_block(1:Tau)=pre_block(1:Tau)+pre_alpha(l)*tail;
            end
        end
        Symbols1(:,b)=cur_block+pre_block;
        pre_alpha=cur_alpha;
    end
    
    nr=randn(P,Block_Num);          
    ni=randn(P,Block_Num);
    theta = N * 2^M; 
    Eb = theta * (N + 1) / (N * (M + 1));  
    Noise=sqrt(Eb / SNR)*(sqrt(2)/2)*(nr+1i*ni); 
    Symbols1 = Symbols1+Noise;
end





