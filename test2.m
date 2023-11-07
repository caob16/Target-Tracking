% read video file
video = VideoReader('1.mp4');
frame = readFrame(video);
% define static area
imshow(frame);
staticRegion = round(getPosition(imrect));
% Convert to grayscale image
grayFrame = rgb2gray(frame);
% Initialize the frame difference method
prevFrame = grayFrame;
% Initialize the output video
outputVideo = VideoWriter('output_video.avi');
open(outputVideo);
% Flag variable, record whether it is the first frame
isFirstFrame = true;
% is used to save the position of a frame where the object first enters the video
firstFramePos = [];
% is used to save the position of the frame where the collision occurred
collidedFrames = [];
% Initialize the counter
frameCounter = 1;
while hasFrame(video)
    % Read current frame and convert to grayscale image
    frame = readFrame(video);
    grayFrameNext = rgb2gray(frame);
    % If the current frame is a multiple of 3, perform target detection and tracking
    if mod(frameCounter, 3) == 0
        % frame difference method
        diffFrame = imabsdiff(grayFrameNext, prevFrame);
        diffThresh = graythresh(diffFrame);
        binaryDiff = imbinarize(diffFrame, diffThresh);
        binaryDiff = bwareaopen(binaryDiff, 50);
        % Histogram projection
        hsvFrame = rgb2hsv(frame);
        hueFrame = hsvFrame(:, :, 1);
        histHue = histcounts(hueFrame(binaryDiff), 0:1/255:1);
        hueMask = histeq(hueFrame, histHue);
        % Binarized histogram projection results
        hueMask = imbinarize(hueMask, graythresh(hueMask));
        hueMask = bwareaopen(hueMask, 50);
        % Detect moving objects using area attributes
        [labeledRegions, numRegions] = bwlabel(hueMask);
        regionProps = regionprops(labeledRegions, 'Centroid', 'BoundingBox', 'Area');
        % Extract the object with the largest area
        if numRegions > 0
            [~, maxAreaIdx] = max([regionProps.Area]);
            target = regionProps(maxAreaIdx);
            % If it is the first frame, record the position of the frame where the object first entered the video
            if isFirstFrame
                isFirstFrame = false;
                firstFramePos = video.CurrentTime;
            end            
            % Determine whether the target enters the static area
            if rectint(target.BoundingBox, staticRegion) > 0
                collidedFrames = [collidedFrames; video.CurrentTime];
            end        
            % Superimpose the detected objects on the original frame
            frameWithTarget = frame;
            frameWithTarget = insertShape(frameWithTarget, 'Rectangle', target.BoundingBox, 'LineWidth', 2, 'Color', 'green');
            frameWithTarget = insertMarker(frameWithTarget, target.Centroid, 'x', 'Color', 'red', 'Size', 8);
          else
              frameWithTarget = frame;
        end
        % update grayscale image
        prevFrame = grayFrameNext;
     end
     % Superimpose the static area on the original frame
     frameWithTarget = insertShape(frameWithTarget, 'Rectangle', staticRegion, 'LineWidth', 2, 'Color', 'red');
     % Show results
     imshow(frameWithTarget);
     drawnow;
     % Add current frame to output video
     writeVideo(outputVideo, frameWithTarget);
     % Increment frame counter
     frameCounter = frameCounter + 1;
end
% close output video
close(outputVideo);
if isFirstFrame
    disp('Target did not enter the video!');
else
    disp(['Target entered the video at ' num2str(firstFramePos) ' seconds.']);
end
if ~isempty(collidedFrames)
    disp('Target collided with the static region at the following times:');
    disp(collidedFrames);
else
    disp('Target did not collide with the static region.');
end

