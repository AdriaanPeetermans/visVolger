fileName = 'Dag 0 kopercue 6';                      % File name.
v = VideoReader([fileName,'.mov']);
startTime = 121;                                    % Start time in seconds.
stopTime = min(floor(v.Duration), 60+startTime);
timeDiff = 1;                                       % Time between different frames.

regions = zeros(floor((stopTime-startTime)/timeDiff),1);
time = startTime;

v.CurrentTime = round(startTime);
frame = v.readFrame();
f = figure;
h1 = imshow(frame,'InitialMagnification',60);
global r;
r = 3;
fun = @keyPr;
set(f,'KeyPressFcn', fun);
ri = 1;

fprintf('Press uparrow when fish goes to zone above current zone.\nPress downarrow when fish goes to zone under current zone.\n');

msg = ['Region: ', num2str(r)];
fprintf(msg);

while (time < stopTime)
    v.CurrentTime = round(time);
    frame = v.readFrame();
    set(h1,'CData',frame);
    drawnow;
    time = time + timeDiff;
    regions(ri) = r;
    ri = ri + 1;
    fprintf(repmat('\b', 1, 1));
    fprintf(num2str(r));
end

filteredRegions = zeros(round(length(regions)*v.FrameRate*timeDiff),1);
for i = 1 : length(regions)
   for j = round((i-1)*timeDiff*v.FrameRate+1) : round(i*timeDiff*v.FrameRate)
      filteredRegions(j) = regions(i); 
   end
end

%% Recalculate parts:
parts = zeros(3,1);
for i = 1 : length(filteredRegions)
   if (filteredRegions(i) ~= 0)
      parts(filteredRegions(i)) = parts(filteredRegions(i)) + 1; 
   end
end

%% Read existing CSV file:
if (exist('fishData.csv', 'file'))
    A = readtable('fishData.csv');
    A = table2cell(A);
    Z = cell(size(A,1)+2,18);
    index = size(A,1)+2;
    for iii = 1 : size(A,1)
        for jjj = 1 : 18
            if (jjj > size(A,2))
                Z{iii+1,jjj} = NaN;
            else
                Z{iii+1,jjj} = A{iii,jjj};
            end
        end
    end
    A = Z;
else
    A = cell(2,18);
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
entries = zeros(3);
for eni = 2 : length(filteredRegions)
    if ((filteredRegions(eni) ~= 0) && (filteredRegions(eni-1) ~= 0))
        if (filteredRegions(eni) ~= filteredRegions(eni-1))
           entries(filteredRegions(eni), filteredRegions(eni-1)) = entries(filteredRegions(eni), filteredRegions(eni-1)) + 1;
        end
    end
end

%% Write data
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
A{index,9} = NaN;
A{1,9} = 'Seconds_still_in_upper_zone';
A{index,10} = NaN;
A{1,10} = 'Seconds_still_in_middle_zone';
A{index,11} = NaN;
A{1,11} = 'Seconds_still_in_lower_zone';
A{index,12} = waitTime;
A{1,12} = 'Seconds_first_in_lower_zone';
A{index,13} = stopTime - startTime;
A{1,13} = 'Recorded_seconds';
A{index,14} = startTime;
A{1,14} = 'Start_time_seconds';
A{index,15} = stopTime;
A{1,15} = 'Stop_time_seconds';
A{index,16} = NaN;
A{1,16} = 'Moved_pixels_in_upper_zone';
A{index,17} = NaN;
A{1,17} = 'Moved_pixels_in_middle_zone';
A{index,18} = NaN;
A{1,18} = 'Moved_pixels_in_lower_zone';
T = cell2table(A(2:end,:),'VariableNames',A(1,:));
writetable(T,'fishData.csv');

drawRegions(filteredRegions, v.FrameRate, fileName);

function keyPr(~,event)
   global r;
   if (strcmp(event.Key,'uparrow')==1)
       r = max(r-1,1);
   end
   if (strcmp(event.Key,'downarrow')==1)
       r = min(r+1,3);
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
    ticks = 0 : 10*frameRate : length(regions);
    set(AX, 'XTick', ticks);
    %oldTick = get(AX,'XTick');
    newTickStr = cellstr(num2str(ticks'/frameRate));
    set(AX,'XTickLabel',newTickStr);
    axis on;
    set(AX,'YTickLabel',{'Upper','Middle','Lower'});
    set(AX,'YTick',[round(round(round(length(regions)/10)/3)/2), round(round(round(length(regions)/10)/3)/2)+round(round(length(regions)/10)/3), round(round(round(length(regions)/10)/3)/2)+2*round(round(length(regions)/10)/3)]);
    xlabel('Time [seconds]','FontSize',11);
    saveas(AX, [fileName, '_regions.png']);
end