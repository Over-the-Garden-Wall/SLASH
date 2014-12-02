
function outstr = format_num(num, digits)

    outstr = num2str(num);
    outstr = ['0' * ones(1,digits-length(outstr)), outstr];
end