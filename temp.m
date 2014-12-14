% t = [1 2 3];

t = (rand(3,1)-.5)*2*pi;

Q = [1 0 0; 0 cos(t(3)) -sin(t(3)); 0 sin(t(3)) cos(t(3))] * ...
[cos(t(2)) 0 sin(t(2)); 0 1 0; -sin(t(2)) 0 cos(t(2))] * ...
[cos(t(1)) -sin(t(1)) 0; sin(t(1)) cos(t(1)) 0; 0 0 1];
% 
% c1c3 = Q(2,2)+Q(3,1)*Q(1,3)/(1-Q(1,3)^2);
% c1s3 = Q(3,2)-Q(2,1)*Q(1,3)/(1-Q(1,3)^2);
Q_by_wiki = [cos(t(2))*cos(t(3)), -cos(t(2))*sin(t(3)), sin(t(2)); ...
    cos(t(1))*sin(t(3)) + cos(t(3))*sin(t(1))*sin(t(2)), cos(t(1))*cos(t(3)) - sin(t(1))*sin(t(2))*sin(t(3)), -cos(t(2))*sin(t(1)); ...
    sin(t(1))*sin(t(3)) - cos(t(1))*cos(t(3))*sin(t(2)), cos(t(3))*sin(t(1)) + cos(t(1))*sin(t(2))*sin(t(3)), cos(t(1))*cos(t(2))];


    thetas = zeros(3,1);
    thetas(2) = asin(Q(1,3)); %val may be pi-val, cos(t(1)) will be +/-
    thetas(1) = acos(Q(1,1)/cos(thetas(2))); %if t2 is right, +/-.
    thetas(3) = acos(Q(3,3)/cos(thetas(2))); %if t2 is right, +/-.
    
    [thetas t]
    
    if abs(-Q(2,3)/cos(thetas(2))- sin(thetas(3))) > .00001
        %assume thetas2 is correct
        thetas(3) = -thetas(3);        
    end
    if abs(-Q(1,2)/cos(thetas(2)) - sin(thetas(1))) > .00001
        thetas(1) = -thetas(1); 
    end
    
    
    
    
%     
%     
    if abs(sin(thetas(1))*sin(thetas(3)) - cos(thetas(1))*cos(thetas(3))*sin(thetas(2)) - Q(3,1)) > .00001
%         disp(abs(sin(thetas(3))*cos(thetas(1))*sin(thetas(2)) + cos(thetas(3)) * sin(thetas(1)) - Q(2,1)))
%         %thetas(2) is wrong
        thetas(2) = pi-thetas(2);
%         if thetas(2) < -pi
%             thetas(2) = thetas(2)+pi*2;
%         elseif thetas(2) > pi
%             thetas(2) = thetas(2)-pi*2;
%         end
%     
%         thetas(1) = acos(Q(1,1)/cos(thetas(2))); %if t2 is right, +/-.
%         thetas(3) = acos(Q(3,3)/cos(thetas(2))); %if t2 is right, +/-.
%         if abs(asin(-Q(2,3)/cos(thetas(2)))-thetas(3)) > .00001
%             %assume thetas2 is correct
%             thetas(3) = -thetas(3);        
%         end
%         if abs(asin(-Q(1,2)/cos(thetas(2))) - thetas(1)) > .00001
%             thetas(1) = -thetas(1); 
%         end
%         
    end
        
        
%         thetas(2) = -thetas(2); disp('c'); disp(sin(thetas(3))*cos(thetas(1))*sin(thetas(2)) + cos(thetas(3)) * sin(thetas(1)))
%     end
    [t thetas]
    
    Q2 = [1 0 0; 0 cos(thetas(3)) -sin(thetas(3)); 0 sin(thetas(3)) cos(thetas(3))] * ...
[cos(thetas(2)) 0 sin(thetas(2)); 0 1 0; -sin(thetas(2)) 0 cos(thetas(2))] * ...
[cos(thetas(1)) -sin(thetas(1)) 0; sin(thetas(1)) cos(thetas(1)) 0; 0 0 1];
% 
[Q Q2]
disp(max(abs(Q(:)-Q2(:))))