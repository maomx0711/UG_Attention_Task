% Ultimatum Game with Psychtoolbox
% Clear the workspace and close all windows

% 情绪效价可以去除，
% 矩形起始点放中间

clear all;
clc;
% sca;  % 关闭所有 Psychtoolbox 窗口
% clear Screen;  % 清除 Psychtoolbox 的缓存

% set(0,'DefaultAxesFontName','宋体');%注意检查
% slCharacterEncoding('UTF-8');
% PsychDefaultSetup(2);
Screen('Preference','TextEncodingLocale','UTF8');
%%
gr_x=600;
gr_y=600;
lum1=127;
   lum2=80;
   LUMINNACE=127;
   Orientation1=90;
   Orientation2=-Orientation1;
bar_leng=60;
bar_wid=4;
bar_lum=255;
size=60;
%%%%%%%%%%%%%
%%
% 定义试次数量
TrialNum=280;
BothNum=210;
SubNum=20;
OthNum=20;
WrongNum=30;
Gap_points=21;
reception=10;
%
Happend_num=32;%1,2,4,8,16,32;32对应第6次的时候让被试自己分配


sn=zeros(24,TrialNum);%记录每个折扣点出现的数量，一共12种情况
rest=144;%中途休息
%%
KbName('UnifyKeyNames');
ID=input('SubName: ','s');
runNum=input('runNum: ');
%% fair evelate
RateP1=imread('equality_rate.jpg');
RateP=uint8(mean(RateP1,3));
rateP_height=length(RateP(:,1));
rateP_width=length(RateP);
%%
result=zeros(23,TrialNum);
Screen('Preference', 'SkipSyncTests', 1);
leftKey=KbName('n');% '2#' left% up
rightKey=KbName('m');% '1$' right% down
breakKey=KbName('space');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% get screen
Screens=Screen('Screens');
ScreenNumber=max(Screens);
%HideCursor
% open a black screen
Black=BlackIndex(ScreenNumber);
white=WhiteIndex(ScreenNumber);
Black=(Black+white)/2;
[w,wRect]=Screen('OpenWindow',ScreenNumber,Black);
Screen('TextFont',w,'Microsoft YaHei');
Screen('TextSize',w,24);
FixationRect=CenterRect([0,0,6,6],[0,0,1920,1080]);

EscapeKey = KbName('q');
TriggerKey = KbName('s');
Text='Waiting for the trigger to start...';
%%
ground=uint8(ones(gr_x,gr_y,3))*LUMINNACE;
ground(gr_x/2:gr_x/2+2,(gr_y/2-9):(gr_y/2+11),:)=255;
ground((gr_x/2-9):(gr_x/2+11),gr_y/2:gr_y/2+2,:)=255;
att=Screen('MakeTexture',w,ground);

%%
Type_set=[ones(1,BothNum),2*ones(1,SubNum),3*ones(1,OthNum),4*ones(1,WrongNum)];
%%
present_set={'19','20','21'};
answer_text1=double('更少');
answer_text2=double('更多');
wait_text=double('等待双方回答');
feed_text1=double('你：正确');
feed_text2=double('你：错误');
feed_text3=double('TA：正确');
feed_text4=double('TA：错误');
choice_you=double('你获得');
choice_he=double('Ta获得');
respond_text=double('接受或者拒绝');
Self_text=double('自己分配');
yuan=double('元');
text_color=[255 255 255];
%%
nn1=0;
nn2=0;
nn3=0;
nn4=0;
Money_set=[60,65];%分配金额总额
discount_rates=repmat([0.5:-0.02:0.1],1,reception);%折扣集
discount_types=repmat([21:-1:1],1,reception);
% Both_reward_pics=repmat(Both_reward,1,3);
% random_discount=randperm(discount_rates);
take_all=1;
take_nothing=0;
Both_nothing=-1;
% both_nothing='0';wRect(3)=1920;wRect(4)=1080;
position_left_x=wRect(3)/2-300;
position_left_y=wRect(4)/2+300;
position_right_x=wRect(3)/2+300;
position_right_y=wRect(4)/2+300;
position_left_up_x=wRect(3)/2-280;
position_left_up_y=wRect(4)/2-150;
position_left_down_x=wRect(3)/2-275;
position_left_down_y=wRect(4)/2+50;
position_right_up_x=wRect(3)/2+275;
position_right_up_y=wRect(4)/2-150;
position_right_down_x=wRect(3)/2+275;
position_right_down_y=wRect(4)/2+50;
position_center_x=wRect(3)/2-80;
position_center_y=wRect(4)/2+260;
position_mid_up_x=wRect(3)/2-80;
position_mid_up_y=wRect(4)/2+60;
%%
% 3. 设置矩形的颜色（RGB值）
rectColor = [255 255 0];  % 黄色
rect_high=30;
rect_width=400;
rect_he_x=wRect(3)/2-140;
rect_he_y=wRect(4)/2-175;
rect_you_x=wRect(3)/2-140;
rect_you_y=wRect(4)/2+25;
rect_give_x=wRect(3)/2-140;
rect_give_y=wRect(4)/2+250;

% 4. 设置矩形的大小和位置 [left, top, right, bottom]
    res_text='剩余总额：';
    give_text='增加金额：';
    punish_text='减少金额：';
    
    begin_point=0;
    present_begin_x=wRect(3)/2-210;
present_begin_y=wRect(4)/2+275;
present_end_x=wRect(3)/2+275;
present_end_y=wRect(4)/2+275;
present_give_x=wRect(3)/2-140;
present_give_y=wRect(4)/2+330;
present_punish_x=wRect(3)/2+170;
present_punish_y=wRect(4)/2+330;
present_res_x=wRect(3)/2-440;
present_res_y=wRect(4)/2+330;   
% Set text size
%Screen('TextSize', window, 50);

