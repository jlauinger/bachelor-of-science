clear all; close all;

t = 0:5e-1:10;
x = sin(t);

figure(1);
hold on;
plot(t, x, 'b');

d1 = fdesign.fracdelay(0.5, 1);
Hd1 = design(d1, 'lagrange', 'filterstructure', 'farrowfd');
y = filter(Hd1, x);

plot(t, y, 'r');

d2 = fdesign.fracdelay(0.999, 1);
Hd2 = design(d2, 'lagrange', 'filterstructure', 'farrowfd');
z = filter(Hd2, x);

plot(t, z, 'g');

cy = xcorr(x, y);
cz = xcorr(x, z);

Cy = cy(ceil(length(cy)/2));
Cz = cz(ceil(length(cz)/2));
fprintf(1, "Cy: %f + %fi\nCz: %f + %fi\n", real(Cy), imag(Cy), real(Cz), imag(Cz));

figure(2);
axis square;
plot(real([Cy Cz 0]), imag([Cy Cz 0]), 'o');