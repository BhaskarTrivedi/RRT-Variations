% This file is created by U. Cem Kaya - 2018
%% MAIN FUNCTION

function [MultiplePaths,finalPath,FinalSmoothedPath,riskExposureLevels]...
    = mainFunc(mapSize, start, finish,distThresh, stepSize, iterMax, goalProb, delayOption, figHandle,...
    Velocity,PREM,dX,dY,PURM,X_Grid,Y_Grid,Population,goalProbTree2,RiskThreshold,obstacles,ResMapSize,...
    Constraints,plotBranches,RecordVideo,randNodeExtProb,p_quasi,pathFigs,T)

T1 = T;
T2 = T;

gama = 1.5*stepSize; %radius of rewiring with logarithmic decrease
alpha = 5; % (1/alpha), dimensions of planning

if RecordVideo
    figure(figHandle)
    writerObj = VideoWriter('PathsFound.avi');
    writerObj.FrameRate = 0.5;
    open(writerObj);
end

success = false; % initially condition of the connection between trees

% Set the first element of a start tree
pathTree1(1).x = start(1);
pathTree1(1).y = start(2);
pathTree1(1).parent = 1;
pathTree1(1).children = [];
pathTree1(1).CumulativeCost = 0;
pathTree1(1).cost = 0;
pathTree1(1).privacyCost = 0;
pathTree1(1).totalDistance = 0;
pathTree1(1).psi = pi/2;
pathTree1(1).vel = Velocity;
pathTree1(1).time = 0;
pathTree1(1).ID = 1;
pathTree1(1).TreeNo = 1;
Tree1 = digraph;
Tree1 = addnode(Tree1,1);
% Set the first element of a goal tree
pathTree2(1).x = finish(1);
pathTree2(1).y = finish(2);
pathTree2(1).parent = 1;
pathTree2(1).children = [];
pathTree2(1).CumulativeCost = 0;
pathTree2(1).cost = 0;
pathTree2(1).privacyCost = 0;
pathTree2(1).totalDistance = 0;
pathTree2(1).psi = 0;
pathTree2(1).vel = Velocity;
pathTree2(1).time = 0;
pathTree2(1).ID = 1;
pathTree2(1).TreeNo = 2;
Tree2 = digraph;
Tree2 = addnode(Tree2,1);
    
% Print out options
fprintf('---------------------------------------------------- \n');
fprintf('##### bi-directional RRT* - Path Planning ##### \n');
fprintf('---------------------------------------------------- \n\n');
fprintf('Starting the simulation \n');
fprintf('Using the following options: \n');
%fprintf('Max number of iterations: %d \n', iter);
fprintf('Distance to the target threshold: %d \n', distThresh);
fprintf('Goal probability: %f \n', goalProb);
fprintf('Step size: %d meters\n', stepSize);
fprintf('Start position: %d, %d meters\n', start(1), start(2));
fprintf('Finish position: %d, %d meters\n', finish(1), finish(2));
%     fprintf('Map size: %d, %d nmi\n\n\n', mapSize(1),mapSize(2));
    
fprintf('Searching for the optimum path... \n');
    
NodeIDsuccess_1 = [];
NodeIDsuccess_2 = [];
NodeID_conn_1 = [];
NodeID_conn_2 = [];
% %  goalSelected = 0;
% %  extended_to_goal = 0;

 total_distances = [];
 riskExposureLevels = [];
 maxRiskRates = [];
 MultiplePaths = {};
%  SmoothedPaths = [];

 RiskExposureLimit = inf;
%  MaxRiskRateLimit = inf;
 
Path =struct('x',[],'y',[],'cost',[],'parent',[],'psi',[],'vel',[]);

FinalPath = [];

currMinRiskLevel = 0;

% Loop until nearest is close enough to goal or until iterMax is reached
for iter=1:iterMax
    
% Delay between iteration displays
    switch delayOption
        case 1
            % No delay
        case 2
            pause(0.001);
        case 3
            pause(2.0);
        case 4
            disp('Press any key (for example space) for next step');
            pause;
    end     
        
    if isempty(MultiplePaths) % if no path has found, grow trees until you found
        [success,Tree1,Tree2,pathTree1,pathTree2,NodeIDsuccess_1,NodeIDsuccess_2,T1,T2]...
            = bi_T_RRTstar(mapSize, start, finish,distThresh, stepSize, goalProb, figHandle,...
            Velocity,PREM,dX,dY,PURM,X_Grid,Y_Grid,Population,goalProbTree2,RiskThreshold,obstacles,ResMapSize,...
            Constraints,plotBranches,randNodeExtProb,pathTree1,pathTree2,Tree1,Tree2,gama,p_quasi,iter,alpha,T1,T2);
        
    else % if there are paths found, you keep growing trees and at the same time optimize the found paths
        NumOfPaths = length(MultiplePaths);
