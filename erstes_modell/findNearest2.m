function idx = findNearest2(v, A)
    if size(v, 1) == size(A, 1)
        D = sum((A - repmat(v,1,size(A,2))).^2, 1);
        [~, idx] = min(D);
    else
        idx = NaN;
    end
end