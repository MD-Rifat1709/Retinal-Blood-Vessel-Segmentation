function img = post(img,w)
slratio = (1/pi) * sqrt( (log(2)/2) ) * ( ((2^1)+1) / ((2^1)-1) );
sigma = slratio*w;
phi=[-pi pi];
[img,theta,sigma] = readandinit (img, 0, 24, sigma, w, 1);
img = gaborfilter(img, w, sigma, theta, phi, 0.5, 1);
img = calc_halfwaverect(img, theta, phi, 10);
img = calc_phasessuppos(img, theta, phi, 2);
img = calc_inhibition(img, 2, 3, sigma, 1, 1, 4);
dispcomb = data(theta);
img = calc_viewimage(img, dispcomb, theta);
img = calc_hysteresis(img, 1, 0.075, 0.15);
end

