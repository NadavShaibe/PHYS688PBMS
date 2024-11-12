%% Initialize
clear;clc;close all;
tic;
ft = 'Times';
Bool = [0 1];
%% Comments
% Simulation of Missile Attack - Written by Nadav Shaibe 11/5/24
% For educational purposes only
% Please direct questions or comments to nshaibe@umd.edu

%% Request information from user

%Number of Warheads
prompt = "Please input desired number of attacking warheads: ";
NW = input(prompt);
while NW<=0
    fprintf('Number of warheads cannot be negative or 0, try again. \n')
    prompt = "Please input desired number of attacking warheads: ";
    NW = input(prompt);
end

%Warhead Yield
prompt = "Please input desired yield of the warhead(s) in units of kt (kilotons of TNT): ";
Y = input(prompt);
while Y<=0
    fprintf('Yield cannot be negative or 0, try again. \n')
    prompt = "Please input desired yield of the warhead(s) in units of kt (kilotons of TNT): ";
    Y = input(prompt);
end

%CEP (Circle of Equal Probability)
prompt = "Please input the CEP of the warhead(s) in units of m (meters): ";
CEP = input(prompt);
while CEP<=0
    fprintf('CEP cannot be negative or 0, try again. \n')
    prompt = "Please input the CEP of the warhead(s) in units of m (meters): ";
    CEP = input(prompt);
end

%Presence of Interceptors

prompt = 'If you would like the defender to have interceptors, press 1, otherwise press 0: ';
Interceptors = input(prompt);
while ismember(Interceptors,Bool) ~=1
    fprintf('Invalid response, try again. \n')
    prompt = 'Please input a 1 (interceptors) or 0 (no interceptors): ';
    Interceptors = input(prompt);
end
if Interceptors ==0
    PI =0;
    NI =0;
    PropTP = 0;
    PropFP = 0;
    ND = 0;
else
    %Probability of interception
    prompt = 'You chose to include interceptors. What is the probability (out of 100) of intercepting a warhead with an intercerpter: ';
    PI = input(prompt);
    while PI <0 | PI >100
        fprintf('Probability of interception cannot be negative or greater than 100%, try again. \n')
        prompt = 'What is the probability (out of 100) of intercepting a warhead with one interceptor: ';
        PI = input(prompt);
    end
    %Number of Interceptors
    prompt = 'And how many interceptors should be sent after EACH warhead: ';
    NI = input(prompt);
    while NI<=0
        fprintf('Number of interceptors cannot be negative or 0, try again. \n')
        prompt = "Please input the number of interceptors per warhead: ";
        NI = input(prompt);
    end
    %Presence of decoys
    prompt = 'If you would like the warheads to have decoys, press 1, otherwise press 0: ';
    Decoys = input(prompt);
    while ismember(Decoys,Bool) ~=1
        fprintf('Invalid response, try again. \n')
        prompt = 'Please input a 1 (decoys) or 0 (no decoys): ';
        Decoys  = input(prompt);
    end
    if Decoys ==0
        PropTP = 1;
        PropFP = 0;
        ND = 0;
    else
        %Probability of true positive
        prompt = 'You chose to include decoys. What is the probability (out of 100) of a true positive: ';
        PropTP = input(prompt);
        while PropTP <0 | PropTP >100
            fprintf('Probability of a true positive cannot be negative or greater than 100%, try again. \n')
            prompt = 'What is the probability (out of 100) of a true positive: ';
            PropTP = input(prompt);
        end
        %Probability of false positive
        prompt = 'And what is the probability (out of 100) of a false positive: ';
        PropFP = input(prompt);
        while PropFP <0 | PropFP >100
            fprintf('Probability of a false positive cannot be negative or greater than 100%, try again. \n')
            prompt = 'What is the probability (out of 100) of a false positive: ';
            PropFP = input(prompt);
        end
        %Number of decoys
        prompt = 'And how many decoys should EACH warhead have: ';
        ND = input(prompt);
        while ND<=0
            fprintf('Number of decoys cannot be negative or 0, try again. \n')
            prompt = "Please input the number of decoys per warhead: ";
            ND = input(prompt);
        end
    end
end

%Target Hardness
prompt = "Finally, Please input hardness of the target in units of psi (pounds per square inch): ";
H = input(prompt);
while H<=0
    fprintf('Hardness cannot be negative or 0, try again. \n')
    prompt = "Please input hardness of the target in units of psi (pounds per square inch): ";
    H = input(prompt);
end
clear prompt

PI = PI/100;
PropFP = PropFP/100;
PropTP = PropTP/100;

%% Calculate LR and Probabilities
LR = 460*(Y/H)^(1/3); %units of meters

P_K1 = 1-0.5^((LR/CEP)^2); %probability of kill per warhead

P_W = (PropTP)/(PropTP+PropFP*ND); %Probability of correctly identifying warhead
if isnan(P_W) == 1
    P_W = 0;
    P_I = 0;
else
    P_I = (1-(1-PI*P_W)^NI);  %Probability of interception per interceptor per warhead
end

