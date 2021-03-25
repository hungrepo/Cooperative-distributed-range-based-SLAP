function Main_Tracking
% Initialization
 [tf,Ts,MPC,Mode,Noise,Tracker,Target]=TLAT_Initilization();
%% Start main Loop %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for t = 0:Ts:tf
    if t==0
        R=10;
        omega=0.1;
        upf=[];
        phi1=0;
        phi2=pi/2;
        pd1=Target.Id1.Pos + [R*cos(omega*t+phi1);
                              R*sin(omega*t+phi1)];
        pd1_dot=Target.Id1.Vel + [-R*omega*sin(omega*t+phi1);
                                  R*omega*cos(omega*t+phi1)];
        
        pd2=Target.Id1.Pos + [R*cos(omega*t+phi2);
                              R*sin(omega*t+phi2)];

        pd2_dot=Target.Id1.Vel + [-R*omega*sin(omega*t+phi2);
                                  R*omega*cos(omega*t+phi2)];
                              
                              
        pd1_hat=[];
        pd2_hat=[];
        pd1_hat_dot=[];
        pd2_hat_dot=[];
%          pd_hat=Target.Id1.PosEst0 + [R*cos(omega*t);
%                                       R*sin(omega*t)];
%          pd_hat_dot=Target.Id1.EstVel0+[-R*omega*sin(omega*t);
%                                          R*omega*cos(omega*t)];              
                              
        P=diag([20,20,.5,.5]);
        Target.Id1.Est=[Target.Id1.PosHat0; Target.Id1.VelHat0];
    end
    
    
%% Tracker information

Tracker.Id1.Yaw=Tracker.Id1.State(3,end);
Tracker.Id1.Pos=Tracker.Id1.State(1:2,end);
Rot1 =   [cos(Tracker.Id1.Yaw) -sin(Tracker.Id1.Yaw);
          sin(Tracker.Id1.Yaw)  cos(Tracker.Id1.Yaw)];
      
Tracker.Id2.Yaw=Tracker.Id2.State(3,end);
Tracker.Id2.Pos=Tracker.Id2.State(1:2,end);
Rot2 =   [cos(Tracker.Id2.Yaw) -sin(Tracker.Id2.Yaw);
          sin(Tracker.Id2.Yaw)  cos(Tracker.Id2.Yaw)];
      
      

%% True Target information
%% Estimated target information
 r11=norm([Tracker.Id1.Pos-Target.Id1.Pos(:,end);Target.Id1.Depth])+0.5*randn;
 r12=norm([Tracker.Id2.Pos-Target.Id1.Pos(:,end);Target.Id1.Depth])+0.5*randn;
 
 [Target.Id1.Est(:,end+1),POut] = MTST_EKF_PosVel(r11,r12,Tracker.Id1.Pos,Tracker.Id2.Pos,Target.Id1.Est(:,end),P,Ts,Target.Id1.Depth,t);
  P=POut;
  
 pd1_hat(:,end+1)=Target.Id1.Est(1:2,end) + [R*cos(omega*t+phi1);
                                             R*sin(omega*t+phi1)];
 pd1_hat_dot(:,end+1)=Target.Id1.Est(3:4,end)+[-R*omega*sin(omega*t+phi1);
                                               R*omega*cos(omega*t+phi1)];      
  
 pd2_hat(:,end+1)=Target.Id1.Est(1:2,end) + [R*cos(omega*t+phi2);
                                             R*sin(omega*t+phi2)];
 pd2_hat_dot(:,end+1)=Target.Id1.Est(3:4,end)+[-R*omega*sin(omega*t+phi2);
                                               R*omega*cos(omega*t+phi2)];      
                                           
                                           
%% Tracking error
% e1=Rot1'*(Tracker.Id1.Pos(1:2,end)-pd1(:,end));
% e2=Rot2'*(Tracker.Id2.Pos(1:2,end)-pd2(:,end));

e1=Rot1'*(Tracker.Id1.Pos(1:2,end)-pd1_hat(:,end));
e2=Rot2'*(Tracker.Id2.Pos(1:2,end)-pd2_hat(:,end));

%% ------------------------------------

% control parameter
delta=0.5;
Delta=[1 0; 
       0 delta];
