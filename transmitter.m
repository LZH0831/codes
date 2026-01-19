function [Bits,Symbols0]=Transmitter(M,N,Block_Num,C)
    theta=N*(2^M);
    P=2*(theta+C);%一个完整符号的长度
    x0=0.123456;
    Bits=randi([0,1],1,N*(M+1)*Block_Num);
    Symbols0=zeros(P,Block_Num); 
    for b=1:Block_Num
        cx0=generate_chaos_seq(theta,x0);
        cx=(cx0-mean(cx0))/std(cx0);
        idx_start=(b-1)*N*(M+1)+1;
        idx_end=b*N*(M+1);
        bits=Bits(idx_start:idx_end);
        bits2=reshape(bits,M+1,N);

        info_seq=zeros(1,theta);
        for n=1:N
            bits3=bits2(:,n);
            map_bits=bits3(1:M);
            mod_bit=bits3(end);
            local_idx=0;
            for k=1:M
                local_idx=local_idx+map_bits(k)*2^(M-k);
            end
            zn=(n-1)*(2^M)+local_idx+1;
            qn=2*mod_bit-1;
            cx2=circshift(cx,[0,zn]);
            info_seq=info_seq+qn*cx2;
        end
        ref=[cx(end-C+1:end),cx];
        info=[info_seq(end-C+1:end),info_seq];
        Symbols0(:,b)=[ref,info].';
    end
end
            



