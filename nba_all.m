function unsucc=nba_all()
%  FUNCTION FLAG=NBA_ALL()
%  获取所有球员数据的函数，无输入参数，返回获取失败的球员列表.
%  程序最后保存4(5)个mat或Excel数据
%         list： 所有球员的网站列表(共调试和查询使用)
%         info： 所有球员的ID和个人基本信息
%         chgui：所有球员的生涯常规赛数据
%         jihou：所有球员的生涯季后赛数据

%   J.Song@2014.10.26   gasongjian@126.com
clc
tic
disp(['==========NBA数据更新程序(gasongjian@126.com)=====================']);
disp(['程序开始运行，请耐心等待(至多五分钟).....']);
url1='http://g.hupu.com/nba/players/';
html1=urlread(url1);
%% 获取球队的列表 teamlist
[teamlist,~]=regexp(html1,'href="(/nba/players/\w+)">(.*?)</a>','tokens','match');
n=length(teamlist);
%% 获取球员的列表list
list=[];
for i=1:n
    url2=['http://g.hupu.com',teamlist{i}{1}];
  %  url2='http://g.hupu.com/nba/players/Wizards';
    html2=urlread(url2);
    [playlist,~]=regexp(html2,'class="td_padding"><a href="(http://g.hupu.com/nba/players/[\w-]+.html)"','tokens','match');
    playlist=playlist(:);
    list=[list;playlist];
end
n=length(list);
for i=1:n
    list{i}=list{i}{1};
end
save('list.mat','list');
t=toc;
fprintf('已获取30个球队共 %d 个球员的网址列表，并保存在 list.mat中，已耗时 %5.2f s, 请耐心等待数据获取...\n',n,t);
%% 开始获取每个球员的数据
info={'ID','name','个人网址','个人头像','身高','位置','体重','生日','球队','学校',...
    '选秀','出生地','本赛季薪金','合同','常规赛参加情况','季后赛参加情况'};
chgui={'ID','name','赛季','球队','场次','首发','时间','投篮','命中率','三分',...
    '命中率','罚球','命中率','篮板','助攻','抢断','盖帽','失误','犯规','得分'};
jihou={'ID','name','赛季','球队','场次','首发','时间','投篮','命中率','三分',...
    '命中率','罚球','命中率','篮板','助攻','抢断','盖帽','失误','犯规','得分'};
flag=zeros(n,1);
for i=1:n
    url=list{i};
    [data,flag1]=nba_player(url,num2str(10000+i));
    flag(i)=flag1;
    if flag1
    info=[info;data.info(2,:)];
    chgui=[chgui;data.chgui(2:end,:)];
    jihou=[jihou;data.jihou(2:end,:)];
    else
        fprintf('ID为 %s 的球员 %s ：资料没有获取到.\n',data.info{2,1},data.info{2,2});
    end
end
if ~all(flag)
    flag=find(flag==0);
    unsucc=cell(length(flag),2);
    unsucc(:,2)=list(flag);
    unsucc(:,1)=num2cell(flag);     
    save('unsucc.mat','unsucc')
    fprintf('获取失败的球员列表已保存在unsucc.mat 中.\n');
else
    unsucc=[];
end
save('info.mat','info');
save('chgui.mat','chgui');
save('jihou.mat','jihou');
t=toc;
disp('==============================================================')
fprintf('已经读取完所有数据，已耗时 %5.2f min,请等待Excel表格(TXT文本)生成....\n',t/60);

%Excel
xlswrite('nba_info.xls',info,1,'A1');
xlswrite('nba_chgui.xls',chgui,1,'A1');
xlswrite('nba_jihou.xls',jihou,1,'A1');

% TXT 版本
textwrite('nba_info.txt',info);
textwrite('nba_chgui.txt',chgui);
textwrite('nba_jihou.txt',jihou);

t=toc;
fprintf('程序运行完毕，共耗时 %5.2f min,谢谢使用^_^\n',t/60);
end

%======================================================================
%=======================================================================
function [sdata_nba,flag]=nba_player(url,ID)
% FUNCTION SDATA_NBA=NBA_PLAYER(URL)
% 获取单个球员数据的函数,输入球员的网址
% 返回的是结构体数据。有三个标签
%       info： 包含各种基本信息如生日等
%       chgui：返回的是常规赛统计数据
%       jihou：返回的是季后赛统计数据
% 返回的第二个参数是：flag=1，获取成功；flag=0，获取失败.

%%  web 数据读取
flag=1;
if nargin==0
    url='http://g.hupu.com/nba/players/tonyparker-700.html';
    disp('DEMO：tonyparker')
    ID=[];
elseif nargin==1
    ID=[];
end
% 程序调试
% url='http://g.hupu.com/nba/players/nickcalathes-3348.html';
% ID=[];
html=urlread(url);

%% 个人资料获取info
str1={'ID','name','个人网址','个人头像','身高','位置','体重','生日','球队','学校',...
    '选秀','出生地','本赛季薪金','合同','常规赛参加情况','季后赛参加情况'};% 请保持最后两个不变