%         randNodeExtProb = 1 - (log2(NumOfPaths+1)/(NumOfPaths+1))^0.5;
        randNodeExtProb = 0.02;
        
%             if rand > log10(1+NumOfPaths)/50 % grow trees normally
%             if rand > 0.02 % grow trees normally
        if 1==1
            [success,Tree1,Tree2,pathTree1,pathTree2,NodeIDsuccess_1,NodeIDsuccess_2,T1,T2]...
                = bi_T_RRTstar(mapSize, start, finish,distThresh, stepSize, goalProb, figHandle,...
                Velocity,PREM,dX,dY,PURM,X_Grid,Y_Grid,Population,goalProbTree2,RiskThreshold,obstacles,ResMapSize,...
                Constraints,plotBranches,randNodeExtProb,pathTree1,pathTree2,Tree1,Tree2,gama,p_quasi,iter,alpha,T1,T2);
    
        else % locally optimize randomly previously found paths
                
            SlctRandPathID = randi([1 NumOfPaths],1,1);
%                 [currMinRiskLevel,minRiskPathID] = min(riskExposureLevels);
%                 SlctRandPathID = round(minRiskPathID +0.2*NumOfPaths*randn);
%                 SlctRandPathID = minRiskPathID;
%                 SlctRandPathID = NumOfPaths;
            SlctRandPath = MultiplePaths{SlctRandPathID};
            numOfIterations = 5;

            [~,~,~,pathTree1,pathTree2] = LocalBiasSmoothing(SlctRandPath,...
                PREM,mapSize,dX,dY,PURM,X_Grid,Y_Grid,Population,Velocity,figHandle,RiskThreshold,obstacles,...
                numOfIterations,pathTree1,Tree1,pathTree2,Tree2,stepSize,ResMapSize,Constraints,gama,...
                start,finish,NodeID_conn_1(SlctRandPathID),NodeID_conn_2(SlctRandPathID));
                
%                 if smooth_REL < riskExposureLevels(SlctRandPathID)
%                 
%                     riskExposureLevels(SlctRandPathID) = smooth_REL;
%                     
%                     MultiplePaths{SlctRandPathID} = SmoothedPath;
%                 
%                     if RecordVideo
%                         delete(SmoothedPaths);
%                         
%                         SmoothedPaths =  plot([SmoothedPath(:).x]',[SmoothedPath(:).y]','m-','LineWidth', 1.1);
%                         
%                         frm = getframe;
%                         img = frame2im(frm);
%                         writeVideo(writerObj, img);
%                     end
%                 
%                 end
        
        end
            
            
    end
   
    if success == true
        
        title(['Iter = ' num2str(iter)])
% %             successNodeCosts = zeros(length(NodeIDsuccess_1),1);
% %             
% %             for jj =1:length(NodeIDsuccess_1)
% %                 successNodeCosts(jj)= (pathTree1(NodeIDsuccess_1(jj)).CumulativeCost + pathTree2(NodeIDsuccess_2(jj)).CumulativeCost);
% %             end
% %         [minPathCost,ID] = min(successNodeCosts);
% %         
% %             if (pathTree1(NodeIDsuccess_1(ID)).CumulativeCost+pathTree2(NodeIDsuccess_2(ID)).CumulativeCost)<RiskExposureLimit
% %             [Path, riskExposureLevel,total_distance] = bidirectionalBacktrack(pathTree1,pathTree2,start,finish,NodeIDsuccess_1(ID),NodeIDsuccess_2(ID),...
% %                      figHandle,V_tar1,PURM,success,Path);
             
        if (pathTree1(NodeIDsuccess_1(end)).CumulativeCost+pathTree2(NodeIDsuccess_2(end)).CumulativeCost)< 1.0*RiskExposureLimit
            [Path, riskExposureLevel,total_distance,MaxRiskRate] = bidirectionalBacktrack(pathTree1,pathTree2,start,finish,NodeIDsuccess_1(end),NodeIDsuccess_2(end),...
                figHandle,Velocity,PURM,success,Path);
                                  
            if (isempty(MultiplePaths))
            
                if RecordVideo
                    firstPath =  plot([Path(:).x]',[Path(:).y]','r-','LineWidth', 1.5);
                
                    frm = getframe;
                    img = frame2im(frm);
                    writeVideo(writerObj, img);
                    
                    set(firstPath,'visible','off')
                end
                       
            else

