function c = generate_chaos_sequence(len, x0)
    if nargin < 2
        x0 = 0.6;  % 初始值
    end
    c = zeros(1, len);
    x = x0;
    for n = 1:len
        x = 1 - 2 * x^2;   % 零均值 Logistic 映射
        c(n) = x;
    end
end