% Author info:
% Code written by Sarah White, last revision 1/16/20,
% in association with the following paper:
% McClymont, E. L., Ford, H. L., Ho, S. L., Tindall, J. C., Haywood, A. M., 
% Alonso-Garcia, M., Bailey, I., Berke, M. A., Littler, K., Patterson, M., 
% Petrick, B., Peterse, F., Ravelo, A. C., Risebrobakken, B., De Schepper, 
% S., Swann, G. E. A., Thirumalai, K., Tierney, J. E., van der Weijst, C., 
% and White, S.: Lessons from a high CO2 world: an ocean view from 
% ~3 million years ago, Clim. Past Discuss., 
% https://doi.org/10.5194/cp-2019-161, in review, 2020.
% 
% What this code does:
% This will calculate the mcd of an arbitrary IODP sample.
% IODP sample names need to be in a spreadsheet, with columns for:
% Site, Hole, Core, Type, Subsection, Top(cm).
% This particular code was written to work on ODP Site 806, for samples 
% from 18H-3 and shallower.
%  
% Inputs to the code:
% 1) All age model information, which is in a spreadsheet named "agemodel_806_forMatlabcode.xlsx"
% This spreadsheet had tabs for:
%     a) Core info, which lists how long each core in each hole is;
%     b) The affine table (from Mayer et al 1993), which provides correlations between holes;
%     c) The conversion from 806B equivalent mbsf to mcd (see below for details);
%     d) The conversion from mcd to age
% 2) Your sample list, as described above.  
%  
% Outputs of the code:
% The mbsf, 806B equivalent mbsf, mcd, and age of each sample are appended 
% to a table of all input sample names. 
% This table is called "sample_names_raw" and is a cell matrix. 
% Another table is also created, "sample_names_num," which has all the same 
% information but formatted as numbers (and lacking column headings). 
% In addition, the mbsf, 806B equivalent mbsf, mcd, and ages can all be 
% found as columns of numbers named "mbsf," "mbsf_806Beq", "mcd?, and ?ages?. 

% The age model ~0-4 Ma is based on a benthic oxygen isotope stratigraphy 
% from Karas et al 2009. 
% For samples ~4-5.5 Ma, the age model is based on a few biostratigraphic
% tie points.

% Please see readme for all details and caveats!

close all
clear all

%%%%% User input
% What is the name of the Excel spreadsheet containing your sample names?
filename = 'sample_list.xlsx';
% What is the name of the tab in the spreadsheet containing your samples?
tabname = 'Wara_2005';


%%%%% Don't change anything below this!!!!

% Load data
[sample_names_num, sample_names_txt, sample_names_raw]=xlsread(filename,tabname);

%%%%% get tie points
% 'core_info' has 6 columns
% 806A_core, 806A_top_depth_mbsf, 806B_core, 806B_top_depth_mbsf, 806C_core,
% 806C_top_depth_mbsf
agemodel_core_info=xlsread('agemodel_806_forMatlabcode.xlsx','core_info');


%%%%% Convert sample names to mbsf
% Make a vector for the mbsf data, which has length equal to the length of 
% the sample names table
sample_names_holes=char(sample_names_txt(:,2));
mbsf(size(sample_names_num,1),1)=0;

