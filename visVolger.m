fileName = 'Dag 10 koper 4';                     % File name.
v = VideoReader([fileName,'.mov']);    
startTime = 60;                                     % Start time in seconds.
stopTime = min(floor(v.Duration), 360+startTime);   % Stop time in seconds.
%bounds = [490 720];                                % Region bounds, where lines are situated.
thresholdL = 120;                                   % Threshold for motion detection.
numberCnts = 10;                                    % Number of consecutive frames a motion has to be detected.
%startH = 240;                                      % Line just under water surface to eliminate waves.
maxSpeed = 20;                                      % Max speed in pixels/frame, otherwise error in detection.
verboseIm = 0;                                      % Display images.
verboseTx = 1;                                      % Display text.
drawLines = 0;                                      % Draw zone boundaries.
nbFramesRegionSwitch = 20;                          % Number of frames needed to count for a region switch.
prevPart = 3;                                       % Zone initialization: lower = 3, middle = 2, upper = 1. 

%User defines bounds:
[bounds] = defineBounds(v);                 % User clicks bounds.
startH = round(bounds(1,1));                % Take rightmost water surface point.

v.CurrentTime = startTime;
prev = rgb2gray(v.readFrame());

nbFrames = (stopTime-startTime)*v.FrameRate;

poss = zeros(nbFrames,2);                   % Contains positions.
parts = zeros(3,1);                         % Contains frames in each zone (convert to , upper is index 1.
timeStill = zeros(3,1);                     % Contains frames where no detection due to no movement, sorted by region.
regions = zeros(nbFrames,1);                % Contains regions.
filteredRegions = zeros(nbFrames,1);        % Contains filtered regions.
entries = zeros(3);
cnts = zeros(numberCnts, 1);                % Contains consecutive different pixel counts.

% fig1 = figure;
% hAxes1 = gca;
%fig2 = figure;
%hAxes2 = gca;

if (verboseIm)
    h1 = imshow(prev,'InitialMagnification',60);
    drawnow;
    figure;
    b1 = bar(parts);
    drawnow;
end

if (verboseTx)
    msg = ['Time: ', num2str(v.CurrentTime)];
    fprintf(msg);
    n=numel(msg);
end

fps = zeros(1,10);
i = 1;
%prevPos = [NaN NaN];

while (v.CurrentTime <= stopTime)
    tic;
    frame = v.readFrame();
    cur = rgb2gray(frame);
    diff = abs(cur-prev);
    diffF = diff(startH:v.Height,:).*sign(floor(diff(startH:v.Height,:)/thresholdL));
    %sset(h1,'CData',diff);
    posX = 0;
    posY = 0;
    cnt = 0;
    for ii = 1 : v.Height-startH+1
       for jj = 1 : v.Width
          if (diffF(ii,jj) ~= 0)
              posX = posX + double(diffF(ii,jj))*(ii+startH-1);
              posY = posY + double(diffF(ii,jj))*jj;
              cnt = cnt + double(diffF(ii,jj));
          end
       end
    end
    posX = posX/cnt;
    posY = posY/cnt;
    
    % Check if enough consecutive movements.
    cnts = [cnt; cnts(1:numberCnts-1)];
    if (sum(1-sign(cnts)) > 2)
        posX = NaN;
        posY = NaN;
    end
    if ((posX == 0) && (posY == 0))
       posX = NaN;
       posY = NaN;
    end
    
    poss(i,:) = [posX posY];
    standStill = 0;
    if (isnan(posX) || isnan(posY))% || sqrt((prevPos(1)-posX)^2+(prevPos(2)-posY)^2) > maxSpeed)
        if (i == 1)
            if (verboseTx)
                disp(' ')
                disp('First position not found! put it at [0,0], may have effect on next positions.');
                n = 0;
            end
            %poss(i,:) = [0 0];
        else
            poss(i,:) = poss(i-1,:);
            standStill = 1;
        end
    else
        %prevPos = [posX posY];
    end
    
    %imshow(diffF);
    prev = cur;
    
    
    px = round(poss(i,1));
    py = round(poss(i,2));
    if (px > bounds(1,3)+bounds(2,3)*py)
       %parts(3) = parts(3) + 1;
       regions(i) = 3;
       prevPart = 3;
    else
        if (px > bounds(1,2)+bounds(2,2)*py)
            %parts(2) = parts(2) + 1;
            regions(i) = 2;
            prevPart = 2;
        else
            if (px > 0)
                %parts(1) = parts(1) + 1;
                regions(i) = 1;
                prevPart = 1;
            else
                if (prevPart > 0)
                    %parts(prevPart) = parts(prevPart) + 1;
                    regions(i) = prevPart;
                end
            end
        end
    end
    
    if (standStill)
        timeStill(regions(i)) = timeStill(regions(i)) + 1;
    end
    
    if (i > 2)
        if ((sqrt((poss(i-2,1)-poss(i-1,1))^2+(poss(i-2,2)-poss(i-1,2))^2) > maxSpeed) && (sqrt((poss(i-1,1)-poss(i,1))^2+(poss(i-1,2)-poss(i,2))^2) > maxSpeed))
            poss(i-1,1) = mean([poss(i-2,1),poss(i,1)]);
            poss(i-1,2) = mean([poss(i-2,2),poss(i,2)]);
        end
    end
    
    %Record entrances
    if (i > nbFramesRegionSwitch*2+1)
        if (regions(i-nbFramesRegionSwitch+1) ~= regions(i-nbFramesRegionSwitch))
            sameRegion = 1;
            for ii = i-nbFramesRegionSwitch+1 : i-1
                if (regions(ii) ~= regions(i))
                    sameRegion = 0;
                    break;
                end
            end
            if (sameRegion)
                %Entry!
                
                sameRegion = 1;
                for ii = i-nbFramesRegionSwitch*2+1 : i-nbFramesRegionSwitch-1
                    if (regions(ii) ~= regions(i-nbFramesRegionSwitch))
                        sameRegion = 0;
                        break;
                    end
                end
                if (sameRegion)
                    %entries(regions(i),regions(i-nbFramesRegionSwitch)) = entries(regions(i),regions(i-nbFramesRegionSwitch)) + 1;
                end
                filteredRegions(i-nbFramesRegionSwitch+1) = regions(i-nbFramesRegionSwitch+1);
            else
                filteredRegions(i-nbFramesRegionSwitch+1) = filteredRegions(i-nbFramesRegionSwitch);
            end
        else
            if (filteredRegions(i-nbFramesRegionSwitch) == 0)
                filteredRegions(i-nbFramesRegionSwitch+1) = median(regions(i-nbFramesRegionSwitch*2+1:i-nbFramesRegionSwitch-1));
            else
                filteredRegions(i-nbFramesRegionSwitch+1) = filteredRegions(i-nbFramesRegionSwitch);
            end
        end
        if (filteredRegions(i-nbFramesRegionSwitch+1) ~= 0)
            parts(filteredRegions(i-nbFramesRegionSwitch+1)) = parts(filteredRegions(i-nbFramesRegionSwitch+1)) + 1;
        end
    end
    
    if (drawLines)
        frame = drawBounds(frame, bounds);
    end
    
    if (verboseIm)
        for ss = max(1,i-100) : i
            pxx = round(poss(ss,1));
            pyy = round(poss(ss,2));
            for ii = pxx-1 : pxx+1
                for jj = pyy-1 : pyy+1
                    if ((ii > 0) && (ii <= v.Height) && (jj > 0) && (jj <= v.Width))
                        frame(ii,jj,:) = [255,0,0];
                    end
                end
            end
        end
        for ii = px-10 : px+10
            for jj = py-10 : py+10
                if ((ii > 0) && (ii <= v.Height) && (jj > 0) && (jj <= v.Width))
                    frame(ii,jj,:) = [255,0,0];
                end
            end
        end
        set(h1,'CData',frame);
        set(b1,'YData',parts/v.FrameRate);
        drawnow;
    end
    
    a = toc;
    fps = [fps(2:10),a];
    
    msg = ['Time: ', fixedLength(v.CurrentTime,6), ' FPS: ', fixedLength(1/mean(fps),7), ' Todo: ', fixedLength((nbFrames-i)*mean(fps)/60,4), ' min', num2str(px), ' ', num2str(py)];
    fprintf(repmat('\b', 1, n));
    fprintf(msg);
    n=numel(msg);
    
    i = i+1;