% 获取屏幕的宽度和高度
% [screenXpixels, screenYpixels] = Screen('WindowSize', w);
screenXpixels=wRect(3);
screenYpixels=wRect(4);
% 设置圆点的颜色为白色
dotColor = [255 255 255];
%%
main_order=randperm(TrialNum);
Both_reward_order=randperm(BothNum);
%% response slider
windowWidth = wRect(3);
windowHeight = wRect(4);
% 缁樺埗璇勫垎婊戝姩鏉?
sliderX = windowWidth/2 - 280;
sliderY = windowHeight/2 + 270;
sliderWidth = windowWidth/2 + 320;
sliderHeight = sliderY + 40;
%% plot dotted line
        % Dot Position
        % 瀹氫箟鍨傜洿铏氱嚎鐨勫弬鏁?
        x_l = windowWidth / 2 + 20; % 铏氱嚎鐨?x 鍧愭爣
        y1 = sliderY; % 璧风偣 y 鍧愭爣
        y2 = sliderHeight; % 缁堢偣 y 鍧愭爣
        lineWidth = 2; % 绾垮
        dashLength = 5; % 铏氱嚎娈电殑闀垮害
        gapLength = 2; % 铏氱嚎娈典箣闂寸殑闂撮殧
        % 璁＄畻铏氱嚎鐨勬鏁?
        lineLength = y2 - y1;
        numDashes = floor(lineLength / (dashLength + gapLength));
        remainingLength = lineLength - numDashes * (dashLength + gapLength);

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Screen('FillRect',w,Black,wRect);
Screen('FillOval',w,[255 255 0], FixationRect);
Screen('DrawText',w,Text,20,20,[255 255 0]);
Screen('Flip',w);
%
% BackGRect=Screen('Rect',att);%%锛?
BackGRect=[2,2,590,658];
[touch, secs, keyCode] = KbCheck;
touch =0;

while ~(touch && (keyCode(TriggerKey)))
    [touch, secs, keyCode] = KbCheck;
end
if keyCode(EscapeKey)
    Screen('CloseAll');
end
%% pre fixation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
t0=GetSecs;
Screen('DrawTexture',w,att,BackGRect);%鍒掑畾鑼冨洿锛?
Screen('Flip',w);
while GetSecs<3.000+t0 %%% 4s
    ;
end
%%
for trial=1:TrialNum
    t=GetSecs;
    Screen('DrawTexture',w,att,BackGRect);
    Screen('Flip',w);
    while GetSecs-t<0.5+1*rand(1);  %1500~500ms
        ;
    end
    %%  Target
    t_circle=GetSecs;
    numDots =20;
    % 随机生成圆点的坐标 (2行, 每列对应一个圆点)
     dotPositions = (0.25*rand(2, numDots)+0.4) .* repmat([screenXpixels; screenYpixels],1,numDots);
    % 设置圆点的大小（例如在5到20像素之间）
     dotSizes = randi([5, 10], 1);
    % 绘制圆点
    Screen('DrawDots', w, dotPositions, dotSizes, dotColor, [], 2);
    Screen('Flip',w);
    while GetSecs-t_circle<1.5
        ;
    end
    
    present_num=present_set{rem(main_order(trial),3)+1};
%     Screen('FillRect',w,Black,wRect);
    DrawFormattedText(w,present_num,wRect(3)/2-10,wRect(4)/2-10,[255 255 255]);
    DrawFormattedText(w,answer_text1,position_left_x,position_left_y,[255,255,255]);
    DrawFormattedText(w,answer_text2,position_right_x,position_right_y,[255,255,255]);
    Screen('Flip',w);  
    
    keyCode=zeros(1,256);
    keyIsDown=0;
    a=0;
