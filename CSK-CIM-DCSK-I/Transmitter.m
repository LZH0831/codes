function [Bits,Symbols0,r_arr]=Transmitter(m_c,m_s,theta,Block_Num,C)
    N=2^m_c;
    P=2^(m_c+1);
    beta=P*theta;
    bits=m_c+m_s+1;
    Bits=randi([0,1],1,bits*Block_Num);
    Bits2=reshape(Bits,bits,Block_Num);
    weight_c=2.^((m_c-1):-1:0);
    weight_s=2.^((m_s-1):-1:0);
    a_arr=weight_c*Bits2(1:m_c,:);
    b_arr=weight_s*Bits2(m_c+1:m_c+m_s,:);
    q_arr=2*Bits2(end,:)-1;
    H=hadamard(P);
    W=H(1:N,:);
    Symbols0=zeros(beta,Block_Num);
    r_arr=zeros(1,Block_Num);
    for b_idx=1:Block_Num
        a=a_arr(b_idx);
        b=b_arr(b_idx);
        q=q_arr(b_idx);
        if a+1<N
            r=N;
        else
            r=1;
        end
        r_arr(b_idx)=r;
        w_r=W(r,:);
        w_a=W(a+1,:);
        x0=rand();
        c0=generate_chaos_seq(theta,x0);
        c=(c0-mean(c0))/std(c0);
        Cx_shifted=circshift(c,[0,b]);
        sk=kron(w_r,c)+kron(w_a,q*Cx_shifted);
        Symbols0(:,b_idx)=sk.';
    end
    Symbols0=[Symbols0(end-C+1:end,:);Symbols0];
end