end

%poss = poss(1:i-1,:);


if (exist('fishData.csv', 'file'))
    A = readtable('fishData.csv');
    A = table2cell(A);
    Z = cell(size(A,1)+2,15);
    index = size(A,1)+2;
    for iii = 1 : size(A,1)
        for jjj = 1 : 15
            Z{iii+1,jjj} = A{iii,jjj};
        end
    end
    A = Z;
else
    A = cell(2,15);
    index = 2;
end

%% Calculate first zone 3:
for iii = 1 : length(filteredRegions)
   if (filteredRegions(iii) ~= 0)
       break;
   end
end
if (filteredRegions(iii) == 3)
   for iiii = iii : length(filteredRegions)
      if (filteredRegions(iiii) ~= 3)
         break; 
      end
   end
   waitTime = (iiii-iii+1)/v.FrameRate;
else
    waitTime = 0;
end

%% Calculate entries:
for eni = 2 : length(filteredRegions)
    if ((filteredRegions(eni) ~= 0) && (filteredRegions(eni-1) ~= 0))
        if (filteredRegions(eni) ~= filteredRegions(eni-1))
           entries(filteredRegions(eni), filteredRegions(eni-1)) = entries(filteredRegions(eni), filteredRegions(eni-1)) + 1;
        end
    end
