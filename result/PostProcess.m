F = dir('./result');
D = {F([F.isdir]).name};
D = D(~ismember(D,{'.','..'}));
N = length(D);
forceCoeffs=[];

for l = 1:N
    f = dir(['./result/',D{l}]);
    d = {f([f.isdir]).name};
    d = d(~ismember(d,{'.','..'}));
    n = length(d);
    for i = 1:n
        res = ['./result/',D{l},'/',d{i},'/postProcessing/residuals/0/residuals.dat'];
        residuals = importdata(res);
        residuals = residuals.data;
        t = residuals(:,1);
        figure;

        %for 3d case
        %semilogy(t,residuals(:,2),t,residuals(:,3),t,residuals(:,4),t,residuals(:,5),t,residuals(:,6),t,residuals(:,7));
        %legend('p','Ux','Uy','Uz','k','omega')

        %for 2d case
        semilogy(t,residuals(:,2),t,residuals(:,3),t,residuals(:,4),t,residuals(:,5),t,residuals(:,6));
        legend('p','Ux','Uy','k','omega')

        xlabel('Iterations'), ylabel('Residuals'), title(d{i})
        res = ['./result/',D{l},'/',d{i},'/Residuals.png'];
        saveas(gcf,res)
        f = ['./result/',D{l},'/',d{i},'/postProcessing/forceCoefficient/0/forceCoeffs.dat'];
        fc = importdata(f);
        fc = fc.data;
        forceCoeffs=[forceCoeffs;[fc(2,2) fc(2,3) fc(2,4) fc(2,5) fc(2,6)]];
    end
    figure;
    %change this mannually
    aoa = [1];
    yyaxis left
    plot(aoa, forceCoeffs(:,3));
    yyaxis right
    plot(aoa, forceCoeffs(:,2), aoa, forceCoeffs(:,1));
    legend('Cl','Cd','Cm','Location','northwest')
    ylabel('Coefficient'), xlabel('AOA')
    res = ['./result/',D{l},'/foreCoeffs.png'];
    saveas(gcf,res)
end
%close all

%sur = dir(['./result/',d{i},'/postProcessing/surfaceData/surface/*/p*']);
%surface = importdata([sur.folder,'/',sur.name], ' ', 2);
%surface = surface.data;
%figure;
%plot3(surface(:,1),surface(:,3),surface(:,4));
%xlabel('x(mm)'), ylabel('z(mm)'), zlabel('p'), title(d{i})
%res = ['./result/',d{i},'/surface.png'];
%saveas(gcf,res)