%% Draw Picture
theta=[0:0.001:2*pi];
xLR=LR*cos(theta); yLR=LR*sin(theta);
xCEP=CEP*cos(theta); yCEP=CEP*sin(theta);
radius = 2*max(CEP,LR);
numpoints = 1001;
xpoints = linspace(-radius,radius,numpoints);
ypoints = xpoints;
[p,q] = meshgrid(xpoints,ypoints);
pairs = [p(:) q(:)];
idx_LR = double(sqrt((pairs(:,1)).^2+(pairs(:,2)).^2)<=LR);
idx_CEP = double(sqrt((pairs(:,1)).^2+(pairs(:,2)).^2)<=CEP);
inCEP = pairs(find(idx_CEP==1),:);
outCEP = pairs(find(idx_CEP==0),:);
inLR = pairs(find(idx_LR==1),:);
clear idx_CEP idx_LR p q pairs theta

%calculate if intercepted
suc = rand(NW,1);
NumIntercepted = length(find(suc<P_I));
NumPassed = NW-NumIntercepted;
inout = rand(NumPassed,1);
clear hitlocation
hitlocation(inout<0.5,:)=inCEP(randi(length(inCEP),length(find(inout<0.5)),1),:);
hitlocation(inout>0.5,:)=outCEP(randi(length(outCEP),length(find(inout>0.5)),1),:);

NLR = length(find(ismember(hitlocation,inLR,'rows')));
P_K = 1-(1-P_K1)^NumPassed;

%%
figure('Position',[200,100,1500,730]);
hold on;
plot(0,0,'.r','MarkerSize',30)
plot(0,0,'.w','MarkerSize',20)
plot(0,0,'.r','MarkerSize',8)
plot(xLR,yLR,'--b');
plot(xCEP,yCEP,'--g');
plot(hitlocation(:,1),hitlocation(:,2),'*k','markersize',12);
grid on
box on
axis equal tight
xlim([xpoints(1) xpoints(end)])
ylim([ypoints(1) ypoints(end)])
text(0,0,'Target','HorizontalAlignment','center','VerticalAlignment','top','fontsize',18,'Interpreter','latex')
% txt = text(3/2*radius,1/2*radius, ['\underline{Intercepted Warheads:}' + NumIntercepted],'HorizontalAlignment','center','fontsize',18,'Interpreter','latex')
txtINT = compose(['\\underline{Intercepted Warheads: %d}'],NumIntercepted);
text(radius+radius/10,radius,txtINT,'HorizontalAlignment','left','fontsize',18,'Interpreter','latex')
txtREM = compose(['\\underline{Unintercepted Warheads: %d}'],NumPassed);
text(radius+radius/10,3/4*radius,txtREM,'HorizontalAlignment','left','fontsize',18,'Interpreter','latex')
txtPK = compose(['\\underline{P(Kill$|$Remaining Warheads): %.4f}'],P_K);
text(radius+radius/10,1/2*radius,txtPK,'HorizontalAlignment','left','fontsize',18,'Interpreter','latex')
txtLR = compose(['\\underline{Detonations in Lethal Radius: %d}'],NLR);
text(radius+radius/10,1/4*radius,txtLR,'HorizontalAlignment','left','fontsize',18,'Interpreter','latex')
if NLR >=1
    txtD = compose(['\\underline{Target Destroyed: Yes}']);
else
    txtD = compose(['\\underline{Target Destroyed: No}']);
end
text(radius+radius/10,0*radius,txtD,'HorizontalAlignment','left','fontsize',18,'Interpreter','latex')
txtLUN = compose(['\\underline{Launched Warheads: %d}'],NW);
text(-radius-radius/3,radius,txtLUN,'HorizontalAlignment','right','fontsize',18,'Interpreter','latex')
txtPIT = compose(['\\underline{P(Intercept Warhead): %.4f}'],P_I);
text(-radius-radius/3,3/4*radius,txtPIT,'HorizontalAlignment','right','fontsize',18,'Interpreter','latex')
txtPK1 = compose(['\\underline{P(Kill$|$Single Warhead): %.4f}'],P_K1);
text(-radius-radius/3,1/2*radius,txtPK1,'HorizontalAlignment','right','fontsize',18,'Interpreter','latex')
txtLTR = compose(['\\underline{Lethal Radius: %.0f m}'],LR);
text(-radius-radius/3,1/4*radius,txtLTR,'HorizontalAlignment','right','fontsize',18,'Interpreter','latex')
txtHRD = compose(['\\underline{Target Hardness: %.0f psi}'],H);
text(-radius+-radius/3,0*radius,txtHRD,'HorizontalAlignment','right','fontsize',18,'Interpreter','latex')
% legend('Target','Lethal Radius','CEP','Warhead Detonations','Interpreter','latex')
if NumPassed>0
    legend('Target','','','Lethal Radius','CEP','Interpreter','latex','position',[0.1 0.1 0.1 0.1])
else
    legend('Target','','','Lethal Radius','CEP','Warhead Detonations','Interpreter','latex','position',[0.1 0.1 0.1 0.1])
end
xlabel('Distance from target (m)','Interpreter','latex')
% ylabel('Distance from target (m)','Interpreter','latex')
set(gca,'fontsize',24,'fontname',ft)