end

%% Write data
%A = cell(2,12);
A{index,1} = fileName;
A{1,1} = 'Filename';
A{index,2} = parts(1)/v.FrameRate/(stopTime - startTime)*100;
A{1,2} = 'Percentage_in_upper_zone';
A{index,3} = parts(2)/v.FrameRate/(stopTime - startTime)*100;
A{1,3} = 'Percentage_in_middle_zone';
A{index,4} = parts(3)/v.FrameRate/(stopTime - startTime)*100;
A{1,4} = 'Percentage_in_lower_zone';
A{index,5} = entries(1,2) + entries(1,3);
A{1,5} = 'Shifts_from_middle_to_upper_zone';
A{index,6} = entries(2,1) + entries(3,1);
A{1,6} = 'Shifts_from_upper_to_middle_zone';
A{index,7} = entries(2,3) + entries(1,3);
A{1,7} = 'Shifts_from_lower_to_midle_zone';
A{index,8} = entries(3,2) + entries(3,1);
A{1,8} = 'Shifts_from_middle_to_lower_zone';
A{index,9} = timeStill(1)/v.FrameRate;
A{1,9} = 'Seconds_still_in_upper_zone';
A{index,10} = timeStill(2)/v.FrameRate;
A{1,10} = 'Seconds_still_in_middle_zone';
A{index,11} = timeStill(3)/v.FrameRate;
A{1,11} = 'Seconds_still_in_lower_zone';
A{index,12} = waitTime;
A{1,12} = 'Seconds_first_in_lower_zone';
A{index,13} = stopTime - startTime;
A{1,13} = 'Recorded_seconds';
A{index,14} = startTime;
A{1,14} = 'Start_time_seconds';
A{index,15} = stopTime;
A{1,15} = 'Stop_time_seconds';
T = cell2table(A(2:end,:),'VariableNames',A(1,:));
writetable(T,'fishData.csv');

