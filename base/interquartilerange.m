function x = interquartilerange(data)

x = percentile(data, 75) - percentile(data, 25);

end