K=diag([.1,.1]);   
% control law  
% upf1=inv(Delta)*(Rot1'*pd1_dot(:,end)-K*(e1-[-delta; 0]));
% upf2=inv(Delta)*(Rot2'*pd2_dot(:,end)-K*(e2-[-delta; 0]));

upf1=inv(Delta)*(Rot1'*pd1_hat_dot(:,end)-K*(e1-[-delta; 0]));
upf2=inv(Delta)*(Rot2'*pd2_hat_dot(:,end)-K*(e2-[-delta; 0]));

Tracker.Id1.Input(:,end+1)=sat(upf1,Tracker.Id1.InputMin,Tracker.Id1.InputMax);
Tracker.Id2.Input(:,end+1)=sat(upf2,Tracker.Id1.InputMin,Tracker.Id1.InputMax);


%upf=[upf upfi];
    
% Step 2: Update the vehicle position and orientation
Tracker.Id1.State(:,end+1)=update_vehicle(Tracker.Id1.State(:,end),Tracker.Id1.Input(:,end),Ts,t);
Tracker.Id2.State(:,end+1)=update_vehicle(Tracker.Id2.State(:,end),Tracker.Id2.Input(:,end),Ts,t);

Target.Id1.Pos(:,end+1)=[100*cos(0.002*t)-100;  100*sin(0.002*t)];
Target.Id1.Vel(:,end+1)=[-0.2*sin(0.002*t); 0.2*cos(0.002*t)];
%% Desire Trajectories
% For vehicle 1
pd1(:,end+1)=Target.Id1.Pos(:,end)+ [R*cos(omega*t+phi1);
                                     R*sin(omega*t+phi1)];

pd1_dot(:,end+1)=Target.Id1.Vel(:,end) + [-R*omega*sin(omega*t+phi1);
                                           R*omega*cos(omega*t+phi1)];
% For vehicle 2
pd2(:,end+1)=Target.Id1.Pos(:,end)+ [R*cos(omega*t+phi2);
                                     R*sin(omega*t+phi2)];

pd2_dot(:,end+1)=Target.Id1.Vel(:,end) + [-R*omega*sin(omega*t+phi2);
                                           R*omega*cos(omega*t+phi2)];
end
%% Save Data to Workspace
    Tracker.Id1.State=Tracker.Id1.State';
    Tracker.Id2.State=Tracker.Id2.State';
    
    Target.Id1.Pos=Target.Id1.Pos';
    
    pd1=pd1';
    pd2=pd2';
    p1=Tracker.Id1.State(:,1:2);
    p2=Tracker.Id2.State(:,1:2);
   
    Target_PosEst=Target.Id1.Est(1:2,:)';
    Target_Pos=Target.Id1.Pos;
    save_to_base(1);
%% Run animation
%pd=x_path(:,1:2);
%pd_est=x_target_est(:,1:2);
yaw1=Tracker.Id1.State(:,3)*180/pi;
yaw2=Tracker.Id2.State(:,3)*180/pi;

resample_1vehicles
animation_1vehicles
end
%% End main loop %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Dynamics of Path and Vehicle %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function x_next=update_vehicle(x_current,input,Ts,t)
    input_robot.nSteps = 4;
    input_robot.Ts=Ts;
    input_robot.u=input;
    input_robot.x = x_current;
    output_robot = RK4_integrator(@vehicle, input_robot);
    x_next = output_robot.value;
end
%% vehicle dynamics
function dx = vehicle(t,x,u)
    psi=x(3);
    ur=u(1);
    r=u(2);
    dx=[ur*cos(psi);ur*sin(psi);r];
end
%% path dynamics
function x_next=update_path(x_current,input,pathtype,pathpar,Ts,t)
    input_path.nSteps = 4;
    input_path.Ts=Ts;
    input_path.u=input;
    input_path.x = [x_current(3);x_current(8)];
    path_par=[x_current(6);x_current(7)];
    output_path = RK4_integrator(@(t,x,u)path(t,x,u,path_par), input_path);
    psid=output_path.value(1); gamma=output_path.value(2);
    x_next=paths(pathtype,pathpar,gamma,psid,t);
end
function dx = path(t,x,u,path_data)
    hg=path_data(1);
    cg=path_data(2); 
    dx=[hg*cg;1]*u;
end
function y=sat(u,lowbound,upbound)
    y=max(min(u,upbound),lowbound);
end
function x_next = update_target(x_current,input,Ts,t)
    input_target.nSteps = 4;
    input_target.Ts=Ts;
    input_target.u=input;
    input_target.x=x_current;
    output_target = RK4_integrator(@target, input_target);
    x_next = output_target.value;
end
function dx=target(t,x,u)
dx=u;
end