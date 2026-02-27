function T = generate_cyclic_shift_matrix(n)
    % 生成n×n的循环移位矩阵
    T = zeros(n);
    for i = 1:n-1
        T(i, i+1) = 1;
    end
    T(n, 1) = 1;
end