%                      if RecordVideo
% %                          delete(Paths);
%                          
% %                          figure(figHandle);
%                          Paths(end+1) =  plot([Path(:).x]',[Path(:).y]','k','LineWidth', 1.5);
%                      
%                          frm = getframe;
%                          img = frame2im(frm);
%                          writeVideo(writerObj, img);
%                          
%                          set(Paths(end),'visible','off')
%                      end
                     
                if RecordVideo && (riskExposureLevel<currMinRiskLevel(1))
%                          delete(FinalPath);
                         
%                          figure(figHandle);
                         FinalPath(end+1) =  plot([Path(:).x]',[Path(:).y]','b','LineWidth', 1.5);
                         
                         frm = getframe;
                         img = frame2im(frm);
                         writeVideo(writerObj, img);
                         
                         set(FinalPath(end),'visible','off')
                end
                                   
            end
                 
            if  riskExposureLevel < RiskExposureLimit
            
                riskExposureLevels(end+1) = riskExposureLevel;
                maxRiskRates(end+1) = MaxRiskRate;
                
                MultiplePaths(end+1) = {Path};
                total_distances(end+1) = total_distance;
                
                RiskExposureLimit = 0.99*min(riskExposureLevels);
                %                 RiskExposureLimit = inf;
                MaxRiskRateLimit = 0.99*max(maxRiskRates);
                %                 MaxRiskRateLimit = inf;
                
                RiskThreshold.Cumulative = RiskExposureLimit;
                RiskThreshold.ExposureRate = MaxRiskRateLimit;
                
                [currMinRiskLevel,~] = min(riskExposureLevels);
                
                NodeID_conn_1(end+1) = NodeIDsuccess_1(end);
                NodeID_conn_2(end+1) = NodeIDsuccess_2(end);
            
            end
                 
            success = false;
        %             break;
                            
        end
    end
           
                 
end
      
    
if (isempty(MultiplePaths))
    
    MultiplePaths = [];
    finalPath = [];
    riskExposureLevels = [];
    fprintf('Goal was not reached! Try changing parameters \n');
    
else
% %         success = 1;
% %         [minREL, ID] = min(riskExposureLevels);
% %     [finalPath, REL_Final,total_distance_Final] = bidirectionalBacktrack(pathTree1,pathTree2,start,finish,NodeIDsuccess_1,NodeIDsuccess_2,...
% %                      figHandle,V_tar1,PURM,success,finalPath);
                 
% %         [FinalSmoothedPath,smoothTotal_distance,smooth_REL] = LocalBiasingSmoothing(finalPath,total_distance_Final,...
% %     REL_Final,PREM_value,mapSize,dX,dY,PURM,X_Grid,Y_Grid,Population,V_tar1);
        
    [~, ID] = min(riskExposureLevels);
    finalPath = MultiplePaths{ID};
    REL_Final = finalPath(end).CumulativeCost;
    total_distance_Final = finalPath(end).totalDistance;
    
    FinalSmoothedPath = finalPath;
        
% %         [FinalSmoothedPath,smoothTotal_distance,smooth_REL,~,~] = LocalBiasSmoothing(finalPath,...
% %             PREM,mapSize,dX,dY,PURM,X_Grid,Y_Grid,Population,Velocity,figHandle,RiskThreshold,obstacles,...
% %             2000,pathTree1,Tree1,pathTree2,Tree2,stepSize,ResMapSize,Constraints,gama,...
% %             start,finish,NodeID_conn_1(end),NodeID_conn_2(end));
% %         
% %         FinalSmoothPath_hnd =  plot([FinalSmoothedPath(:).x]',[FinalSmoothedPath(:).y]','r','LineWidth', 3.0);
% %                 
    if RecordVideo
%             figure(figHandle);
            
            set(firstPath,'visible','on','Color','blue','LineStyle','-.','LineWidth',1.5)