%% Create images:
for ss = 1 : nbFrames
    pxx = round(poss(ss,1));
    pyy = round(poss(ss,2));
    for ii = pxx-1 : pxx+1
        for jj = pyy-1 : pyy+1
            if ((ii > 0) && (ii <= v.Height) && (jj > 0) && (jj <= v.Width))
                frame(ii,jj,:) = [255,0,0];
            end
        end
    end
end
frame = drawBounds(frame, bounds);
imwrite(frame,[fileName,'_path.png']);
drawRegions(filteredRegions, v.FrameRate, fileName);


function [a] = fixedLength(num, len)
    a = num2str(num);
    if (length(a) > len)
        a = a(1:len);
    else
       if (length(a) < len)
           b = zeros(1, len);
           b(1:length(a)) = a;
           for iii = length(a)+1 : len
               b(iii) = '0';
           end
           a = b;
       end
    end
end

function [] = drawRegions(regions, frameRate, fileName)
    B = 255*ones(round(length(regions)/10),length(regions),3,'uint8');
    for e = 1 : length(regions)
        r = regions(e);
        if (r == 1)
            B(1:round(round(length(regions)/10)/3),e,:) = [255*ones(round(round(length(regions)/10)/3),1), zeros(round(round(length(regions)/10)/3),2)];
        else
            if (r == 2)
                B(round(round(length(regions)/10)/3)+1:2*round(round(length(regions)/10)/3),e,:) = [zeros(round(round(length(regions)/10)/3),1), 255*ones(round(round(length(regions)/10)/3),1), zeros(round(round(length(regions)/10)/3),1)];
            else
                if (r == 3)
                    B(2*round(round(length(regions)/10)/3)+1:end,e,:) = [zeros(size(B,1)-(2*round(round(length(regions)/10)/3)+1)+1,2), 255*ones(size(B,1)-(2*round(round(length(regions)/10)/3)+1)+1,1)];
                end
            end
        end
    end
    figure;
    AX = axes;
    %imshow(B,'InitialMagnification',10);
    imshow(B, 'InitialMagnification', 100000/length(regions));
    oldTick = get(AX,'XTick');
    newTickStr = cellstr(num2str(oldTick'/frameRate));
    set(AX,'XTickLabel',newTickStr);
    axis on;
    set(AX,'YTickLabel',{'Upper','Middle','Lower'});
    set(AX,'YTick',[round(round(round(length(regions)/10)/3)/2), round(round(round(length(regions)/10)/3)/2)+round(round(length(regions)/10)/3), round(round(round(length(regions)/10)/3)/2)+2*round(round(length(regions)/10)/3)]);
    xlabel('Time [seconds]','FontSize',11);
    saveas(AX, [fileName, '_regions.png']);
end

function [bounds] = defineBounds(v)
    v.CurrentTime = round(v.Duration/2);
    frame = v.readFrame();
    f = figure;
    imshow(frame,'InitialMagnification',60);
    fprintf('Click the points on the image in this order:\n\tWater bound left\n\tWater bound right\n\tZone up-middle bound left\n\tZone up-middle bound right\n\tZone middle-bottom bound left\n\tZone middle-bottom bound right\n');
    [x, y] = ginput(6);
    close(f);
    a1 = (y(1)-y(2))/(x(1)-x(2));
    a2 = (y(3)-y(4))/(x(3)-x(4));
    a3 = (y(5)-y(6))/(x(5)-x(6));
    y1 = y(2) - x(2)*a1;
    y2 = y(4) - x(4)*a1;
    y3 = y(6) - x(6)*a1;
    bounds = [y1, y2, y3; a1, a2, a3];
end

function [f] = drawBounds(f, bounds)
    for i = 1 : size(f,2)
       f(round(bounds(1,1)+bounds(2,1)*(i-1)),i,:) = [0, 255, 0];
       f(round(bounds(1,2)+bounds(2,2)*(i-1)),i,:) = [0, 0, 255];
       f(round(bounds(1,3)+bounds(2,3)*(i-1)),i,:) = [0, 0, 255];
    end
end