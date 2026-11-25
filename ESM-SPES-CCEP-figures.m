%% ESM / SPES-CCEP Practice Survey: figure generation
% Generates the figures for the survey on electrical stimulation practices
% (ESM and SPES/CCEP) in stereo-EEG and subdural recordings.
%
% Input : survey export (.xlsx), sheet 'Form Responses 1' (see Config)
% Output: all figures (PNG, 300 dpi) are written to one results folder
%         (resultsDir). The companion script ESM-SPES-CCEP-stats.m writes
%         its report and tables to the same folder.
%
% Requirements:
%   - MATLAB R2022a or later (clim; heatmap inside subplot)
%   - Statistics and Machine Learning Toolbox
%   - master_ColorMaps on the MATLAB path (https://github.com/sakkol/master_ColorMaps;
%     colormaps used: 'roma', 'batlow', 'plasma')
%
% Notes:
%   - Free-text "Other" entries in multi-select questions are not cleaned,
%     except for one answer that contains commas (see section 2).

clear; clc; close all;

%% 0. Config
% Paths are relative to this script. Expected layout:
%   <repo>/ESM-SPES-CCEP-figures.m  (this script)
%   <repo>/data/             survey export (not included in the repository)
%   <repo>/results/          created automatically; all outputs are written here
dataFile   = 'Survey_responses.xlsx';
scriptDir  = fileparts(mfilename('fullpath'));
if isempty(scriptDir); scriptDir = pwd; end
filePath   = fullfile(scriptDir,'data',dataFile);
resultsDir = fullfile(scriptDir,'results');
sheet      = 'Form Responses 1';
alpha      = 0.05;
if ~exist(resultsDir,'dir'); mkdir(resultsDir); end

%% 1. Load
raw  = readcell(filePath,'Sheet',sheet);
data = raw(2:end,:);                  % drop header row
N    = size(data,1);

%% 2. Grouping variables
data(:,69) = strrep(data(:,69),' (will skip this section)','');
data(:,17) = strrep(data(:,17),' (can skip this section)','');
region   = colStr(data(:,4));
instType = colStr(data(:,7));
% One free-text answer contains commas and would be split into several items
% by the comma-based multi-select parser; remove its commas so it is counted once.
ftOld = 'Of note, Would do low-frequency stimulation off ASM if needed, not HF';
ftNew = 'Of note Would do low-frequency stimulation off ASM if needed not HF';
for i = 1:N
    if ischar(data{i,24}) || isstring(data{i,24})
        data{i,24} = strrep(char(data{i,24}), ftOld, ftNew);
    end
end
ageGrp   = strings(N,1);
ageGrp(contains(instType,"Adult") & contains(instType,"Ped"))  = "Both";
ageGrp(contains(instType,"Adult") & ~contains(instType,"Ped")) = "Adult";
ageGrp(~contains(instType,"Adult")& contains(instType,"Ped"))  = "Pediatric";
setting  = strings(N,1);
setting(contains(instType,"Academic")) = "Academic";
setting(contains(instType,"Private"))  = "Private";

groupData  = {region, setting, ageGrp};
groupNames = ["Region","Setting","Age Group"];