for a=1:(size(sample_names_num,1))
    % converts Hole A,B,C to number
    if sample_names_holes(a,1)=='A'
        Hole=1;
    elseif sample_names_holes(a,1)=='B'
        Hole=2;
    else
        Hole=3;
    end
    % find what core you're in
    core=sample_names_num(a,3);
    % calculate mbsf for your sample, by looking up the mbsf of the top of
    % the core you're in, and adding 150 cm to whatever subsection you're
    % in (minus 1, so you don't add to 1st subsection), then adding cm of
    % sample name. Also converting cm to m
    mbsf(a)=(agemodel_core_info(core,Hole*2))+(1.50*(sample_names_num(a,5)-1))+(sample_names_num(a,6))/100;
end

% Append calculated mbsf to original table of sample names
sample_names_num = [sample_names_num mbsf];
sample_names_raw = [sample_names_raw ['mbsf'; num2cell(mbsf)]];


%%%%% Convert mbsf to 806B equivalent mbsf
mbsf_806Beq(length(sample_names_num(:,1)),1)=NaN;

% Get affine table
% 'affine' has 4 columns
% 806A_mbsf, 806B_mbsf_forA, 806C_mbsf, 806B_mbsf_forC
% This is just the affine table from Mayer et al 1993, but with blank spaces
% eliminated - so values are repeated 
agemodel_affine_all=xlsread('agemodel_806_forMatlabcode.xlsx', 'affine');
% reset variable affine so that it's just for the hole of interest
% can't use whole affine table, because splices are different lengths for
% different holes, and empty cells get filled with 'NaN' by Matlab
for a=1:length(agemodel_affine_all(:,1))
    if isnan(agemodel_affine_all(a,1))==0 
        affine_forA(a,1)=agemodel_affine_all(a,1);
        affine_forA(a,2)=agemodel_affine_all(a,2);
    end
    if isnan(agemodel_affine_all(a,3))==0 
        affine_forC(a,1)=agemodel_affine_all(a,3);
        affine_forC(a,2)=agemodel_affine_all(a,4);
    end
end

for b=1:(length(sample_names_num(:,1)))
    % converts Hole A,B,C to number
    if sample_names_holes(b,1)=='A'
        Hole=1;
    elseif sample_names_holes(b,1)=='B'
        Hole=2;
    else
        Hole=3;
    end
    
    % Which hole are we in? This determines which affine table to use
    if Hole==1
        mbsf_806Beq(b) = interp1(affine_forA(:,1), affine_forA(:,2), sample_names_num(b,7));
    elseif Hole==2
    % If we're in Hole B, mbsf is already in 806Beq mbsf, and we don't
    % need to do anything further, just put the mbsf value into the target
    % matrix
        mbsf_806Beq(b) = sample_names_num(b,7);
    else 
        mbsf_806Beq(b) = interp1(affine_forC(:,1), affine_forC(:,2), sample_names_num(b,7));
    end
end


%%%%% Fix NaNs
% Interpolation returns 'NaN' if input values exceed those in the affine table
% I'm going to assume that, for all depths deeper than 
% the deepest value in the affine table (end of core 11),
% the "806B equivalent" value is equal to the mbsf + the mbsf-806Bmbsf offset 
% at the deepest value
offset_to806B(1,2) = 0;
offset_to806B(1,1) = affine_forA(end,2)-affine_forA(end,1);
offset_to806B(1,2) = affine_forC(end,2)-affine_forC(end,1);
for c=1:length(mbsf_806Beq)
    if isnan(mbsf_806Beq(c))==1
        if Hole==1
            mbsf_806Beq(c)=sample_names_num(c,7)+offset_to806B(1,1);
        elseif Hole==3
            mbsf_806Beq(c)=sample_names_num(c,7)+offset_to806B(1,2);
        end
    end
end

% Append calculated 806B equivalent mbsf to original table of sample names
sample_names_num = [sample_names_num mbsf_806Beq];
sample_names_raw = [sample_names_raw ['806Beq mbsf'; num2cell(mbsf_806Beq)]];


%%%%% Convert to mcd
agemodel_mbsf2mcd=xlsread('agemodel_806_forMatlabcode.xlsx', 'mbsf_to_mcd');
mcd=zeros(length(mbsf_806Beq), 1);
% Matlab is dumb and thinks some of the values in the spreadsheet are
% different by 8x10^-16, so I'm rounding everything to the 2nd decimal place
offset_to_mcd=[round(agemodel_mbsf2mcd(:,1),2) round(agemodel_mbsf2mcd(:,4),2)];
offset_to_mcd=unique(offset_to_mcd, 'rows');
    

for a=1:length(mbsf_806Beq(:,1))
    core=sample_names_num(a,3);
    mcd(a)=sample_names_num(a,8) + offset_to_mcd(core,2);
end

% Append calculated 806B equivalent mbsf to original table of sample names
sample_names_num = [sample_names_num mcd];
sample_names_raw = [sample_names_raw ['mcd'; num2cell(mcd)]];


%%%%% Calculate ages
agemodel_d18O_ages=xlsread('agemodel_806_forMatlabcode.xlsx', 'd18O_agemodel');
agemodel_biostrat_ages=xlsread('agemodel_806_forMatlabcode.xlsx', 'biostrat_agemodel');
% Make vector to hold ages
ages(length(mcd))=0;
% Samples deeper than rev mbsf=107.98 must have ages calculated with
% biostrat model
for a=1:length(mcd)
    if mcd(a)<=107.98
        ages(a)=interp1(agemodel_d18O_ages(:,1), agemodel_d18O_ages(:,2), mcd(a));
    else 
        ages(a)=interp1(agemodel_biostrat_ages(:,1), agemodel_biostrat_ages(:,2), mcd(a));
    end
end
ages=ages';

% Append calculated ages to original table of sample names
sample_names_num = [sample_names_num ages];
sample_names_raw = [sample_names_raw ['Age (Ma)'; num2cell(ages)]];