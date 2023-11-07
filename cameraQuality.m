% Read image
image = imread('image.jpg');
if size(image, 3) == 3
% Convert to grayscale image
grayImage = rgb2gray(image);
else
grayImage = image;
end

% Compute horizontal and vertical gradients using Sobel operator
Gx = imgradient(grayImage, 'Sobel', 'horizontal');
Gy = imgradient(grayImage, 'Sobel', 'vertical');

% Compute gradient magnitude
G = sqrt(Gx.^2 + Gy.^2);

% Compute average gradient magnitude
meanGradient = mean(G(:));

% Output result
fprintf('Average gradient magnitude: %.2f\n', meanGradient);