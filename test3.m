% 读取视频文件
video = VideoReader('1.mp4');
frame = readFrame(video);

% 转换为灰度图像
grayFrame = rgb2gray(frame);

% 初始化帧差法
prevFrame = grayFrame;

% 初始化输出视频
outputVideo = VideoWriter('output_video.avi');
open(outputVideo);

while hasFrame(video)
    % 读取当前帧并转换为灰度图像
    frame = readFrame(video);
    grayFrameNext = rgb2gray(frame);
    
    % 帧差法
    diffFrame = imabsdiff(grayFrameNext, prevFrame);
    diffThresh = graythresh(diffFrame);
    binaryDiff = imbinarize(diffFrame, diffThresh);
    binaryDiff = bwareaopen(binaryDiff, 50);
    
    % 直方图投影
    hsvFrame = rgb2hsv(frame);
    hueFrame = hsvFrame(:, :, 1);
    histHue = histcounts(hueFrame(binaryDiff), 0:1/255:1);
    hueMask = histeq(hueFrame, histHue);
    
    % 二值化直方图投影结果
    hueMask = imbinarize(hueMask, graythresh(hueMask));
    hueMask = bwareaopen(hueMask, 50);
    
    % 使用区域属性检测移动目标
    [labeledRegions, numRegions] = bwlabel(hueMask);
    regionProps = regionprops(labeledRegions, 'Centroid', 'BoundingBox', 'Area');

    % 提取面积最大的目标
    if numRegions > 0
        [~, maxAreaIdx] = max([regionProps.Area]);
        target = regionProps(maxAreaIdx);
        
        % 将检测到的目标叠加在原始帧上
        frameWithTarget = frame;
        frameWithTarget = insertShape(frameWithTarget, 'Rectangle', target.BoundingBox, 'LineWidth', 2, 'Color', 'green');
        frameWithTarget = insertMarker(frameWithTarget, target.Centroid, 'x', 'Color', 'red', 'Size', 8);
    else
        frameWithTarget = frame;
    end
    
    % 显示结果
    imshow(frameWithTarget);
    drawnow;
    
    % 将当前帧添加到输出视频中
    writeVideo(outputVideo, frameWithTarget);
    
    % 更新灰度图像
    prevFrame = grayFrameNext;
end

% 关闭输出视频
close(outputVideo);