%             set(Paths(:),'visible','on','Color','black','LineStyle','-','LineWidth',0.8)

            set(FinalPath(end),'visible','on','Color','r','LineStyle','-','LineWidth',2.5)
            set(FinalPath(1:end-1),'visible','on','Color','b','LineStyle','--','LineWidth',0.5)
            
            title('\bf RRT Generated Path - Top View')

            lgd = legend([firstPath FinalPath(end)],'First Path','Final Path', 'start','finish','location','north','orientation','horizontal');
            lgd.FontSize = 8;
            lgd.Color = 'w';
            lgd.Position = [0.35 0.125 0.35 0.04];
            


            frm = getframe;
            img = frame2im(frm);
            writeVideo(writerObj, img);
            
            close(writerObj);
    end
        
%         [SmoothedPath,smoothTotal_distance,smooth_REL,~,~] = LocalBiasingSmoothing(finalPath,...
%                     PREM,ResMapSize,dX,dY,PURM,X_Grid,Y_Grid,Population,Velocity,figHandle,RiskThreshold,obstacles,...
%                     10000,pathTree1,Tree1,pathTree2,Tree2);
%                 
%         SmoothPath =  plot([SmoothedPath(:).x]',[SmoothedPath(:).y]','g','LineWidth', 2.5);
%         hold on   
        
newFigure13 = copyobj(figHandle,'legacy');

% % fncSaveFig(1,pathFigs,'RRT_Path21Colored',11,6,4);

figure
k = plot(total_distances,riskExposureLevels,'r*','linewidth',2,'MarkerSize',5);
hold on
l = plot(total_distance_Final,REL_Final,'g^','linewidth',3,'MarkerSize',10);
hold on
m = plot(total_distances(1),riskExposureLevels(1),'bs','linewidth',3,'MarkerSize',8);
hold on

%         n = plot(smoothTotal_distance,smooth_REL,'mo','linewidth',2,'MarkerSize',7);
%         hold on
title('\bf Risk vs Total Distance Graph ');
xlabel('\bf Total Distance of UAV along path, km');
ylabel('\bf Risk along path');
grid on
axis([0 1.2*max(total_distances) 0 1.2*max(riskExposureLevels)]);
lgd =  legend([m l k],'First','Final','Alternative','location','south','orientation','horizontal');
lgd.Position = [0.345 0.15 0.35 0.02];
lgd.FontSize = 8;

% % fncSaveFig(1,pathFigs,'PathREL21',11,6,4);


% % % % Print out results
% % % fprintf('Goal was reached! \n');
% % % fprintf('Path distance: %d \n', total_distance_Final);
% % % fprintf('Number of iterations: %d \n', iter);
% % % fprintf('Number of tree branches: %d \n', (length(pathTree1)+length(pathTree2)));
% % % fprintf('# of iterations Goal Selected: %d \n', goalSelected);
% % % fprintf('# of iterations Extended to Goal failed: %d \n', (goalSelected-extended_to_goal));
end
    
end


%% BI-T-RRTstar FUNCTION

function [success,Tree1,Tree2,pathTree1,pathTree2,NodeIDsuccess_1,NodeIDsuccess_2,T1,T2]...
    = bi_T_RRTstar(mapSize, start, finish,distThresh, stepSize, goalProb, figHandle,...
    Velocity,PREM,dX,dY,PURM,X_Grid,Y_Grid,Population,goalProbTree2,RiskThreshold,obstacles,ResMapSize,...
    Constraints,plotBranches,randNodeExtProb,pathTree1,pathTree2,Tree1,Tree2,gama,p_quasi,iter_N,alpha,T1,T2)

success = false;
NodeIDsuccess_1 = 0;
NodeIDsuccess_2 = 0;
% Call the function to select the next target
        [target,~] = ChooseTarget(finish, ResMapSize, goalProb,p_quasi,iter_N);        
% %         goalSelected = goalSelected + finishSelected;

