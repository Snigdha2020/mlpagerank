R = [0 1/2 0   1/2 0 1    1/2 1/2 0;
     0 0   0   0 1/2 0    0 1/2 0;
     1 1/2 1   1/2 1/2 0  1/2 0 1];
P = convertR2P(R); 

save('example1.mat','R','P')