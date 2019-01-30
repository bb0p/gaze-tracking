% New eyetracking script with a couple of improvements / Sept 2008
% Fft is used for multiple comparisons

clear;
stimuli_jpgs=dir('stimuli/*.jpg');
response_jpgs=dir('response/*.jpg');

% This is example does not use a calibration procedure, but just use a
% couple of hand-picked prototype/salience couplings. In principle these
% could be found in an unsupervised fasion but because of the relative
% sparse data this doesn't seem feasible.
prototypes=[7 20 26 39 41 76 114 116 129 150 154 173 176 212 223];
n=length(prototypes);
w=30; % Margin between prototype and image

clf
s2=imread(['stimuli/' stimuli_jpgs(1).name]); % Read the first stimulus
for t=1:length(stimuli_jpgs)-1
    s=imread(['stimuli/' stimuli_jpgs(t).name]);
    r=imread(['response/' response_jpgs(t).name]);
    % Calculate the difference between this and the previous stimulus
    diff=sum(abs(s-s2),3);
    for i=1:10 % Smooth the difference a little
        diff=diff+circshift(diff,[-i -i])+circshift(diff,[i -i])+...
            circshift(diff,[-i i])+circshift(diff,[i i]);
    end
    s2=s; % Remember the last stimulus for the next difference calculation
    [m1 c1]=max(diff); % Find the max in difference
    [m2 c2]=max(m1);
    sal(t,:)=[c1(c2) c2]; % The salience coordinates at time i
    s(sal(t,1),:,:)=0;
    s(:,sal(t,2),:)=0;
    s(sal(t,1),:,1)=255;
    s(:,sal(t,2),1)=255;
    fi=find(prototypes==t);
    if fi
        p(:,:,:,fi)=r(w:size(r,1)-w,w:size(r,2)-w,:);
    end
    s=repmat(s,3*3,1);      % Make s larger for printing
    s=reshape(s,213,3,3,320,3);
    image(squeeze(s(:,1,1,:,:)))
    s=permute(s,[2 1 3 4 5]);
    s=reshape(s,3*213,3*320,3);
    r(1:2:size(r,1),:,:)=[]; % shrink r
    r(:,1:2:size(r,2),:)=[];
    r=flipdim(r,2); % flip r
    s(1:size(r,1),1:size(r,2),:)=r; % fit r into s
    image(s)
    title(num2str(t))
    drawnow
end

% Compare all the prototypes to all frames using fft
r2=double(imread(['response/' response_jpgs(1).name]));
tic
for t=1:length(response_jpgs)-1
    r=double(imread(['response/' response_jpgs(t).name]));
    for i=1:n
        r2(w:size(r,1)-w,w:size(r,2)-w,:)=p(:,:,:,i);
        d(t,i)=max(real(ifft(fft(r(:)).*conj(fft(r2(:))))));
    end
    imagesc(d');
    title([num2str(ceil((toc/t)*(length(response_jpgs)-t)/60)) ' minutes left'])
    drawnow
end
for i=1:size(d,1) % Normalize
    d(i,:)=d(i,:)/max(d(i,:));
end
for i=1:size(d,2)
    d(:,i)=d(:,i)/max(d(:,i));
end

% Matlabs standard least squares inverse "\" is used to extrapolate the
% tracking points from the prototypes, but you favorite correlation can
% also be used..
track=ceil(d*(d(prototypes,:)\sal(prototypes,:)));

% That is basically it... The rest is just for visualisation

s2=imread(['stimuli/' stimuli_jpgs(1).name]); % Read the first stimulus
track(find(track<1))=1;
track(find(track(:,2)>size(s2,2)),:)=size(s2,2);
track(find(track(:,1)>size(s2,1)),:)=size(s2,1);

for t=1:length(stimuli_jpgs)-1
    s=imread(['stimuli/' stimuli_jpgs(t).name]);
    r=imread(['response/' response_jpgs(t).name]);
    s(track(t,1),:,:)=0;
    s(:,track(t,2),:)=0;
    s(track(t,1),:,1)=255;
    s(:,track(t,2),1)=255;
    s=repmat(s,3*3,1);      % Make s larger for printing
    s=reshape(s,213,3,3,320,3);
    image(squeeze(s(:,1,1,:,:)))
    s=permute(s,[2 1 3 4 5]);
    s=reshape(s,3*213,3*320,3);
    r(1:2:size(r,1),:,:)=[]; % shrink r
    r(:,1:2:size(r,2),:)=[];
    r=flipdim(r,2); % flip r
    s(1:size(r,1),1:size(r,2),:)=r; % fit r into s
    image(s)
    drawnow
    imwrite(s,['analysis/' response_jpgs(t).name])
end

% Create movie
unix('~/Documents/sync/ffmpegXbinaries20050814/mencoder mf://analysis/*.jpg -mf fps=3:type=jpg -ovc lavc -lavcopts vcodec=mpeg4 -oac copy -o nosound.avi')
