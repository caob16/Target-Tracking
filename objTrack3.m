video = VideoReader('1.mp4');
frame = readFrame(video);
imshow(frame);

staticRegion = round(getPosition(imrect));

isFirstFrame = true;
firstFramePos = [];
prevFrame = rgb2gray(frame);
isCollided = false;
collidedFrame = [];

while hasFrame(video)
    frame = readFrame(video);
    grayFrame = rgb2gray(frame);
    diffFrame = imabsdiff(grayFrame, prevFrame);
    diffThresh = graythresh(diffFrame);
    binaryDiff = imbinarize(diffFrame, diffThresh);
    binaryDiff = bwareaopen(binaryDiff, 50);
    [labels, numLabels] = bwlabel(binaryDiff);

    if numLabels > 0 && isFirstFrame
        targetProps = regionprops(labels, 'BoundingBox', 'Area');
        [~, maxIdx] = max([targetProps.Area]);
        targetRegion = targetProps(maxIdx).BoundingBox;
        
        % 计算Sobel梯度
        [sobelX, sobelY] = imgradient(grayFrame, 'sobel');
        sobelMagnitude = sqrt(sobelX.^2 + sobelY.^2);
        
        % 使用梯度阈值创建直方图
        sobelThresh = 5;
        sobelMask = sobelMagnitude > sobelThresh;
        sobelBinary = binaryDiff & sobelMask;
        
        % 更新目标区域
        [labeledSobel, numSobelLabels] = bwlabel(sobelBinary);
        if numSobelLabels > 0
            sobelProps = regionprops(labeledSobel, 'BoundingBox', 'Area');
            [~, maxSobelIdx] = max([sobelProps.Area]);
            targetRegion = sobelProps(maxSobelIdx).BoundingBox;
        end
        
        isFirstFrame = false;
        firstFramePos = video.CurrentTime;
    end

    if ~isFirstFrame
        if rectint(targetRegion, staticRegion) > 0
            isCollided = true;
            collidedFrame = [collidedFrame; video.CurrentTime];
        end
        
        % 在帧上绘制目标和静态区域
        frame = insertShape(frame, 'Rectangle', targetRegion, 'LineWidth', 2);
    end
    
    frame = insertShape(frame, 'Rectangle', staticRegion, 'LineWidth', 2, 'Color', 'red');
    imshow(frame);
    prevFrame = grayFrame;
end

if isFirstFrame
    disp('Target did not enter the video!');
else
    disp(['Target entered the video at ' num2str(firstFramePos) ' seconds.']);
    if isCollided
        disp('Collision detected at the following times (seconds):');
        disp(collidedFrame);
    else
        disp('No collision detected.');
    end
end