%     Tar_t=GetSecs;
    t_dot=GetSecs;
   while 1;%until response
         [keyIsDown, secs, keyCode] = KbCheck;
         if  (~a)&&(keyCode(leftKey)||keyCode(rightKey)||keyCode(EscapeKey))
                    a=1;
                    if keyCode(rightKey)
                        result(2,trial)=2;%right means more
                    elseif keyCode(leftKey)
                        result(2,trial)=1;% left means less
                    end
                    if keyCode(EscapeKey)
                        Screen('Closeall');
                    end
                    result(3,trial)=GetSecs-t_dot;  
                    break
         end
     
   end
    t=GetSecs;
    Screen('FillRect',w,Black,wRect);
    if result(2,trial)==1%left less
    DrawFormattedText(w,answer_text1,position_left_x,position_left_y,[255 255 255]);%365jqq
    Screen('Flip',w);
        while GetSecs-t<1;  %3s(0.5鍒?绉掞級
          ;  
         end
    elseif result(2,trial)==2%right more
    DrawFormattedText(w,answer_text2,position_right_x,position_right_y,[255 255 255]);%834
      Screen('Flip',w);
       while GetSecs-t<1;  %3s(0.5鍒?绉掞級
          ;  
        end
    end
    
    %
    tt0=GetSecs;
    DrawFormattedText(w,wait_text,position_center_x,position_center_y-200,[255 255 255]);%365jqq
    Screen('Flip',w);
    while GetSecs-tt0<3+1*rand(1);  %3s(0.5鍒?绉掞級
          ;  
    end
   %%
    type=Type_set(main_order(trial));
    result(1,trial)=main_order(trial);
    total_money=randi(Money_set);  
    if type==1
        nn1=nn1+1;
        discount=discount_rates(Both_reward_order(nn1));
        discount_type=discount_types(Both_reward_order(nn1));
        feed_down=feed_text1;
        feed_up=feed_text3;
        money_you=total_money*discount;
        money_he=total_money*(1-discount);
       % 5. 绘制矩形
       rectPosition_he = [rect_he_x, rect_he_y, rect_he_x+rect_width*(1-discount),rect_he_y+rect_high ];
       rectPosition_you = [rect_you_x, rect_you_y, rect_you_x+rect_width*(discount), rect_you_y+rect_high];% 矩形左上角坐标 (100, 100)，右下角坐标 (300, 200)

    elseif type==2
        nn2=nn2+1;
        discount=take_all;
        discount_type=Gap_points+3;%you get all reward
        feed_down=feed_text1;
        feed_up=feed_text4;
        money_you=total_money*discount;
        money_he=total_money*(1-discount);
        rectPosition_he = [rect_he_x, rect_he_y, rect_he_x+rect_width*(1-discount),rect_he_y+rect_high ];
        rectPosition_you = [rect_you_x, rect_you_y, rect_you_x+rect_width*(discount), rect_you_y+rect_high];% 矩形左上角坐标 (100, 100)，右下角坐标 (300, 200)
    elseif type==3
        nn3=nn3+1;
        discount=take_nothing;
        discount_type=Gap_points+2;%other get all reward
        feed_down=feed_text2;
        feed_up=feed_text3;
        money_you=total_money*discount;
        money_he=total_money*(1-discount);
        rectPosition_he = [rect_he_x, rect_he_y, rect_he_x+rect_width*(1-discount),rect_he_y+rect_high ];
        rectPosition_you = [rect_you_x, rect_you_y, rect_you_x+rect_width*(discount), rect_you_y+rect_high];% 矩形左上角坐标 (100, 100)，右下角坐标 (300, 200)
    elseif type==4
        nn4=nn4+1;
        feed_down=feed_text2;
        feed_up=feed_text4;
        discount=-1;
        discount_type=Gap_points+1;%both get o reward
        money_you=0;
        money_he=0;
        rectPosition_he = [0, 0, 0,0 ];
        rectPosition_you = [0,0, 0, 0];  
    end
    if discount_type >= 1 && discount_type <= 24
        sn(discount_type,trial) = sum(sn(discount_type,:)) + 1;
    end

   %% Slider
    feed_you=double([num2str(money_you),yuan]);
    feed_he=double([num2str(money_he),yuan]);
    end_point=total_money;
    %% 
    t=GetSecs;
    Screen('DrawTexture',w,att,BackGRect);
    Screen('Flip',w);
    while GetSecs-t<0.5+1*rand(1);  %1500~500ms
        ;
    end  
    DrawFormattedText(w,feed_down,position_left_down_x-100,position_left_down_y+100,text_color); % 浣犲湪鐐逛及璁′换鍔′腑鐨勭粨鏋?
    DrawFormattedText(w,feed_up,position_left_up_x-100,position_left_up_y,text_color); % TA鍦ㄧ偣浼拌浠诲姟涓殑缁撴灉
    DrawFormattedText(w,feed_you,position_right_down_x,position_right_down_y+100,text_color); % 浣犳墍寰楅噾棰?
    DrawFormattedText(w,feed_he,position_right_up_x,position_right_up_y,text_color); % TA鎵?緱閲戦
    Screen('Flip', w);
    %%
    % 缁樺埗婊戝潡
    knobRadius = (sliderWidth - sliderX) ;
    % 绛夊緟鎸夐敭
    rr = knobRadius/2;  % 姣忔鎸夐敭绉诲姩鐨勬闀?step = (sliderWidth - sliderX)/10;
    keyCode=zeros(1,256);
    keyIsDown=0;
    Rate_t=GetSecs;
    while GetSecs-Rate_t<50.0 % 30.0s  
        Screen('FillRect', w, rectColor, rectPosition_he);
        Screen('FillRect', w, rectColor, rectPosition_you);
        [keyIsDown, secs, keyCode] = KbCheck;
         [x, y, buttons] = GetMouse(w);
         if keyCode(breakKey)          
            result(5,trial)=GetSecs-Rate_t; % decision time
            break;
        end
        
        if any(buttons)
            if x >= sliderX && x <= sliderWidth && y >= sliderY && y <= sliderHeight
                rr=x-sliderX;
                if rr<=0
                    rr=0;
                elseif rr>knobRadius
                    rr=knobRadius;
                end
            end
        end
        score = rr/knobRadius; % 璁＄畻璇勫垎鍊?
        %%
        % Slider Display
        Screen('FillRect', w, [150 150 150], [sliderX, sliderY, sliderWidth, sliderHeight]); % 缁樺埗婊戝姩鏉¤儗鏅?
        Screen('FillRect', w, [255 255 255], [sliderX, sliderY, sliderX + rr, sliderHeight]); % 缁樺埗婊戝潡
        % Text Display
        DrawFormattedText(w,feed_down,position_left_down_x,position_left_down_y,text_color); % 浣犲湪鐐逛及璁′换鍔′腑鐨勭粨鏋?
        DrawFormattedText(w,feed_up,position_left_up_x,position_left_up_y,text_color); % TA鍦ㄧ偣浼拌浠诲姟涓殑缁撴灉
        DrawFormattedText(w,feed_you,position_right_down_x,position_right_down_y,text_color); % 浣犳墍寰楅噾棰?
        DrawFormattedText(w,feed_he,position_right_up_x,position_right_up_y,text_color); % TA鎵?緱閲戦
        % Willings of acception_Rating
        RejectText = double('完全拒绝');
        AcceptText = double('完全同意');
        RejectScore = double('0');
        %%%%% MidScore = double('0.5');
        AcceptScore = double('1');

        % Text_Rating
        DrawFormattedText(w, RejectText, windowWidth/2 - 310, windowHeight/2 + 200, [0,0,0]);
        DrawFormattedText(w, AcceptText, windowWidth/2 + 290, windowHeight/2 + 200, [0,0,0]);
        DrawFormattedText(w, RejectScore, windowWidth/2 - 280, windowHeight/2 + 255, [0,0,0]);
        %%%%% DrawFormattedText(w, MidScore, windowWidth/2 + 20, windowHeight/2 + 255, [0,0,0]);
        DrawFormattedText(w, AcceptScore, windowWidth/2 + 320, windowHeight/2 + 255, [0,0,0]);
        % plot dotted line
        if score<0.5
            line_color=[0,255,0];
        else
            line_color=[255,255,0];
        end   
        currentY = y1;
        for i = 1:numDashes
            % line step by step
            Screen('FillRect', w, line_color, [x_l - lineWidth/2, currentY, x_l + lineWidth/2, currentY + dashLength]);
            currentY = currentY + dashLength + gapLength;
        end
        % 缁樺埗鍓╀綑閮ㄥ垎
        if remainingLength > 0
            Screen('FillRect', w, line_color, [x_l - lineWidth/2, currentY, x_l + lineWidth/2, currentY + remainingLength]);
        end
        Screen('Flip', w);
    end
    result(17,trial)=score;
%% < 0.5 means reject && > 0.5 means accept
    if result(17,trial)<0.5 % Reject
        result(4,trial)=0;
        Screen('FillRect',w,Black,wRect);
        feed_no=double([num2str(0),yuan]); % 0 yuan
        DrawFormattedText(w,choice_you,position_left_down_x,position_left_down_y,text_color); % 浣犲湪鐐逛及璁′换鍔′腑鐨勭粨鏋?
        DrawFormattedText(w,choice_he,position_left_up_x,position_left_up_y,text_color); % TA鍦ㄧ偣浼拌浠诲姟涓殑缁撴灉
        DrawFormattedText(w,feed_no,position_right_down_x,position_right_down_y,[0,255,0]);
        DrawFormattedText(w,feed_no,position_right_up_x,position_right_up_y,[0,255,0]); 
    elseif result(17,trial)>=0.5 % Accept
        result(4,trial)=1;
        Screen('FillRect',w,Black,wRect);
        DrawFormattedText(w,choice_you,position_left_down_x,position_left_down_y,text_color); % 浣犲湪鐐逛及璁′换鍔′腑鐨勭粨鏋?
        DrawFormattedText(w,choice_he,position_left_up_x,position_left_up_y,text_color); % TA鍦ㄧ偣浼拌浠诲姟涓殑缁撴灉
        DrawFormattedText(w,feed_you,position_right_down_x,position_right_down_y,[255,255,0]);
        DrawFormattedText(w,feed_he,position_right_up_x,position_right_up_y,[255,255,0]);      
    end
    Screen('Flip',w);

    %%ITI
    tt1=GetSecs;
    while GetSecs-tt1<1
        ;
    end

    result(6,trial)=discount_type;
    result(7,trial)=discount;
    result(8,trial)=total_money;
    result(9,trial)=money_you;
    result(10,trial)=money_he;
   %%

if any(sn(1:24, trial) == Happend_num)
    
DrawFormattedText(w,Self_text,position_mid_up_x,position_mid_up_y,[0,0,255]);
Screen('Flip',w);
self_t=GetSecs;
while GetSecs-self_t<1
    ;
end
gg=0; 
t4=GetSecs;
keyCode=zeros(1,256);
keyIsDown=0;
secs=GetSecs;
while GetSecs-t4<60.0 % 50.0s
% while 1
        [keyIsDown, secs, keyCode] = KbCheck;      
         [x, y, buttons] = GetMouse(w);
         if keyCode(breakKey)
             result(16,trial)=GetSecs-t4;%决策时间，decision time
             break
         end
         if any(buttons)
            if x >= rect_you_x && x <= rect_you_x+400 && y >= rect_you_y && y <= rect(4)
                gg=gg-x-rect_you_x;
               if gg<=0
                  gg=0;
               elseif gg>=400
                   gg=400;
               end
            end

         end
%   res_money=all_money-(gg/400)*4;

  price=(gg/400)*total_money;
  give_point=price;
  punish_point=price;  
% present_allmoney=double([num2str(All_money),yuan]);

DrawFormattedText(w,feed_down,position_left_down_x,position_left_down_y,text_color);
DrawFormattedText(w,feed_up,position_left_up_x,position_left_up_y,text_color);
DrawFormattedText(w,feed_you,position_right_down_x,position_right_down_y,text_color);
DrawFormattedText(w,feed_he,position_right_up_x,position_right_up_y,text_color);

Screen('FillRect', w, [255,0,0], rectPosition_he);
Screen('FillRect', w, rectColor, rectPosition_you);
if type ==4
rectPosition_he = [0, 0, 0,0 ];
rectPosition_you =[rect_you_x, rect_you_y, rect_you_x+gg, rect_you_y+rect_high];% 矩形左上角坐标 (100, 100)，右下角坐标 (300, 200)
punish_point=0;
give_text='增加金额：';
punish_text='减少金额：';
    you_m=money_you+price;
    he_m=money_he-price;
    if you_m>=total_money
        you_m=total_money;     
    end
    feed_you=double([num2str(you_m),yuan]);  
    if he_m<=0
        he_m=0;   
    end
    feed_he=double([num2str(he_m),yuan]);
elseif type==2
rectPosition_he = [rect_he_x, rect_he_y, rect_he_x+rect_width*(1-discount)+gg,rect_he_y+rect_high ];
rectPosition_you = [rect_you_x, rect_you_y, rect_you_x+rect_width*(discount)-gg, rect_you_y+rect_high];% 矩形左上角坐标 (100, 100)，右下角坐标 (300, 200)   
give_text='减少金额：';%反过来了，更合理一点
punish_text='增加金额：';
    you_m=money_you-price;
    he_m=money_he+price;
    if you_m<=0
        you_m=0;       
    end
    feed_you=double([num2str(you_m),yuan]);  
    if he_m>=total_money
        he_m=total_money; 
    end
    feed_he=double([num2str(he_m),yuan]);
else
rectPosition_he = [rect_he_x, rect_he_y, rect_he_x+rect_width*(1-discount)-gg,rect_he_y+rect_high ];
rectPosition_you = [rect_you_x, rect_you_y, rect_you_x+rect_width*(discount)+gg, rect_you_y+rect_high];% 矩形左上角坐标 (100, 100)，右下角坐标 (300, 200)
give_text='增加金额：';
punish_text='减少金额：';
    you_m=money_you+price;
    he_m=money_he-price;
    if you_m>=total_money
        you_m=total_money;     
    end
    feed_you=double([num2str(you_m),yuan]);  
    if he_m<=0
        he_m=0;   
    end
    feed_he=double([num2str(he_m),yuan]);
end
% present_resmoney=double([res_text,num2str(res_money),yuan]);
present_givemoney=double([give_text,num2str(give_point),yuan]);
present_beginpoint=double([num2str(begin_point),yuan]);
present_endpoint=double([num2str(end_point),yuan]);
present_punish_point=double([punish_text,num2str(punish_point),yuan]);
% DrawFormattedText(w,present_resmoney,present_res_x,present_res_y,text_color);
DrawFormattedText(w,present_givemoney,present_give_x,present_give_y,[255,255,0]);
DrawFormattedText(w,present_beginpoint,present_begin_x,present_begin_y,text_color);
DrawFormattedText(w,present_endpoint,present_end_x,present_end_y,text_color);
DrawFormattedText(w,present_punish_point,present_punish_x,present_punish_y,[255,0,0]);
rectPosition_give = [rect_give_x, rect_give_y, rect_give_x+gg, rect_give_y+rect_high];% 矩形左上角坐标 (100, 100)，右下角坐标 (300, 200)  
Screen('FillRect', w, [150 150 150], [rect_give_x, rect_give_y, rect_give_x+400, rect_give_y+rect_high]);
Screen('FillRect', w, [255 255 255], rectPosition_give);
    
Screen('Flip',w);
   %%
    %%%%% rest

end
result(13,trial)=he_m;
result(14,trial)=you_m;
result(15,trial)=give_point;
end
  %%  ITI
    t=GetSecs;
    Screen('FillRect',w,Black,wRect);
    Screen('Flip',w);
    while GetSecs<1+t;  %3s(0.5鍒?绉掞級
      ;  
    end
    if rem(trial,rest)==0 & trial~=TrialNum
        ae=floor(trial/rest);
        be=sprintf('%d',ae);
        Restcue=strcat('Please close your eyes and rest for a while!',be);
        Screen('FillRect',w,Black,wRect);
        Screen('DrawText',w,Restcue,wRect(3)/2-250,wRect(4)/2-8,[255 255 0]);
        Screen('Flip',w);

        while ~(touch && (keyCode(TriggerKey)))
            [touch, secs, keyCode] = KbCheck;
        end
        if keyCode(EscapeKey)
            Screen('CloseAll');
        end
        t_rest=GetSecs;
        Screen('DrawTexture',w,att,BackGRect);
        Screen('Flip',w);
    end

end
%% evluate qquality

evluate_text='公平评分';
present_evluate_text=double(evluate_text);
e_Type_set=[ones(1,Gap_points),2,3,4]; %%%%%% 2*Gap_points...
e_main_order=randperm(Gap_points+3); %%%%%% 2*Gap_points
e_discount_rates=[0.1:0.02:0.5];
e_discount_types=[1:1:21];
DrawFormattedText(w,present_evluate_text,wRect(3)/2,wRect(4)/2,[255,255,255]);
Screen('Flip',w);
[touch, secs, keyCode] = KbCheck;
touch =0;
while ~(touch && (keyCode(TriggerKey)))
    [touch, secs, keyCode] = KbCheck;
end
for e_trial=1:Gap_points+3; %%%%%% 2*Gap_points
    
    e_totalmoney=62.5;
    e_type=e_Type_set(e_main_order(e_trial));
    
    e_total_money=randi(Money_set);
    if e_type==1
        e_discount=e_discount_rates(e_main_order(e_trial));
        e_discount_type=e_discount_types(e_main_order(e_trial));
        feed_down=feed_text1;
        feed_up=feed_text3;
        money_you=e_total_money*e_discount;
        money_he=e_total_money*(1-e_discount);
       % 5. 绘制矩形
       rectPosition_he = [rect_he_x, rect_he_y, rect_he_x+rect_width*(1-e_discount),rect_he_y+rect_high ];
       rectPosition_you = [rect_you_x, rect_you_y, rect_you_x+rect_width*(e_discount), rect_you_y+rect_high];% 矩形左上角坐标 (100, 100)，右下角坐标 (300, 200)

        
    elseif e_type==2
        e_discount=take_all;
        e_discount_type=Gap_points+3;%you get all reward %%%%%% 2*Gap_points
        feed_down=feed_text1;
        feed_up=feed_text4;
        money_you=e_total_money*e_discount;
        money_he=e_total_money*(1-e_discount);
        rectPosition_he = [rect_he_x, rect_he_y, rect_he_x+rect_width*(1-e_discount),rect_he_y+rect_high ];
        rectPosition_you = [rect_you_x, rect_you_y, rect_you_x+rect_width*(e_discount), rect_you_y+rect_high];% 矩形左上角坐标 (100, 100)，右下角坐标 (300, 200)
%         Screen('FillRect', w, rectColor, rectPosition_he);
%         Screen('FillRect', w, rectColor, rectPosition_you);
    elseif e_type==3
        e_discount=take_nothing;
        e_discount_type=Gap_points+2;%other get all reward %%%%%% 2*Gap_points
        feed_down=feed_text2;
        feed_up=feed_text3;
        money_you=e_total_money*e_discount;
        money_he=e_total_money*(1-e_discount);
        rectPosition_he = [rect_he_x, rect_he_y, rect_he_x+rect_width*(1-e_discount),rect_he_y+rect_high ];
        rectPosition_you = [rect_you_x, rect_you_y, rect_you_x+rect_width*(e_discount), rect_you_y+rect_high];% 矩形左上角坐标 (100, 100)，右下角坐标 (300, 200)
%         Screen('FillRect', w, rectColor, rectPosition_he);
%         Screen('FillRect', w, rectColor, rectPosition_you);
    elseif type==4
        feed_down=feed_text2;
        feed_up=feed_text4;
        e_discount=-1;
        e_discount_type=Gap_points+1;%both get o reward %%%%%% 2*Gap_points
        money_you=0;
        money_he=0;
        rectPosition_he = [0, 0, 0,0 ];
        rectPosition_you = [0, 0, 0, 0];% 矩形左上角坐标 (100, 100)，右下角坐标 (300, 200) 
    end
    feed_you=double([num2str(money_you),yuan]);
    feed_he=double([num2str(money_he),yuan]);
%         Screen('FillRect', w, rectColor, rectPosition_he);
%         Screen('FillRect', w, rectColor, rectPosition_you)
%     DrawFormattedText(w,feed_up,position_left_down_x,position_left_down_y,text_color);
%     DrawFormattedText(w,feed_down,position_left_up_x,position_left_up_y,text_color);
%     DrawFormattedText(w,feed_you,position_right_down_x,position_right_down_y,text_color);
%     DrawFormattedText(w,feed_he,position_right_up_x,position_right_up_y,text_color);
%     DrawFormattedText(w,respond_text,position_center_x,position_center_y,text_color);
%     Screen('Flip',w);
    result(11,e_trial)=e_discount_type;
    tt=GetSecs;
    while GetSecs-tt<1
        ;
    end
    %% response2
% RateP1(1,:,:)=127;
% RateP1(:,1,:)=127;

pp=round(rand(1)*(400-200)+200);
RateP(170:196,20:pp+20)=103;
% [rateP_height, rateP_width, ~] = size(RateP);

start_row = 350;
start_col = round((gr_x - rateP_width) / 2+20);
ground_with_RateP = uint8(ones(gr_x,gr_y,3))*LUMINNACE;
ground_with_RateP(start_row:start_row+rateP_height-1, start_col:start_col+rateP_width-1, :) = repmat(RateP, [1, 1, 3]);
RP = Screen('MakeTexture', w, ground_with_RateP);
Screen('DrawTexture',w,RP);
        Screen('FillRect', w, rectColor, rectPosition_he);
        Screen('FillRect', w, rectColor, rectPosition_you)
    DrawFormattedText(w,feed_down,position_left_down_x,position_left_down_y,text_color);
    DrawFormattedText(w,feed_up,position_left_up_x,position_left_up_y,text_color);
    DrawFormattedText(w,feed_you,position_right_down_x,position_right_down_y,text_color);
    DrawFormattedText(w,feed_he,position_right_up_x,position_right_up_y,text_color);

Screen('Flip',w);
t4=GetSecs;
keyCode=zeros(1,256);
keyIsDown=0;
secs=GetSecs;
while GetSecs-t4<60.0 % 60.0s
% while 1
[keyIsDown, secs, keyCode] = KbCheck;
[x, y, buttons] = GetMouse(w);
if keyCode(breakKey)
    break;
end
if any(buttons)   
   if x >= start_col + 20 && x <= start_col + 545 
      pp=x-(start_col+20);
      if pp<0
         pp=0;
      elseif pp>550
         pp=525;
      end
   end
end
ground_with_RateP_modified = ground_with_RateP;
ground_with_RateP_modified(start_row + 170:start_row + 196, start_col + 19:start_col + 19 + pp, :) = 103;
ground_with_RateP_modified(start_row + 170:start_row + 196, start_col + 19 + pp + 1:start_col + 545, :) = 150;
RPnew = Screen('MakeTexture', w, ground_with_RateP_modified);
Screen('DrawTexture',w,RPnew);
        Screen('FillRect', w, rectColor, rectPosition_he);
        Screen('FillRect', w, rectColor, rectPosition_you)
    DrawFormattedText(w,feed_down,position_left_down_x,position_left_down_y,text_color);
    DrawFormattedText(w,feed_up,position_left_up_x,position_left_up_y,text_color);
    DrawFormattedText(w,feed_you,position_right_down_x,position_right_down_y,text_color);
    DrawFormattedText(w,feed_he,position_right_up_x,position_right_up_y,text_color);

Screen('Flip',w);
%%%%%%%%%%%%%%%%%%%%%%%%%
if keyCode(EscapeKey)
Screen('CloseAll');
ListenChar(0);
end
Screen('Close', RPnew);
end
pp=pp/525*100;
result(12,e_trial)=pp;

    Screen('DrawTexture',w,att,BackGRect);
    Screen('Flip',w);
    t2=GetSecs;
    while GetSecs-t2<1
        ;
    end
end
ShowCursor;
Screen('CloseAll');
%%
%%ANA
n1=0;n2=0;n3=0;n4=0;n5=0;n6=0;n7=0;n8=0;n9=0; n10=0;n11=0;n12=0;n13=0;n14=0;n15=0;n16=0;n17=0;n18=0;n19=0;n20=0;n21=0;
nn1=0;nn2=0;nn3=0;nn4=0;nn5=0;nn6=0;nn7=0;nn8=0;nn9=0; nn10=0;nn11=0;nn12=0;nn13=0;nn14=0;nn15=0;nn16=0;nn17=0;nn18=0;nn19=0;nn20=0;nn21=0;
r_h1=0;r_h2=0;r_h3=0;r_h4=0;r_h5=0;r_h6=0;r_h7=0;r_h8=0;r_h9=0;r_h10=0;r_h11=0;r_h12=0;r_h13=0;r_h14=0;r_h15=0;r_h16=0;r_h17=0;r_h18=0;r_h19=0;r_h20=0;r_h=21;
r_y1=0;r_y2=0;r_y3=0;r_y4=0;r_y5=0;r_y6=0;r_y7=0;r_y8=0;r_y9=0;r_y10=0;r_y11=0;r_y12=0;r_y13=0;r_y14=0;r_y15=0;r_y16=0;r_y17=0;r_y18=0;y_y19=0;r_y20=0;r_y21=0;
t_1=0;t_2=0;t_3=0;t_4=0;t_5=0;t_6=0;t_7=0;t_8=0;t_9=0; t_10=0;t_11=0;t_12=0;t_13=0;t_14=0;t_15=0;t_16=0;t_17=0;t_18=0;t_19=0;t_20=0;t_21=0;
S1=0;S2=0;S3=0;S4=0;S5=0;S6=0;S7=0;S8=0;S9=0;S10=0;S11=0;S12=0;S13=0;S14=0;S15=0;S16=0;S17=0;S18=0;S19=0;S20=0;S21=0;
%%
for ii=1:TrialNum
if result(6,ii)==1;
    n1=n1+1;
    S1(1,n1)=result(17,ii);%decide score
    r_h1(1,n1)=result(10,ii);%money_he;
    r_y1(1,n1)=result(9,ii);%money_you
    t_1(1,n1)=result(5,ii);%response time
    if result(4,ii)==1
       nn1=nn1+1;
    end
elseif result(6,ii)==2
    n2=n2+1;
    S2(1,n2)=result(17,ii);
    r_h2(1,n2)=result(10,ii);%money_he;
    r_y2(1,n2)=result(9,ii);%money_you
    t_2(1,n2)=result(5,ii);%response time
    if result(4,ii)==1
        nn2=nn2+1;
    end
elseif result(6,ii)==3
    n3=n3+1;
    S3(1,n3)=result(17,ii);
    r_h3(1,n3)=result(10,ii);%money_he;
    r_y3(1,n3)=result(9,ii);%money_you
    t_3(1,n3)=result(5,ii);%response time
    if result(4,ii)==1
        nn3=nn3+1;
    end
elseif result(6,ii)==4
    n4=n4+1;
    S4(1,n4)=result(17,ii);
    r_h4(1,n4)=result(10,ii);%money_he;
    r_y4(1,n4)=result(9,ii);%money_you
    t_4(1,n4)=result(5,ii);%response time
    if result(4,ii)==1
        nn4=nn4+1;
    end
elseif result(6,ii)==5
    n5=n5+1;
    S5(1,n5)=result(17,ii);
    r_h5(1,n5)=result(10,ii);%money_he;
    r_y5(1,n5)=result(9,ii);%money_you
    t_5(1,n5)=result(5,ii);%response time
    if result(4,ii)==1
        nn5=nn5+1;
    end
elseif result(6,ii)==6
    n6=n6+1;
    S6(1,n6)=result(17,ii);
    r_h6(1,n6)=result(10,ii);%money_he;
    r_y6(1,n6)=result(9,ii);%money_you
    t_6(1,n6)=result(5,ii);%response time
    if result(4,ii)==1
        nn6=nn6+1;
    end
elseif result(6,ii)==7
    n7=n7+1;
    S7(1,n7)=result(17,ii);
    r_h7(1,n7)=result(10,ii);%money_he;
    r_y7(1,n7)=result(9,ii);%money_you
    t_7(1,n7)=result(5,ii);%response time
    if result(4,ii)==1
        nn7=nn7+1;
    end
elseif result(6,ii)==8
    n8=n8+1;
    S8(1,n8)=result(17,ii);
    r_h8(1,n8)=result(10,ii);%money_he;
    r_y8(1,n8)=result(9,ii);%money_you
    t_8(1,n8)=result(5,ii);%response time
    if result(4,ii)==1
        nn8=nn8+1;
    end
elseif result(6,ii)==9
    n9=n9+1;
    S9(1,n9)=result(17,ii);
    r_h9(1,n9)=result(10,ii);%money_he;
    r_y9(1,n9)=result(9,ii);%money_you
    t_9(1,n9)=result(5,ii);%response time
    if result(4,ii)==1
        nn9=nn9+1;
    end
elseif result(6,ii)==10
    n10=n10+1;
    r_h10(1,n10)=result(10,ii);%money_he;
    r_y10(1,n10)=result(9,ii);%money_you
    t_10(1,n10)=result(5,ii);%response time
    if result(4,ii)==1
        nn10=nn10+1;
    end
elseif result(6,ii)==11
    n11=n11+1;
    r_h11(1,n11)=result(10,ii);%money_he;
    r_y11(1,n11)=result(9,ii);%money_you
    t_11(1,n11)=result(5,ii);%response time
    if result(4,ii)==1
        nn11=nn11+1;
    end
elseif result(6,ii)==12
    n12=n12+1;
    r_h12(1,n12)=result(10,ii);%money_he;
    r_y12(1,n12)=result(9,ii);%money_you
    t_12(1,n12)=result(5,ii);%response time
    if result(4,ii)==1
        nn12=nn12+1;
    end
elseif result(6,ii)==13
    n13=n13+1;
    r_h13(1,n13)=result(10,ii);%money_he;
    r_y13(1,n13)=result(9,ii);%money_you
    t_13(1,n13)=result(5,ii);%response time
    if result(4,ii)==1
        nn13=nn13+1;
    end
elseif result(6,ii)==14
    n14=n14+1;
    r_h14(1,n14)=result(10,ii);%money_he;
    r_y14(1,n14)=result(9,ii);%money_you
    t_14(1,n14)=result(5,ii);%response time
    if result(4,ii)==1
        nn14=nn14+1;
    end
elseif result(6,ii)==15
    n15=n15+1;
    r_h15(1,n15)=result(10,ii);%money_he;
    r_y15(1,n15)=result(9,ii);%money_you
    t_15(1,n15)=result(5,ii);%response time
    if result(4,ii)==1
        nn15=nn15+1;
    end
elseif result(6,ii)==16
    n16=n16+1;
    r_h16(1,n16)=result(10,ii);%money_he;
    r_y16(1,n16)=result(9,ii);%money_you
    t_16(1,n16)=result(5,ii);%response time
    if result(4,ii)==1
        nn16=nn16+1;
    end
elseif result(6,ii)==17
    n17=n17+1;
    r_h17(1,n17)=result(10,ii);%money_he;
    r_y17(1,n17)=result(9,ii);%money_you
    t_17(1,n17)=result(5,ii);%response time
    if result(4,ii)==1;
        nn17=nn17+1;
    end
elseif result(6,ii)==18
    n18=n18+1;
    r_h18(1,n18)=result(10,ii);%money_he;
    r_y18(1,n18)=result(9,ii);%money_you
    t_18(1,n18)=result(5,ii);%response time
    if result(4,ii)==1
        nn18=nn18+1;
    end
elseif result(6,ii)==18
    n18=n18+1;
    r_h18(1,n18)=result(10,ii);%money_he;
    r_y18(1,n18)=result(9,ii);%money_you
    t_18(1,n18)=result(5,ii);%response time
    if result(4,ii)==1
        nn18=nn18+1;
    end
 elseif result(6,ii)==19
    n19=n19+1;
    r_h19(1,n19)=result(10,ii);%money_he;
    r_y19(1,n19)=result(9,ii);%money_you
    t_19(1,n19)=result(5,ii);%response time
    if result(4,ii)==1
        nn19=nn19+1;
    end
 elseif result(6,ii)==20
    n20=n20+1;
    r_h20(1,n20)=result(10,ii);%money_he;
    r_y20(1,n20)=result(9,ii);%money_you
    t_20(1,n20)=result(5,ii);%response time
    if result(4,ii)==1
        nn21=nn21+1;
    end
  elseif result(6,ii)==21
    n21=n21+1;
    r_h21(1,n21)=result(10,ii);%money_he;
    r_y21(1,n21)=result(9,ii);%money_you
    t_21(1,n21)=result(5,ii);%response time
    if result(4,ii)==1
        nn21=nn21+1;
    end
end

end    

p1=nn1/10;p2=nn2/10;p3=nn3/10;p4=nn4/10;p5=nn5/10;p6=nn6/10;p7=nn7/10;p8=nn8/10;p9=nn9/10;
p10=nn10/10;p11=nn11/10;p12=nn12/10;p13=nn13/10;p14=nn14/10;p15=nn15/10;p16=nn16/10;p17=nn17/10;p18=nn18/10;p19=n19/10;p20=n20/10;p21=n21/10;
 %%
reward_you1=mean(r_y1);reward_you2=mean(r_y2);reward_you3=mean(r_y3);reward_you4=mean(r_y4);reward_you5=mean(r_y5);reward_you6=mean(r_y6);reward_you7=mean(r_y7);reward_you8=mean(r_y8);reward_you9=mean(r_y9);
reward_you10=mean(r_y10);reward_you11=mean(r_y11);reward_you12=mean(r_y12);reward_you13=mean(r_y13);reward_you14=mean(r_y14);reward_you15=mean(r_y15);reward_you16=mean(r_y16);reward_you17=mean(r_y17);reward_you18=mean(r_y18);
reward_you19=mean(r_y19);reward_you20=mean(r_y20);reward21_you21=mean(r_y21);
%%
reward_he1=mean(r_h1);reward_he2=mean(r_h2);reward_he3=mean(r_h3);reward_he4=mean(r_h4);reward_he5=mean(r_h5);reward_he6=mean(r_h6);reward_he7=mean(r_h7);reward_he8=mean(r_h8);reward_he9=mean(r_h9); % reward_he10=mean(r_h10);reward_he11=mean(r_h11);
reward_he12=mean(r_h12);reward_he13=mean(r_h13);reward_he14=mean(r_h14);reward_he15=mean(r_h15);reward_he16=mean(r_h16);reward_he17=mean(r_h17);reward_he18=mean(r_h18);
reward_he19=mean(r_h19);reward_he20=mean(r_h20);reward_he18=mean(r_h21);
%%%
M_S1=mean(S1);M_S2=mean(S2);M_S3=mean(S3);M_S4=mean(S4);M_S5=mean(S5);M_S6=mean(S6);M_S7=mean(S7);M_S8=mean(S8);M_S9=mean(S9);
M_S10=mean(S10);M_S11=mean(S11);M_S12=mean(S12);M_S13=mean(S13);M_S14=mean(S14);M_S15=mean(S15);M_S16=mean(S16);M_S17=mean(S17);M_S18=mean(S18);
M_S19=mean(S19);M_S20=mean(S20);M_S21=mean(S21);
M_S=[M_S1,M_S2,M_S3,M_S4,M_S5,M_S6,M_S7,M_S8,M_S9,M_S10,M_S11,M_S12,M_S13,M_S14,M_S15,M_S16,M_S17,M_S18,M_S19,M_S20,M_S21];
S_d = zeros(1, 21);    % 存储 S_d 的值,自己分配的值/总值
Bias = zeros(1, 21);   % 存储 Bias 的值，自己和他人相差的值/总值
m1=0;
for num = 1:TrialNum
    if result(15, num) ~= 0
        idx = result(6, num);  % 使用 result(6,num) 作为索引，代表 1~9 之间的值
        
        if idx >= 1 && idx <= 9
            % 更新 S_d 和 Bias 数组中对应的元素
            S_d(idx) = result(15, num) / result(8, num);
            Bias(idx) = (result(14, num) - result(13, num)) / result(8, num);
        end
    end
    if result(4,num)~=0
        m1=m1+1;
    Acc_money_set(m1)=result(9,num);
    end
    
end
% 使用 randperm 来随机选择4个不重复的值
random_indices = randperm(length(Acc_money_set), 4);  % 随机生成4个索引
Asub_money = mean(Acc_money_set(random_indices));       % 提取对应的4个值并取均值，这就是被试费

% S_d1=0;S_d2=0;S_d3=0;S_d4=0;S_d5=0;S_d6=0;S_d7=0;S_d8=0;S_d9=0;
% Bias1=0;Bias2=0;Bias3=0;Bias4=0;Bias5=0;Bias6=0;Bias7=0;Bias8=0;Bias9=0;
% for num=1:TrialNum
%     if result(15,num)~=0
%         if result(6,num)==1
%             S_d1=result(15,num)/result(8,num);
%             Bias1=(result(14,num)-result(13,num))/result(8,num);
%         elseif result(6,num)==2
%             S_d2=result(15,num)/result(8,num);
%             Bias2=(result(14,num)-result(13,num))/result(8,num);
%         elseif result(6,num)==3
%             S_d3=result(15,num)/result(8,num);
%             Bias3=(result(14,num)-result(13,num))/result(8,num);
%         elseif result(6,num)==4
%             S_d4=result(15,num)/result(8,num);
%             Bias4=(result(14,num)-result(13,num))/result(8,num);
%         elseif result(6,num)==5
%             S_d5=result(15,num)/result(8,num);
%             Bias5=(result(14,num)-result(13,num))/result(8,num);
%         elseif result(6,num)==6
%             S_d6=result(15,num)/result(8,num);
%             Bias6=(result(14,num)-result(13,num))/result(8,num);
%         elseif result(6,num)==7
%             S_d7=result(15,num)/result(8,num);
%             Bias7=(result(14,num)-result(13,num))/result(8,num);
%         elseif result(6,num)==8
%             S_d8=result(15,num)/result(8,num);
%             Bias8=(result(14,num)-result(13,num))/result(8,num);
%         elseif result(6,trial)==9
%             S_d9=result(15,num)/result(8,num);
%             Bias9=(result(14,num)-result(13,num))/result(8,num);
%         end
%     end
%             
% end
%%
% inferior equality
num1=9;
num2=10;
% nn1=0; nn2=0; nn3=2; nn4=2; nn5=9; nn6=10; nn7=10; nn8=9; nn9=10;
y1 = [nn1,nn2,nn3,nn4,nn5,nn6,nn7,nn8,nn9,nn10,nn11,nn12,nn13,nn14,nn15,nn16,nn17,nn17,nn18,nn19,nn20,nn21]'; 
x1 = (0.1:0.02:0.5)';  % 特征值
n1 = [10, 10, 10, 10, 10, 10, 10, 10, 10,10,10,10,10,10,10,10,10,10,10,10,10]';
%%
% 使用 glmfit 拟合逻辑回归模型
% 'binomial' 指定二项分布，'link' 设置为 'logit'
[B_i, ~, stats_i] = glmfit(x1, [y1, n1], 'binomial', 'link', 'logit');


% 获取模型系数
beta0_i = B_i(1); % 截距项
beta1_i = B_i(2); % X 的系数

x_05_i = -beta0_i / beta1_i;

disp(['y1 = 0.5 时对应的 x 值为: ', num2str(x_05_i)]);

%% 生成预测值
% 计算逻辑回归预测值
y_pred_i = glmval(B_i, x1, 'logit', 'size', n1) ./ n1;

% 创建图形窗口
figure;

% --- 绘制原始数据散点图 ---
subplot(1,2,1);
scatter(x1, y1/10, 80, 'b', 'filled', 'DisplayName', 'Original Data'); 
hold on;

% --- 绘制逻辑回归拟合曲线 ---
plot(x1, y_pred_i, 'r-', 'LineWidth', 2, 'DisplayName', 'Fitted Logistic Regression'); 
% --- 图形修饰 ---
xlabel('X_i');
ylabel('Accuracy');
title('Unfair Disadvantage: Logistic Regression Fit & M_S Curve');
legend('Location', 'Best');
grid on;
hold off;
subplot(1,2,2);
% --- 绘制M_S曲线 ---
% scatter(x1, M_S,80, 'g', 'filled', 'DisplayName', 'M_S Curve'); 
% hold on;
x_half_y=Muti_model(x1,M_S);
%%
Block=num2str(runNum);
FileName=['UGi' '_' ID '_' Block ];
save(FileName, 'result');Accept_mean=sum(result(4,:))/TrialNum;
Accept_sum=sum(result(4,:));
RT=sum(result(5,:))/TrialNum;
% Decide_num=[S_d1,S_d2,S_d3,S_d4,S_d5,S_d6,S_d7,S_d8,S_d9];
% Bias_num=[Bias1,Bias2,Bias3,Bias4,Bias5,Bias6,Bias7,Bias8,Bias9];

sts.RT=RT;
sts.Accept_mean=Accept_mean;
sts.Accept_sum=Accept_sum;
sts.iPSE=x_05_i;
%%%%%% sts.aPSE=x_05_a;
sts.Decide=S_d;
sts.Bias=Bias;
sts.iy=y1;
sts.sn=sn;
sts.submoney=Asub_money;
sts.mutimodel=x_half_y;
%%%%%% sts.ay=y2;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% recode result
Block=num2str(runNum);
FileName=['UGi' '_' ID '_' Block ];
save(FileName, 'result');
AnaName=['UGi_Ana' '_' ID '_' Block ];
save(AnaName,'sts');