% %         figure(figHandle);
%         plot(target(1) , target(2), 'ro');
% %         hold on
        
        KDtree1 = KDTreeSearcher([pathTree1.x;pathTree1.y]');

        if rand < randNodeExtProb 
            [randNode_1, randNodeID_1] = RandomNode(pathTree1);
            [pathTree1,Tree1,extended_1,T1] = Extend_1(randNode_1, target, stepSize,randNodeID_1,pathTree1,Tree1,PREM,ResMapSize,...
                dX,dY,PURM,X_Grid,Y_Grid,Population,RiskThreshold,obstacles,Constraints,Velocity,T1);

        else
   
            % Call the function to find the closest node to target
            [nearestNode_1, nearestNodeID_1] = NearestNode(pathTree1, target,KDtree1);
            % Call the function to extend the branch towards next target
            [pathTree1,Tree1,extended_1,T1] = Extend_1(nearestNode_1, target, stepSize,nearestNodeID_1,pathTree1,Tree1,PREM,ResMapSize,...
                dX,dY,PURM,X_Grid,Y_Grid,Population,RiskThreshold,obstacles,Constraints,Velocity,T1);
                      
        end
                
        NumOfNodes_1 = length(pathTree1);
        NumOfNodes_2 = length(pathTree2);
        if (extended_1 ~= 0) 
            
% %             if finishSelected == 1
% %                 extended_to_goal = extended_to_goal + 1;
% %             end
         %% Find Nodes in the neighborhood of the New Node
%             temp=(200*log(length([pathTree.x]))/length([pathTree.x]))^(1/2);
%             r=min(stepSize,temp);

            
%         r_1 = Dist(extended_1,PathNode_1)*cr1;
        r_1 = gama*(log(NumOfNodes_1)/(NumOfNodes_1))^(1/alpha);
        nearNodes_1=Near(pathTree1,extended_1,r_1,KDtree1);
        
            
            extendedNode_1 = pathTree1(end);
            extendedNode_1.ID = length(pathTree1);
            
            [pathTree1,Tree1] = RewireNodes(pathTree1,Tree1,extendedNode_1,nearNodes_1,...
                                PREM,figHandle,mapSize,dX,dY,PURM,X_Grid,Y_Grid,...
                                Population,Constraints,T1);
            
            if plotBranches
            % Plot line
            figure(figHandle);
            plot([pathTree1(pathTree1(end).parent).x pathTree1(end).x] , [pathTree1(pathTree1(end).parent).y pathTree1(end).y] ,'b','LineWidth', 2);
            hold on;
            end
            
             if (Dist(finish, extended_1) < distThresh )
                 
                 [success,NodeIDsuccess_1,NodeIDsuccess_2] = ConnectionCheck(extendedNode_1.ID,1,pathTree1,pathTree2,Constraints,NodeIDsuccess_1,NodeIDsuccess_2);    
  
%                  break
             end
            

            
            [target2,~] = ChooseTarget(extended_1, ResMapSize, goalProbTree2,p_quasi,iter_N);
            
% %             figure(figHandle);
%             plot(target2(1) , target2(2), 'ro');
% %             hold on
            
            KDtree2 = KDTreeSearcher([pathTree2.x;pathTree2.y]');
            
            if rand < randNodeExtProb
                [randNode_2, randNodeID_2] = RandomNode(pathTree2);
                [pathTree2,Tree2,extended_2,T2] = Extend_1(randNode_2, target2, stepSize,randNodeID_2,pathTree2,Tree2,PREM,ResMapSize,...
                    dX,dY,PURM,X_Grid,Y_Grid,Population,RiskThreshold,obstacles,Constraints,Velocity,T2);
                            
            else
                      
                [nearestNode_2,nearestNodeID_2] = NearestNode(pathTree2,target2,KDtree2);
                
                [pathTree2,Tree2,extended_2,T2] = Extend_1(nearestNode_2, target2, stepSize,nearestNodeID_2,pathTree2,Tree2,PREM,ResMapSize,...
                    dX,dY,PURM,X_Grid,Y_Grid,Population,RiskThreshold,obstacles,Constraints,Velocity,T2);
                

            end
                
                    if (extended_2 ~= 0)
                        
%                          r_2 = Dist(extended_2,PathNode_2)*cr2;
                         r_2 = gama*(log(NumOfNodes_2)/NumOfNodes_2)^(1/alpha);
                         nearNodes_2=Near(pathTree2,extended_2,r_2,KDtree2);
                        
                        extendedNode_2 = pathTree2(end);
                        extendedNode_2.ID = length(pathTree2);
                        
                        [pathTree2,Tree2] = RewireNodes(pathTree2,Tree2,extendedNode_2,...
                                            nearNodes_2,PREM,figHandle,mapSize,dX,dY,...
                                            PURM,X_Grid,Y_Grid,Population,Constraints,T2);
                        
                        if plotBranches
                         % Plot line
                         figure(figHandle);
                         plot([pathTree2(pathTree2(end).parent).x pathTree2(end).x] , [pathTree2(pathTree2(end).parent).y pathTree2(end).y] ,'r','LineWidth', 2);
                         hold on;
                        end
                        
                          KDtree1 = KDTreeSearcher([pathTree1.x;pathTree1.y]');
                          KDtree2 = KDTreeSearcher([pathTree2.x;pathTree2.y]');
                          
                          [nearestToExt2_1, nearestToExt2ID_1] = NearestNode(pathTree1, extended_2,KDtree1);
                          [nearestToExt1_2, nearestToExt1ID_2] = NearestNode(pathTree2, extended_1,KDtree2);
            
                             if (Dist(nearestToExt2_1, extended_2) < distThresh )
                
                                 [success,NodeIDsuccess_1,NodeIDsuccess_2] = ConnectionCheck(nearestToExt2ID_1,extendedNode_2.ID,pathTree1,pathTree2,Constraints,NodeIDsuccess_1,NodeIDsuccess_2); 

%                                  break
            
                             elseif (Dist(nearestToExt1_2, extended_1) < distThresh )
           
                                  [success,NodeIDsuccess_1,NodeIDsuccess_2] = ConnectionCheck(extendedNode_1.ID,nearestToExt1ID_2,pathTree1,pathTree2,Constraints,NodeIDsuccess_1,NodeIDsuccess_2); 
         
%                                   break
                             end
       
                    else
                        
                          [nearestToExt1_2, nearestToExt1ID_2] = NearestNode(pathTree2, extended_1,KDtree2);
            

            
                          if (Dist(nearestToExt1_2, extended_1) < distThresh ) 
                              
                              [success,NodeIDsuccess_1,NodeIDsuccess_2] = ConnectionCheck(extendedNode_1.ID,nearestToExt1ID_2,pathTree1,pathTree2,Constraints,NodeIDsuccess_1,NodeIDsuccess_2);

%                               break;      
                          end

                         
                    end
                    

            
                    
        elseif(extended_1 == 0)
                 
            
            [target2,~] = ChooseTarget(start, ResMapSize, goalProbTree2,p_quasi,iter_N);
            
% %             figure(figHandle);
%         plot(target2(1) , target2(2), 'ro');
% %         hold on
        
            KDtree2 = KDTreeSearcher([pathTree2.x;pathTree2.y]');
            
            if rand <= randNodeExtProb
                [randNode_2, randNodeID_2] = RandomNode(pathTree2);
                [pathTree2,Tree2,extended_2,T2] = Extend_1(randNode_2, target2, stepSize,randNodeID_2,pathTree2,Tree2,PREM,ResMapSize,...
                    dX,dY,PURM,X_Grid,Y_Grid,Population,RiskThreshold,obstacles,Constraints,Velocity,T2);
                
            else
            
                [nearestNode_2,nearestNodeID_2] = NearestNode(pathTree2,target2,KDtree2);
                
                [pathTree2,Tree2,extended_2,T2] = Extend_1(nearestNode_2, target2, stepSize,nearestNodeID_2(1),pathTree2,Tree2,PREM,ResMapSize,...
                    dX,dY,PURM,X_Grid,Y_Grid,Population,RiskThreshold,obstacles,Constraints,Velocity,T2);
                

            end
            
                    if (extended_2 ~= 0)
                        
%                          r_2 = Dist(extended_2,PathNode_2)*cr2;
                        r_2 = gama*(log(NumOfNodes_2)/NumOfNodes_2)^(1/alpha);
                         nearNodes_2=Near(pathTree2,extended_2,r_2,KDtree2);

                        extendedNode_2 = pathTree2(end);
                        extendedNode_2.ID = length(pathTree2);
                        
                        [pathTree2,Tree2] = RewireNodes(pathTree2,Tree2,extendedNode_2,...
                                            nearNodes_2,PREM,figHandle,mapSize,dX,dY,...
                                            PURM,X_Grid,Y_Grid,Population,Constraints,T2);
                        
                        if plotBranches
                            % Plot line
                            figure(figHandle);
                            plot([pathTree2(pathTree2(end).parent).x pathTree2(end).x] , [pathTree2(pathTree2(end).parent).y pathTree2(end).y] ,'r','LineWidth', 2);
                            hold on;
                        end
                         
                         [nearestToExt2_1, nearestToExt2ID_1] = NearestNode(pathTree1, extended_2,KDtree1);
            

            
                          if (Dist(nearestToExt2_1, extended_2) < distThresh )
                
                              [success,NodeIDsuccess_1,NodeIDsuccess_2] = ConnectionCheck(nearestToExt2ID_1,extendedNode_2.ID,pathTree1,pathTree2,Constraints,NodeIDsuccess_1,NodeIDsuccess_2);

%                               break;      
                          end
                          
                         
                    end          
            
               
        end
        
        
        

end

%% CHOSE TARGET FUNCTION
function [target,goalSelected] = ChooseTarget(finish, ResMapSize, goalProb,p_quasi,N)

    
    % Create a random value between 0 and 1
    p = rand;
%% QUASI-RANDOM SAMPLING 
% %     if ( (p > 0) && (p < goalProb) )
% %         target = finish;
% %         goalSelected = 1;
% %     elseif ( (p > goalProb) && (p < 1) )
% %         target(1) = (ResMapSize(1,1) + (ResMapSize(2,1)-ResMapSize(1,1))*p_quasi(N,1));
% %         target(2) = (ResMapSize(1,2) + (ResMapSize(2,2)-ResMapSize(1,2))*p_quasi(N,2));%r = a + (b-a).*rand(100,1); range of [a, b]
% %         goalSelected = 0;
% %     end

%% UNIFORM RAND SAMPLING
    if ( (p > 0) && (p < goalProb) )
        target = finish;
        goalSelected = 1;
    elseif ( (p > goalProb) && (p < 1) )
        target(1) = (ResMapSize(1,1) + (ResMapSize(2,1)-ResMapSize(1,1))*rand);
        target(2) = (ResMapSize(1,2) + (ResMapSize(2,2)-ResMapSize(1,2))*rand);%r = a + (b-a).*rand(100,1); range of [a, b]
        goalSelected = 0;
    end

end

%% RANDOM NODE FUNCTION
function [randNode, randNodeID] = RandomNode(tree)
    randNodeID = randi([1,length(tree)],1);
    
    randNode(1) = tree(randNodeID).x;
    randNode(2) = tree(randNodeID).y;
end
%% NEAREST NODE FUNCTION
function [nearestNode, nearestNodeID] = NearestNode(tree, target,KDtree)


    nearestNodeID = knnsearch(KDtree,target,'K',1);
    
    nearestNode(1) = tree(nearestNodeID).x;
    nearestNode(2) = tree(nearestNodeID).y;

% % % nodeDistArray = zeros(length(tree),1);
% % %     % Find distances from all nodes to the target
% % %     for i=1:length(tree)
% % %         tempNode(1) = tree(i).x;
% % %         tempNode(2) = tree(i).y;
% % %         nodeDistArray(i) = Dist(tempNode, target);
% % %     end
% % %     
% % %     % Find the ID of minimum distance
% % %     NodeID = find(nodeDistArray == min(nodeDistArray));
% % %     nearestNodeID = NodeID(1);
% % %     nearestNode(1) = tree(nearestNodeID).x;
% % %     nearestNode(2) = tree(nearestNodeID).y;
end

%% EUCLIDEAN DISTANCE BETWEED TWO 2D POINTS
function distance = Dist(x1, x2)
    % Calculate the euclidean distance between x and y
    distance  = sqrt( (x1(1) - x2(1))^2 + (x1(2) - x2(2))^2 );
end





function [success,NodeIDsuccess_1,NodeIDsuccess_2] = ConnectionCheck(id1,id2,...
        pathTree1,pathTree2,Constraints,NodeIDsuccess_1,NodeIDsuccess_2)

psi1 = pathTree1(id1).psi;
psi2 = pathTree2(id2).psi; 

dist = Dist([pathTree1(id1).x pathTree1(id1).y], [pathTree2(id2).x pathTree2(id2).y]);

delta_t_max = (dist/pathTree1(id1).vel)*Constraints.delta_t(2);
psiDot_Constraint = Constraints.psi_dot;

if psi2 < 0 % reverse the second tree connection angle
    psi2 = psi2 + pi;
else
    psi2 = psi2 - pi;
end

angDiff = psi2-psi1;
    
if angDiff < -pi
    angDiff = angDiff + 2*pi;
elseif angDiff > pi
    angDiff = angDiff - 2*pi;
end

if ((abs(angDiff)/delta_t_max)<=psiDot_Constraint)
    success = true;
    NodeIDsuccess_1(end+1) = id1;
    NodeIDsuccess_2(end+1) = id2;
else
    success = false;
end

end