%% 2b. Center counts by group (single stacked bar figure)
figure('Position',[100 100 600 700]);
hold on; barData = nan(numel(groupData),0); allLabels = {};
for g = 1:numel(groupData)
    x = groupData{g}(groupData{g} ~= "");
    [u,~,ic] = unique(x); cnt = accumarray(ic,1);
    for k = 1:numel(u)
        allLabels{end+1} = sprintf('%s: %s', groupNames(g), u(k));
    end
    b = bar(g, cnt', 'stacked');
    for k = 1:numel(b); b(k).FaceColor = 'flat'; end
    set(gca,'ColorOrder',master_ColorMaps('roma',5))
end
set(gca,'XTick',1:numel(groupData),'XTickLabel',groupNames);
set(gca, 'FontSize',20,'FontWeight','bold');
ylabel('Number of centers');
% title('Number of centers by group');
legend(allLabels,'Location','eastoutside','FontSize',10); grid on; hold off;
ylim([0 length(groupData{1})])
ytickss = yticks;yticks([ytickss length(groupData{1})])
print(fullfile(resultsDir,'centerCounts_per_group.png'),'-dpng','-r300');

%% 3. Ordinal variables and category order
% Column indices, short names and ordered answer categories of the single-answer
% ordinal (bracket) questions; used for the ordered distribution plots (7b).
ordinalCols  = [8 9 10 17 69 18 19 23 25 26 74];
ordinalNames = ["iEEGperYear","PctSEEG","LOS","PctESM","PctSPES","ESM_EloquentFreq","ESM_SeizureFreq", ...
               "ESM_Sessions","SeizInd_NetworkMap","SeizInd_FuncMap", "SeizInd_SPES"];

% Explicit category order for each ordinal variable
ordinalDefs = struct( ...
    'iEEGperYear',        ["1-10","11-20","21-30","31-40","≥40"], ...
    'PctSEEG',            ["0-20%","21-40%","41-60%","61-80%","81-100%"], ...
    'LOS',                ["4-6 days","7-10 days","11-14 days","15-21 days"], ...
    'PctESM',             ["0%","1-20%","21-40%","41-60%","61-80%","81-100%"], ...
    'PctSPES',            ["0%","1-20%","21-40%","41-60%","61-80%","81-100%"], ...
    'ESM_EloquentFreq',   ["0-20%","21-40%","41-60%","61-80%","81-100%"], ...
    'ESM_SeizureFreq',    ["0-20%","21-40%","41-60%","61-80%","81-100%"], ...
    'ESM_Sessions',       ["Never (may skip the next question)","Yes, in <5% of all iEEG cases", ...
                            "Yes, in 5-30% of all iEEG cases","Yes, in >30% of all iEEG cases"], ...
    'SeizInd_NetworkMap', ["0-20%","21-40%","41-60%","61-80%","81-100%"], ...
    'SeizInd_FuncMap',    ["0-20%","21-40%","41-60%","61-80%","81-100%"], ...
    'SeizInd_SPES',       ["0-20%","21-40%","41-60%","61-80%","81-100%"] ...
    );

%% 4. Multi-select reason bar charts
reasonCols  = [24 70 73];
reasonTitle = ["ESM off-ASM reasons","SPES/CCEP indications","SPES/CCEP off-ASM reasons"];
figure('Name','Multi-select reasons','Position',[100 100 1500 500]);
for i = 1:numel(reasonCols)
    Ti = parseMultiSelect(data(:,reasonCols(i)));
    subplot(1,3,i);
    if ~isempty(Ti)
        barh(Ti.Count); 
        set(gca,'YTick',1:height(Ti),'YTickLabel',Ti.Item,'YDir','reverse','FontSize',8);
        xlabel('Number of centers'); 
        title(reasonTitle(i),'Interpreter','none'); 
        grid on;
    else
        text(0.5, 0.5, 'No Data', 'HorizontalAlignment', 'center');
    end
end
print(fullfile(resultsDir,'multiselect_reasons.png'),'-dpng','-r300');

%% 5. Stimulation-parameter heatmaps (pulse width x frequency)
pulseLabels = ["<0.05 ms","0.05 ms","0.1 ms","0.2 ms","0.3 ms","0.4 ms","0.5 ms","1 ms","2 ms",">2 ms"];
gridDefs = {27:36,'sEEG - ESM Functional'; 37:46,'sEEG - ESM Network'; ...
            47:56,'Subdural - ESM Functional'; 57:66,'Subdural - ESM Network'; ...
            75:84,'sEEG - SPES/CCEP'; 85:94,'Subdural - SPES/CCEP'};
for k = 1:size(gridDefs,1)
    figure('Name','Stimulation parameter heatmaps','Position',[50 50 600 600]);
    [M,freqLabels] = buildParamHeatmap(data, gridDefs{k,1});
    if isempty(freqLabels)
        axis off;
        text(0.5,0.5,[gridDefs{k,2} ' (no data)'],'HorizontalAlignment','center','FontSize',12);
        print(fullfile(resultsDir,['stim_parameter_heatmaps_' num2str(k) '_' erase(gridDefs{k,2},{' ','/'}) '.png']),'-dpng','-r300');
        continue
    end
    h = heatmap(freqLabels, pulseLabels, M);
    h.Title = gridDefs{k,2};
    h.XLabel = 'Pulse train frequency'; h.YLabel = 'Pulse width';
    hs=struct(h);ylabel(hs.Colorbar,'Center Count','FontSize',16)
    set(gca,'FontSize',14)
    print(fullfile(resultsDir,['stim_parameter_heatmaps_' num2str(k) '_' erase(gridDefs{k,2},{' ','/'}) '.png']),'-dpng','-r300');
end
close all

%% 5b. Supplementary: stimulation-parameter heatmaps by age group
% Same pulse-width x frequency grids as section 5, but split into three
% panels per figure: Adult-only centers, Pediatric-only centers, and
% centers serving Both (kept as its own panel, not double-counted into
% Adult/Peds). Because of the small sample, some age-split cells are sparse
% or empty.
ageLevels = ["Adult","Pediatric","Both"];
for k = 1:size(gridDefs,1)
    figure('Name',['Stim parameter heatmaps by age - ' gridDefs{k,2}],'Position',[50 50 1650 560]);
    for a = 1:numel(ageLevels)
        subplot(1,3,a);
        subsetRows = ageGrp == ageLevels(a);
        [M,freqLabels] = buildParamHeatmap(data(subsetRows,:), gridDefs{k,1});
        nCenters = sum(subsetRows);
        if isempty(freqLabels)
            axis off;
            text(0.5,0.5,sprintf('%s (n=%d)\nno data',ageLevels(a),nCenters), ...
                'HorizontalAlignment','center','FontSize',10);
            continue
        end
        h = heatmap(freqLabels, pulseLabels, M);
        h.Title = sprintf('%s (n=%d)', ageLevels(a), nCenters);
        h.XLabel = 'Pulse train frequency'; h.YLabel = 'Pulse width';
        hs = struct(h); ylabel(hs.Colorbar,'Center Count','FontSize',10);
        set(gca,'FontSize',9)
    end
    sgtitle([gridDefs{k,2} ' — by age group'],'Interpreter','none');
    print(fullfile(resultsDir,['stim_parameter_heatmaps_supp_' num2str(k) '_' erase(gridDefs{k,2},{' ','/'}) '_byAge.png']),'-dpng','-r300');
end
close all

%% 6. Grouped comparison plots (Region / Setting / AgeGroup)
keyVars  = [17 25 26 69 74];
keyNames = ["PctESM","SeizInd_NetworkMap","SeizInd_FuncMap","PctSPES","SeizInd_SPES"];
isMultiSelect = [true, false, false, true, false]; 

for v = 1:numel(keyVars)
    figure('Name',char(keyNames(v)),'Position',[100 100 1500 400]);
    for g = 1:numel(groupData)
        subplot(1,3,g);
        if isMultiSelect(v)
            if g==1
                groupedBarByGroupMulti(data(:,keyVars(v)), groupData{g}, groupNames(g), keyNames(v),[]);
            elseif g==2
                cmap = master_ColorMaps('roma',5);cmap=cmap(1:2,:);
                groupedBarByGroupMulti(data(:,keyVars(v)), groupData{g}, groupNames(g), keyNames(v),cmap);
            elseif g==3
                cmap = master_ColorMaps('roma',5);cmap=cmap(3:5,:);
                groupedBarByGroupMulti(data(:,keyVars(v)), groupData{g}, groupNames(g), keyNames(v),cmap);
            end
        else
            x_clean = colStr(data(:,keyVars(v)));
            if v==3 || v==2
                stackedBarByGroup(x_clean, groupData{g}, groupNames(g),[],'batlow');
            else
                stackedBarByGroup(x_clean, groupData{g}, groupNames(g),[],'roma');
            end
        end
        set(gca, 'FontSize',16,'FontWeight','bold');
    end
    % sgtitle(keyNames(v),'Interpreter','none');
    print(fullfile(resultsDir, sprintf('groupcompare_%s.png', keyNames(v))),'-dpng','-r300');
end
close all

%% 6b. iEEG case volume by Region / Setting / AgeGroup
% Note: raw responses are ordinal brackets ("1-10","11-20",...,"≥40"),
% not counts, so we plot ordered proportions rather than a numeric mean.
caseVolOrder = ["1-10","11-20","21-30","31-40","≥40"];
xVol = colStr(data(:,8));
for g = 1:numel(groupData)
    figure('Name','iEEG case volume by group','Position',[100 100 600 700]);
    stackedBarByGroup(xVol, groupData{g}, groupNames(g), caseVolOrder, 'batlow');
    set(gca, 'FontSize',20,'FontWeight','bold');
    grid on
    set(gca,'XTickLabelRotation',35)
    title('')
    print(fullfile(resultsDir,['groupcompare_caseVolume_' char(groupNames(g)) '.png']),'-dpng','-r300');
end

%% 7. Overview: practice distributions (all key variables)
% Outcome variables for the overview plots; multi-select columns are flagged below
outcomeCols  = [8 9 10 17 18 19 21 22 23 25 26 67 68 69 71 72 74 95 96];
outcomeNames = ["iEEGperYear","PctSEEG","LOS","PctESM","ESM_EloquentFreq","ESM_SeizureFreq", ...
    "ESM_Timing","ESM_Sessions","ESM_OffASM","SeizInd_NetworkMap","SeizInd_FuncMap", ...
    "StimDur_LowFreq","StimDur_HighFreq","PctSPES","SPES_Timing","SPES_OffASM", ...
    "SeizInd_SPES","NumPulses","Current"];
multiSelectFlags = ismember(outcomeCols, [17 21 22 69 71]); 

for i = 1:numel(outcomeCols)

    % horizontal bar figure
    figure('Name','Practice distributions overview','Position',[50 50 500 500]);
    
    if multiSelectFlags(i)
        % --- Parse multi-select variable ---
        Ti = parseMultiSelect(data(:,outcomeCols(i)));
        barh(Ti.Count);
        set(gca,'YTick',1:height(Ti),'YTickLabel',Ti.Item,'FontSize',9,'YDir','reverse');
        xlabel('Number of Centers');
    else
        x = colStr(data(:,outcomeCols(i)));
        x = x(x~="");
        [u,~,ic] = unique(x);
        cnt = accumarray(ic,1);
        [cnt,ord] = sort(cnt,'descend');
        barh(cnt);
        set(gca,'YTick',1:numel(u),'YTickLabel',u(ord),'FontSize',9,'YDir','reverse');
        xlabel('Number of Centers');
    end
    title(outcomeNames(i),'Interpreter','none','FontSize',9);
    grid on;
    print(fullfile(resultsDir,['practice_distributions_' num2str(i) '_' char(outcomeNames(i)) '_barHorz.png']),'-dpng','-r300');

    % stacked bar figure
    x = colStr(data(:,outcomeCols(i)));
    x = x(x~="");
    [u,~,ic] = unique(x);
    cnt = accumarray(ic,1);
    prop = cnt' / sum(cnt);           % 1 x nCategories row -> one stacked bar
    bar(1, prop, 'stacked');
    set(gca,'XTick',[]); ylim([0 1]); ylabel('Proportion');
    title(outcomeNames(i),'Interpreter','none','FontSize',8);
    legend(u,'Location','eastoutside','Interpreter','none','FontSize',5);
    grid on;
    set(gca,'YTick',0:0.2:1,'YTickLabel',{'0%','20%','40%','60%','80%','100%'})
    print(fullfile(resultsDir,['practice_distributions_' num2str(i) '_' char(outcomeNames(i)) '_stacked.png']),'-dpng','-r300');
end
close all

%% 7b. Per-variable horizontal bar distributions for key ordinal variables
% One figure per variable, with horizontal bars in the category order given in
% ordinalDefs (section 3; first category at the top). Bars touch each other
% (BarWidth = 1). Bar length is the number of centers in that category and bar
% color encodes the same count (continuous colormap). The color scale is shared
% across all figures (global min/max count) so colors are comparable between
% variables. Only axis labels are drawn; no text inside the plot.
ordVarIdx = 1:5; % iEEGperYear, PctSEEG, LOS, PctESM, PctSPES
ordVars   = ordinalCols(ordVarIdx);
ordNames  = ordinalNames(ordVarIdx);
colormapname = 'plasma';

% First pass: gather counts for every category of every variable so the color
% scale can be set globally (use a per-figure min/max inside the loop below for
% a local scale instead).
allCounts = cell(numel(ordNames),1);
for v = 1:numel(ordNames)
    catOrder = ordinalDefs.(char(ordNames(v)));
    nCatsV = numel(catOrder);
    x = colStr(data(:,ordVars(v)));
    [tf, ord] = ismember(x, catOrder);
    ord = ord(tf); % drop blanks / unexpected values
    allCounts{v} = accumarray(ord(:), 1, [nCatsV 1]);
end
globalMin = min(cellfun(@min, allCounts));
globalMax = max(cellfun(@max, allCounts));

nColorLevels = 256;
cmapFull = getColormapSafe(colormapname, nColorLevels);

for v = 1:numel(ordNames)
    catOrder = ordinalDefs.(char(ordNames(v)));
    nCatsV = numel(catOrder);
    counts = allCounts{v};

    if globalMax > globalMin
        colorIdx = round(1 + (counts - globalMin) / (globalMax - globalMin) * (nColorLevels-1));
    else
        colorIdx = repmat(round(nColorLevels/2), nCatsV, 1);
    end
    colorIdx = max(1, min(nColorLevels, colorIdx));
    barColors = cmapFull(colorIdx,:);

    figure('Name',['Distribution - ' char(ordNames(v))],'Position',[100 100 500 350]);
    b = barh(1:nCatsV, counts, 'BarWidth', 1);
    b.FaceColor = 'flat';
    b.CData = barColors;
    set(gca,'YTick',1:nCatsV,'YTickLabel',catOrder,'YDir','reverse','FontSize',14,'FontWeight','bold');
    xlabel('Number of Centers');
    xlim([0 25])
    box on;
    print(fullfile(resultsDir,['practice_distributions_barh_' char(ordNames(v)) '.png']),'-dpng','-r300');
end
close all

% 7c. Standalone colorbar legend for the count-colored bars (7b)
figure('Units','normalized','Position',[0 0 .5 1])
% ax = axes;
colormap(master_ColorMaps(colormapname));
% set(gca,'ColorScale','log')
c=colorbar(gca);
% c.Label.String = 'p-values';c.Label.Rotation=270;
c.FontSize=48;
c.FontWeight='bold';
c.LineWidth = 1;
clim([0 25]);
% c.Ticks =  [1 5 10 15 20 24];% [0.0001,0.01,0.02,0.03,0.04,0.05];
% c.TickLabels = {'<0.0001','0.01','0.02','0.03','0.04','≥0.05'};

a=get(c); %gets properties of colorbar
a = a.Position; %gets the positon and size of the color bar
set(c,'Units','normalized','Position',[.5 .1 .05 .5])% To change size
set(gca,'Visible','off')
% ax.Visible = 'off';
set(gcf,'color','w')
set(gcf, 'InvertHardcopy', 'off') % to set saving white color as white
print(fullfile(resultsDir,'practice_distributions_barh_colorbar.png'),'-dpng','-r300');

%% ===================== Local functions =====================
function s = colStr(c)
% Convert an Nx1 readcell column to a string array; blanks -> ""
s = strings(numel(c),1);
for i = 1:numel(c)
    v = c{i};
    if isMissingCell(v); s(i) = ""; else; s(i) = strtrim(string(v)); end
end
end

function tf = isMissingCell(v)
tf = isa(v,'missing') || (isnumeric(v) && isscalar(v) && isnan(v)) || ...
     (ischar(v) && isempty(v)) || (isstring(v) && (ismissing(v) || strlength(v)==0));
end

function [p,stat,df,method] = catTest(x,g)
% Chi-square test of independence; uses Fisher's exact test when available
valid = x~="" & g~="";
x = cellstr(x(valid)); g = cellstr(g(valid));
[tbl,chi2,pChi2] = crosstab(x,g);
df = (size(tbl,1)-1)*(size(tbl,2)-1);
p = pChi2; stat = chi2; method = "Chi-square";
if size(tbl,1)>1 && size(tbl,2)>1
    try
        [~,pF] = fishertest(tbl);
        p = pF; stat = NaN; method = "Fisher exact";
    catch
    end
end
end

function [p, stat, df, method] = ordinalGroupTest(xOrd, g, nPerm)
% Rank-based test of an ordinal outcome (xOrd = integer bracket level,
% NaN for missing/excluded) across independent groups g.
%   k==2 groups -> Wilcoxon rank-sum / Mann-Whitney U, exact p-value
%   k>=3 groups -> Kruskal-Wallis H (tie-corrected), Monte Carlo
%                  permutation p-value (nPerm resamples) instead of the
%                  asymptotic chi-square approximation, since group
%                  sizes here are small.
valid = ~isnan(xOrd) & g ~= "";
x = xOrd(valid); grp = g(valid);
[uG,~,gIdx] = unique(grp);
k = numel(uG);
Nn = numel(x);

if k < 2 || Nn < 2
    p = NaN; stat = NaN; df = NaN; method = "n/a (insufficient groups/data)";
    return
end

if k == 2
    x1 = x(gIdx==1); x2 = x(gIdx==2);
    [p,~,statsRS] = ranksum(x1, x2, 'method','exact');
    stat = statsRS.ranksum; df = NaN;
    method = "Wilcoxon rank-sum (exact)";
else
    df = k - 1;
    stat = kwStat(x, gIdx, k, Nn);
    rng(42,'twister'); % fixed seed -> reproducible permutation p-value
    [~, ord] = sort(rand(Nn, nPerm), 1);      % Nn x nPerm random permutations
    gIdxPerm = gIdx(ord);                     % permuted group labels, ranks (x) held fixed
    r = tiedrank(x);
    Hperm = zeros(1, nPerm);
    for j = 1:k
        mask = (gIdxPerm == j);
        Rsum_j = sum(r .* mask, 1);
        n_j = sum(mask, 1);
        Hperm = Hperm + (Rsum_j.^2) ./ n_j;
    end
    Hperm = (12/(Nn*(Nn+1))) * Hperm - 3*(Nn+1);
    [~,~,ic] = unique(x);
    t = accumarray(ic,1);
    tieCorr = 1 - sum(t.^3 - t) / (Nn^3 - Nn);
    if tieCorr > 0; Hperm = Hperm / tieCorr; end
    % one-sided upper-tail Monte Carlo p-value with add-one smoothing
    p = (sum(Hperm >= stat - 1e-9) + 1) / (nPerm + 1);
    method = sprintf("Kruskal-Wallis (permutation, N=%d)", nPerm);
end
end

function H = kwStat(x, gIdx, k, Nn)
% Tie-corrected Kruskal-Wallis H statistic
r = tiedrank(x);
Rsum = accumarray(gIdx, r, [k 1]);
n = accumarray(gIdx, 1, [k 1]);
H = (12/(Nn*(Nn+1))) * sum((Rsum.^2)./n) - 3*(Nn+1);
[~,~,ic] = unique(x);
t = accumarray(ic,1);
tieCorr = 1 - sum(t.^3 - t) / (Nn^3 - Nn);
if tieCorr > 0; H = H / tieCorr; end
end

function q = bhFDR(p)
% Benjamini-Hochberg FDR correction
[ps,idx] = sort(p); m = numel(p);
qs = ps .* m ./ (1:m)';
qs = flipud(cummin(flipud(qs)));
q = zeros(size(p)); q(idx) = min(qs,1);
end

function T = parseMultiSelect(colCell)
% Count frequency of each comma-separated item across all responses
items = {};
for i = 1:numel(colCell)
    s = colCell{i};
    if isMissingCell(s); continue; end
    parts = strtrim(strsplit(char(string(s)),','));
    parts(cellfun(@isempty,parts)) = [];
    items = [items, parts];
end
[u,~,ic] = unique(items);
counts = accumarray(ic(:),1);
[counts,ord] = sort(counts,'descend');
T = table(reshape(u(ord),[],1), counts, 'VariableNames',{'Item','Count'});
end

function [M, freqLabels] = buildParamHeatmap(data, colRange)
% Build pulse-width x frequency count matrix from a block of grid columns
% Parses comma-separated multiple selections within grid cells.

nP = numel(colRange); 
N = size(data, 1);
allTok = {}; 
tokMat = cell(nP, N);

for i = 1:nP
    for j = 1:N
        v = data{j, colRange(i)};
        if isMissingCell(v); continue; end
        
        % Split multiple answers separated by commas
        toks = strtrim(strsplit(char(string(v)), ', '));
        toks(cellfun(@isempty, toks)) = [];
        
        tokMat{i, j} = toks; 
        allTok = [allTok, toks];
    end
end

freqLabels = unique(allTok);
if isempty(freqLabels); M = []; return; end

% Robust numeric extraction to sort the x-axis frequencies in order (e.g., 1 Hz, 2 Hz, 50 Hz)
nums = nan(1, numel(freqLabels));
for f = 1:numel(freqLabels)
    % Extracts the first decimal or integer digit from the label
    m = regexp(freqLabels{f}, '[\d.]+', 'match', 'once');
    if ~isempty(m)
        nums(f) = str2double(m); 
    end
end

% Handle cases where no numbers are found (fallback to alphabetical sort)
nums(isnan(nums)) = Inf; 
[~, ord] = sort(nums); 
freqLabels = freqLabels(ord);

% Build the heatmap data matrix
M = zeros(nP, numel(freqLabels));
for i = 1:nP
    for j = 1:N
        toks = tokMat{i, j};
        if isempty(toks); continue; end
        for t = 1:numel(toks)
            idx = find(strcmp(freqLabels, toks{t}));
            if ~isempty(idx)
                M(i, idx) = M(i, idx) + 1; 
            end
        end
    end
end

freqLabels = string(freqLabels);
end

function stackedBarByGroup(x,g,titleStr,catOrder,cmapName)
% Normalized stacked bar of response proportions across group levels.
% Optional catOrder specifies left-to-right order of x categories
% (e.g. ordinal brackets); otherwise uses appearance order from crosstab.
% Optional cmapName (string) applies a named colormap (via
% master_ColorMaps) to the stacked segments; omit/'' to use MATLAB defaults.
if nargin < 4; catOrder = []; end
if nargin < 5; cmapName = ''; end
valid = x~="" & g~="";
x = cellstr(x(valid)); g = cellstr(g(valid));
[tbl,~,~,labels] = crosstab(g,x);
nG = size(tbl,1);
gLabels = string(labels(1:nG, 1)); 
if strcmpi(string(titleStr), "Region")
    [gLabels, gOrd] = sort(gLabels, 'ascend');
    tbl = tbl(gOrd, :);
end
xLabels = string(labels(1:size(tbl,2),2));
if ~isempty(catOrder)
    [tf,ord] = ismember(catOrder,xLabels);
    ord = ord(tf); tbl = tbl(:,ord); xLabels = xLabels(ord);
end
propTbl = tbl ./ sum(tbl,2);
b = bar(propTbl,'stacked');
if ~isempty(cmapName)
    cmap = master_ColorMaps(cmapName, 5);
    for k = 1:numel(b)
        b(k).FaceColor = cmap(k,:);
    end
end
set(gca,'XTickLabel',gLabels(1:nG,1));
set(gca,'YTick',0:0.2:1,'YTickLabel',{'0%','20%','40%','60%','80%','100%'})
legend(xLabels,'Location','eastoutside','Interpreter','none','FontSize',7);
ylabel('Proportion of centers'); title(titleStr,'Interpreter','none'); ylim([0 1]);
end

function cmap = getColormapSafe(name, n)
% Wrapper around master_ColorMaps: if a colormap name is not available, fall
% back to the built-in turbo colormap (with a warning) instead of stopping.
try
    cmap = master_ColorMaps(name, n);
catch
    warning('getColormapSafe:fallback', ...
        'Colormap "%s" not found via master_ColorMaps; falling back to turbo(%d).', name, n);
    cmap = turbo(n);
end
end


function [binTable, uniqueChoices] = binarizeMultiSelect(colCell, varName)
% Parses comma-separated multi-select cells into a logical/binary table.
% Each unique answer choice becomes its own column.

% Clean and split responses
N = numel(colCell);
splitCells = cell(N, 1);
allTokens = {};

for i = 1:N
    v = colCell{i};
    if isa(v,'missing') || (isnumeric(v) && isnan(v)) || (ischar(v) && strcmp(v,'')) || (isstring(v) && strlength(v)==0)
        splitCells{i} = {};
        continue;
    end
    % Split by comma, trimming any leading/trailing whitespace
    tokens = strtrim(strsplit(char(string(v)), ','));
    tokens(cellfun(@isempty, tokens)) = [];
    splitCells{i} = tokens;
    allTokens = [allTokens, tokens];
end

% Get unique choices
uniqueChoices = string(unique(allTokens));
uniqueChoices(uniqueChoices == "") = [];

% Create binary matrix
binMatrix = zeros(N, numel(uniqueChoices));
for i = 1:N
    if isempty(splitCells{i}), continue; end
    for j = 1:numel(uniqueChoices)
        if any(strcmp(splitCells{i}, uniqueChoices(j)))
            binMatrix(i, j) = 1;
        end
    end
end

% Standardize and safely truncate column names for MATLAB table safety
safeNames = erase(uniqueChoices, {'.', ' ', '-', '/', '(', ')', '[', ']', '{', '}'});
safeNames = varName + "_" + safeNames;

% Enforce MATLAB's namelengthmax (typically 63 characters)
maxLength = namelengthmax; 
for k = 1:numel(safeNames)
    if strlength(safeNames(k)) > maxLength
        % Truncate to maxLength, but keep it unique by appending a short hash of the original name if needed
        trimmed = extractBefore(safeNames(k), maxLength - 5);
        hashVal = num2str(mod(sum(double(char(safeNames(k)))), 10000), '%04d');
        safeNames(k) = trimmed + "_" + hashVal;
    end
end

binTable = array2table(binMatrix, 'VariableNames', cellstr(safeNames));
end

function groupedBarByGroupMulti(colCell, g, groupName, varLabel, cmap)
% Generates a grouped bar chart showing the NUMBER of centers within each
% group that selected each option (percentage bracket) for a multi-select
% variable. Plotted as raw counts (not % of centers) because the x-axis
% categories are themselves percentage brackets (e.g. of cases undergoing
% ESM/SPES). Category order follows binarizeMultiSelect (rawChoices).

valid = g ~= "";
colCell = colCell(valid);
g = g(valid);

% Get unique groups and binarize the multi-select column
[uGroups, ~, gIdx] = unique(g);
[binTable, rawChoices] = binarizeMultiSelect(colCell, varLabel);
nChoices = width(binTable);
nGroups = numel(uGroups);

% Count of centers in each group who chose each option
countMatrix = zeros(nChoices, nGroups);
for grp = 1:nGroups
    grpMembers = (gIdx == grp);
    if any(grpMembers)
        countMatrix(:, grp) = sum(binTable{grpMembers, :}, 1)';
    end
end

% Plot
bar(countMatrix);
set(gca, 'XTick', 1:nChoices, 'XTickLabel', rawChoices, 'XTickLabelRotation', 45, 'FontSize', 8);
ylabel('Number of centers');
title(groupName);
% legend(cellstr(uGroups), 'Location', 'best', 'FontSize', 7);
yl = ylim; ylim([0 max(yl(2), 1)]);
if isequal(get(gca,'YTick'), unique(round(get(gca,'YTick'))))==0
    yticks(unique(round(yticks))); % force integer tick labels for counts
end
grid on;
if ~isempty(cmap)
    set(gca,'ColorOrder',cmap)
end
end