info=cell(2,length(str1));
info(1,:)=str1;
info{2,1}=ID;info{2,3}=url;
[temp,~]=regexp(html,'<h2>(.*?)</h2>','tokens','match');
name=temp{1}{1};
info{2,2}=name;
% 个人头像地址
[jpgurl,~]=regexp(html,'src="(http://c2.hoopchina.com.cn//uploads/gamespace/players/\w{0,3}/\w+.(jpg|png))"','tokens','match');
if ~isempty(jpgurl)
    jpgurl=jpgurl{1}{1};
else
    jpgurl=[];
end
info{2,4}=jpgurl;
%=====================================================================

[temp,~]=regexp(html,'<p>([^<a].*?)</p>','tokens','match');
for i=1:length(temp)
    sign=temp{i}{1};
    ind=strfind(sign,'：');
    item=sign(1:ind-1);
    content=sign(ind+1:end);   
    ind1=find(strcmp(item,str1));
    if strcmp(item,'球队')
        [content,~]=regexp(content,'<a.*?>(.*?)</a>','tokens','match');
        content=content{1}{1};
    end
    info{2,ind1}=content;
end

%% 常规赛数据预处理，把字符串分隔(各个球员网站源代码格式不尽相同，力求兼容性。)

ind1=strfind(html,'bottTitle');
if numel(ind1)==3
%     info{2,end-1}=1; %记录是否参加过常规赛
%     info{2,end}=1;    %记录是否参加过季后赛
    %html1=html(ind1(1):ind1(2));% 本赛季常规赛数据区域
    html2=html(ind1(2):ind1(3));% 生涯常规赛数据区域
     html3=html(ind1(3):end);% 生涯季候赛数据区域
     ind2=strfind(html3,'得分排行榜');
     if ~isempty(ind2)
         html3=html3(1:ind2);
     end
elseif numel(ind1)==2
    temp=html(ind1(2):ind1(2)+50);
    if ~isempty(strfind(temp,'职业生涯常规赛平均数据'))
        info{2,end}=0; 
        %info{2,end-1}=1;
        html2=html(ind1(2):end);
        ind2=strfind(html2,'得分排行榜');
        if ~isempty(ind2)
             html2=html2(1:ind2);
        end
        html3='';
    elseif ~isempty(strfind(temp,'职业生涯季后赛平均数据'))
        info{2,end-1}=0;
        %info{2,end}=1;
        html2='';
        html3=html(ind1(2):end);
        ind2=strfind(html3,'得分排行榜');
        if ~isempty(ind2)
             html3=html3(1:ind2);
        end
    end   
elseif numel(ind1)==1
    info{2,end-1}=0;info{2,end}=0;
    chgui=[];jihou=[];
    sdata_nba=struct;
    sdata_nba.info=info;
    sdata_nba.chgui=chgui;
    sdata_nba.jihou=jihou;
    return    
else
    info{2,end-1}=0;info{2,end}=0;
    flag=0;
    chgui=[];jihou=[];
    sdata_nba=struct;
    sdata_nba.info=info;
    sdata_nba.chgui=chgui;
    sdata_nba.jihou=jihou;
    return     
end
%% 常规赛数据获取
if ~isempty(html2)
    regstr=['<tr.*?',repmat('<td.*?>(.*?)</td>\s+',1,18),'</tr>'];
    [s,~]=regexp(html2,regstr,'tokens','match');
    ch_len=length(s);info{2,end-1}=ch_len-2;
    chgui=cell(ch_len-1,2+length(s{2}));
    for i=1:ch_len-1
        chgui{i,1}=info{2,1};
        chgui{i,2}=info{2,2};
        chgui(i,3:end)=s{i+1};
    end
    chgui{1,1}='ID';chgui{1,2}='name';
else
    chgui=[];
end

%% 季候赛数据获取
if ~isempty(html3)
regstr=['<tr.*?',repmat('<td.*?>(.*?)</td>\s+',1,18),'</tr>'];
[s,~]=regexp(html3,regstr,'tokens','match');
jihou_len=length(s);info{2,end}=jihou_len-2;
jihou=cell(jihou_len-1,2+length(s{2}));
for i=1:jihou_len-1 
jihou{i,1}=info{2,1};
jihou{i,2}=info{2,2};
jihou(i,3:end)=s{i+1};
end
jihou{1,1}='ID';jihou{1,2}='name';
else
    jihou=[];
end
%% 数据返回
sdata_nba=struct;
sdata_nba.info=info;
sdata_nba.chgui=chgui;
sdata_nba.jihou=jihou;
end



function textwrite(filename,data,delimiter)
% 把元胞数组的内容写到txt中
if nargin==2
   delimiter='|';
end
[nrows,ncols] = size(data);
for i=1:nrows
    for j=1:ncols
        if ~isa(data{i,j},'char')
            data{i,j}=num2str(data{i,j});
        end
    end
end
fileID = fopen(filename,'w');
formatSpec = [repmat(['%s',delimiter],1,ncols-1),'%s\r\n'];
for row = 1:nrows
    fprintf(fileID,formatSpec,data{row,:});
end
fclose(fileID);
end



    
    
    
    
    
    
    
    
